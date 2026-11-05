extends Node2D
class_name Emboque

## Media mitad del emboque: un extremo con peso (palito o campana) que cuelga
## del jugador por una cuerda. El extremo es un RigidBody2D (RopeEnd) con física
## real: se balancea, rota sobre sí mismo y colisiona con el otro extremo.
## La cuerda se dibuja como una línea visual que sigue al extremo.
## En niveles con LevelRules.throw_enabled el jugador además puede tomar el
## extremo en la mano, apuntar y lanzarlo (ver "Tomar y lanzar").

## Nodo del que cuelga la cuerda (la "mano" del jugador).
@export var anchor_node: NodePath
## Prefijo de acciones del Input Map ("p1" o "p2").
@export var input_prefix: String = "p1"
## Escena del extremo (palito.tscn o campana.tscn). Se instancia como RopeEnd.
@export var end_scene: PackedScene
## Tipo de extremo, para que el WinManager sepa cuál es cuál.
@export_enum("palito", "campana") var end_kind: String = "palito"

@export_group("Cuerda")
@export var rope_length: float = 170.0
@export var min_length: float = 60.0
@export var max_length: float = 320.0
@export var length_speed: float = 240.0
## Si la cuerda tensa puede frenar/tirar del jugador cuando el extremo se traba.
@export var limit_player_movement: bool = true

@export_group("Enganche")
## Tiempo tras desenganchar antes de poder volver a engancharse (s).
@export var rehook_cooldown: float = 0.35

@export_group("Visual")
@export var rope_segments: int = 18

@export_group("Lanzar")
## Solo en niveles con un nodo LevelRules con throw_enabled. Velocidad con que
## sale el extremo (px/s): viaja en línea recta, sin gravedad, hasta max_length.
@export var throw_speed: float = 1400.0
## Ángulo máximo de la mira sobre la horizontal (grados).
@export_range(0.0, 89.0) var aim_max_angle_deg: float = 60.0
## Velocidad del barrido de la mira (grados/s): va y vuelve entre 0 y el máximo.
@export var aim_sweep_speed_deg: float = 60.0
## Holgura sobre min_length para poder tomar el extremo (px): no se toma a través de un muro.
@export var grab_tolerance: float = 20.0
@export var aim_line_color: Color = Color(1, 1, 1, 0.85)
@export var aim_line_width: float = 3.0
@export var aim_dash_length: float = 10.0

enum ThrowState { NONE, HELD, AIMING, FLYING }

## Dónde queda el extremo tomado, desde la mano (x hacia donde mira el jugador).
## Un poco más abajo que la mano para no tapar el ojo; sigue dentro del cuerpo.
const HOLD_OFFSET := Vector2(8, 10)
## Qué tan rápido llega el extremo a la mano al tomarlo (1/s).
const REEL_SHARPNESS := 30.0
## Margen de tiempo sobre lo que tarda el vuelo en llegar a max_length (s).
const FLIGHT_TIMEOUT_MARGIN := 0.15

@onready var _rope_line: Line2D = $Rope

var _anchor: Node2D
var _player: Player
var _end: RopeEnd
var _hook_sensor: Area2D
var _hooked: bool = false
var _hook_position: Vector2 = Vector2.ZERO
var _rehook_timer: float = 0.0

var _throw_enabled: bool = false
var _throw_state: ThrowState = ThrowState.NONE
var _carry_offset: Vector2 = Vector2.ZERO
var _aim_time: float = 0.0
var _throw_dir: Vector2 = Vector2.RIGHT
var _flight_time: float = 0.0
var _last_end_pos: Vector2 = Vector2.ZERO
var _release_used: bool = false  # soltar se usó para dejar el extremo: no alarga hasta soltar la tecla

func _ready() -> void:
	_anchor = get_node_or_null(anchor_node) as Node2D
	_instance_end()
	if _anchor != null and _end != null:
		_player = _find_character_body(_anchor) as Player
		if _player != null:
			# Saltar desde la cuerda suelta el gancho (lo decide el jugador).
			_player.swing_jumped.connect(_unhook)
		_end.global_position = _anchor.global_position + Vector2(0, rope_length)
		_end.rope_length = rope_length
		_end.constrained = true
	var rules := LevelRules.of(get_tree())
	_throw_enabled = rules != null and rules.throw_enabled and _player != null

func _instance_end() -> void:
	if end_scene == null:
		push_warning("Emboque '%s' sin end_scene asignada" % name)
		return
	_end = end_scene.instantiate() as RopeEnd
	add_child(_end)
	_hook_sensor = _end.get_node_or_null("HookSensor")
	if _hook_sensor != null:
		_hook_sensor.area_entered.connect(_on_hook_sensor_area_entered)

## Sube por el árbol desde el ancla hasta encontrar el cuerpo del jugador.
func _find_character_body(node: Node) -> CharacterBody2D:
	var current := node
	while current != null:
		if current is CharacterBody2D:
			return current
		current = current.get_parent()
	return null

func _physics_process(delta: float) -> void:
	if _anchor == null or _end == null:
		return
	_rehook_timer = maxf(0.0, _rehook_timer - delta)
	# Antes de _update_length: tomar el extremo exige que la cuerda YA estuviera
	# al mínimo antes de esta pulsación.
	if _throw_enabled:
		_update_throw(delta)
		if is_held():
			return
	_update_length(delta)

	if _hooked:
		if Input.is_action_just_pressed(input_prefix + "_down"):
			_unhook()
		elif _player != null:
			_player.set_swing_length(rope_length)

	# Pasar los parámetros de la cuerda al extremo rígido (los usa en su
	# _integrate_forces, que corre después en el mismo frame).
	_end.anchor_position = _anchor.global_position
	_end.rope_length = rope_length
	_end.hooked = _hooked
	_end.hook_position = _hook_position

	_limit_player()
	_update_rope_visual()

## Alarga (soltar) o acorta (tirar) la cuerda de forma continua.
func _update_length(delta: float) -> void:
	var change := 0.0
	if _release_used and not Input.is_action_pressed(input_prefix + "_release"):
		_release_used = false
	if Input.is_action_pressed(input_prefix + "_release") and not _release_used:
		change += length_speed * delta
	if Input.is_action_pressed(input_prefix + "_pull"):
		change -= length_speed * delta
	if change != 0.0:
		rope_length = clampf(rope_length + change, min_length, max_length)

## Si el extremo está más lejos que rope_length (trabado, o el jugador enganchado
## en el suelo), tira del jugador hacia el extremo. Con deslizamiento para que
## el piso no anule el tirón lateral. Colgando tenso no hace falta: el péndulo
## del jugador ya respeta el largo exacto.
func _limit_player() -> void:
	if not limit_player_movement or _player == null:
		return
	if _hooked and _player.is_swing_taut():
		return
	var anchor_pos := _anchor.global_position
	var target := _hook_position if _hooked else _end.global_position
	var to_end := target - anchor_pos
	var dist := to_end.length()
	if dist > rope_length + 1.0 and dist > 0.001:
		_move_sliding(_player, (to_end / dist) * (dist - rope_length))

## Mueve un cuerpo por 'motion' deslizando sobre las superficies con las que
## choca (como move_and_slide, pero con un desplazamiento explícito).
func _move_sliding(body: PhysicsBody2D, motion: Vector2) -> void:
	var slides := 4
	var remaining_motion := motion
	while slides > 0 and remaining_motion.length() > 0.001:
		var col := body.move_and_collide(remaining_motion)
		if col == null:
			return
		remaining_motion = col.get_remainder().slide(col.get_normal())
		slides -= 1

func _on_hook_sensor_area_entered(area: Area2D) -> void:
	# El sensor solo detecta puntos de enganche (por su máscara de colisión).
	# En la mano no engancha; lanzado sí (es la gracia de lanzar).
	if not _hooked and _rehook_timer <= 0.0 and not is_held():
		if _throw_state == ThrowState.FLYING:
			_end_flight()
		_hooked = true
		_hook_position = area.global_position
		Sfx.play(&"hook")
		# Enganche instantáneo: la cuerda toma el largo actual y el balanceo parte ya.
		rope_length = clampf(_anchor.global_position.distance_to(_hook_position), min_length, max_length)
		if _player != null:
			_player.attach_swing(_hook_position, rope_length)

## Suelta el enganche (abajo, o el jugador saltó desde la cuerda).
func _unhook() -> void:
	_hooked = false
	_rehook_timer = rehook_cooldown
	if _player != null:
		_player.detach_swing()
		# El extremo sale junto al jugador: si quedara quieto en el gancho, la
		# cuerda frenaría de golpe el lanzamiento.
		_end.linear_velocity = _player.velocity

# --- Tomar y lanzar (solo si el nivel lo permite: LevelRules.throw_enabled) ---

## True si el jugador tiene el extremo en la mano (tomado o apuntando).
func is_held() -> bool:
	return _throw_state == ThrowState.HELD or _throw_state == ThrowState.AIMING

## Tomar: cuerda ya al mínimo + tirar otra vez. Tomado: soltar lo deja caer,
## lanzar empieza a apuntar. Apuntando: lanzar otra vez lo lanza.
func _update_throw(delta: float) -> void:
	match _throw_state:
		ThrowState.NONE:
			if Input.is_action_just_pressed(input_prefix + "_pull") and _can_grab():
				_grab()
		ThrowState.HELD:
			if Input.is_action_just_pressed(input_prefix + "_release"):
				_drop()
			elif Input.is_action_just_pressed(input_prefix + "_throw"):
				_start_aim()
		ThrowState.AIMING:
			if Input.is_action_just_pressed(input_prefix + "_release"):
				_drop()
			elif Input.is_action_just_pressed(input_prefix + "_throw"):
				_throw()
			else:
				_aim_time += delta
				queue_redraw()
		ThrowState.FLYING:
			_update_flight(delta)
	if is_held():
		_carry(delta)

func _can_grab() -> bool:
	return not _hooked and rope_length <= min_length \
		and _anchor.global_position.distance_to(_end.global_position) <= min_length + grab_tolerance

func _grab() -> void:
	_throw_state = ThrowState.HELD
	_carry_offset = _end.global_position - _anchor.global_position
	_end.set_held(true)
	_rope_line.visible = false
	Sfx.play(&"grab")

## Lleva el extremo en la mano: llega con un tirón corto y después va pegado a
## ella (sin colisiones, así que moverlo directo no atraviesa nada).
func _carry(delta: float) -> void:
	var weight := 1.0 - exp(-REEL_SHARPNESS * delta)
	_carry_offset = _carry_offset.lerp(Vector2(HOLD_OFFSET.x * _player.facing, HOLD_OFFSET.y), weight)
	_end.global_position = _anchor.global_position + _carry_offset
	var facing_rotation := 0.0 if _player.facing > 0 else PI
	_end.global_rotation = lerp_angle(_end.global_rotation, facing_rotation, weight)

## Suelta el extremo de la mano: vuelve a colgar con la cuerda al mínimo (así
## basta tirar una vez para volver a tomarlo). Esa pulsación de soltar no alarga.
func _drop() -> void:
	_throw_state = ThrowState.NONE
	_player.aiming = false
	rope_length = min_length
	_release_used = true
	_end.set_held(false)
	_end.linear_velocity = _player.velocity
	_rope_line.visible = true
	queue_redraw()

func _start_aim() -> void:
	_throw_state = ThrowState.AIMING
	_aim_time = 0.0
	_player.aiming = true
	queue_redraw()

## Dirección de la mira: barre de 0° (horizontal, hacia donde mira) a
## aim_max_angle_deg hacia arriba y vuelve.
func _aim_direction() -> Vector2:
	var angle := deg_to_rad(pingpong(_aim_time * aim_sweep_speed_deg, aim_max_angle_deg))
	return Vector2(_player.facing * cos(angle), -sin(angle))

## Lanza desde la mano por la línea de la mira; la cuerda pasa al máximo.
## La forma del extremo cabe dentro del jugador, así que nunca parte dentro de un muro.
func _throw() -> void:
	_throw_dir = _aim_direction()
	_throw_state = ThrowState.FLYING
	_player.aiming = false
	_flight_time = 0.0
	rope_length = max_length
	_end.global_position = _anchor.global_position
	_end.global_rotation = _throw_dir.angle()
	_end.set_held(false)
	_end.start_flight(_throw_dir * throw_speed)
	_last_end_pos = _end.global_position
	_rope_line.visible = true
	queue_redraw()
	Sfx.play(&"throw")

## En vuelo (sin gravedad): termina cuando la cuerda se tensa, cuando algo lo
## frena (se mide el avance real, no linear_velocity) o por tiempo.
func _update_flight(delta: float) -> void:
	_flight_time += delta
	var progress := (_end.global_position - _last_end_pos).dot(_throw_dir)
	_last_end_pos = _end.global_position
	var taut := _anchor.global_position.distance_to(_end.global_position) >= rope_length - 1.0
	var blocked := progress < throw_speed * delta * 0.5
	var timed_out := _flight_time > max_length / throw_speed + FLIGHT_TIMEOUT_MARGIN
	if taut or blocked or timed_out:
		_end_flight()

func _end_flight() -> void:
	_throw_state = ThrowState.NONE
	_end.end_flight()

func _draw() -> void:
	if _throw_state != ThrowState.AIMING:
		return
	var hand := _anchor.global_position
	draw_dashed_line(to_local(hand), to_local(hand + _aim_direction() * max_length),
		aim_line_color, aim_line_width, aim_dash_length)

## Redibuja la cuerda como una curva con soltura (catenaria aproximada).
func _update_rope_visual() -> void:
	var a := _anchor.global_position
	var b := _end.global_position
	var dist := a.distance_to(b)
	var slack := maxf(0.0, rope_length - dist)
	# Lanzado sale recta, como un látigo.
	var sag := 0.0 if _throw_state == ThrowState.FLYING else minf(slack * 0.5, 90.0)
	var mid := (a + b) * 0.5 + Vector2(0, sag)

	var pts := PackedVector2Array()
	for i in range(rope_segments + 1):
		var t := float(i) / float(rope_segments)
		var p := a.lerp(mid, t).lerp(mid.lerp(b, t), t)
		pts.append(_rope_line.to_local(p))
	_rope_line.points = pts

# --- API para el WinManager ---

func get_end() -> RopeEnd:
	return _end

func get_end_position() -> Vector2:
	return _end.global_position if _end != null else global_position

## Devuelve el Area2D de la cavidad (solo la campana lo tiene; palito → null).
func get_cavity_sensor() -> Area2D:
	return _end.get_node_or_null("CavitySensor") if _end != null else null
