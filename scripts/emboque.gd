extends Node2D
class_name Emboque

## Media mitad del emboque: un extremo con peso (palito o campana) que cuelga
## del jugador por una cuerda. El extremo es un RigidBody2D (RopeEnd) con física
## real: se balancea, rota sobre sí mismo y colisiona con el otro extremo.
## La cuerda se dibuja como una línea visual que sigue al extremo.

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

@onready var _rope_line: Line2D = $Rope

var _anchor: Node2D
var _player: CharacterBody2D
var _end: RopeEnd
var _hook_sensor: Area2D
var _hooked: bool = false
var _hook_position: Vector2 = Vector2.ZERO
var _rehook_timer: float = 0.0

func _ready() -> void:
	_anchor = get_node_or_null(anchor_node) as Node2D
	_instance_end()
	if _anchor != null and _end != null:
		_player = _find_character_body(_anchor)
		_end.global_position = _anchor.global_position + Vector2(0, rope_length)
		_end.rope_length = rope_length
		_end.constrained = true

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
	_update_length(delta)

	if _hooked and Input.is_action_just_pressed(input_prefix + "_down"):
		_unhook()

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
	if Input.is_action_pressed(input_prefix + "_release"):
		change += length_speed * delta
	if Input.is_action_pressed(input_prefix + "_pull"):
		change -= length_speed * delta
	if change != 0.0:
		rope_length = clampf(rope_length + change, min_length, max_length)

## Si el extremo está más lejos que rope_length (trabado, o el jugador colgando
## de un gancho), tira del jugador hacia el extremo. Con deslizamiento para que
## el piso no anule el tirón lateral.
func _limit_player() -> void:
	if not limit_player_movement or _player == null:
		return
	var anchor_pos := _anchor.global_position
	var to_end := _end.global_position - anchor_pos
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
	if not _hooked and _rehook_timer <= 0.0:
		_hooked = true
		_hook_position = area.global_position

## Suelta el enganche (con el direccional abajo).
func _unhook() -> void:
	_hooked = false
	_rehook_timer = rehook_cooldown

## Redibuja la cuerda como una curva con soltura (catenaria aproximada).
func _update_rope_visual() -> void:
	var a := _anchor.global_position
	var b := _end.global_position
	var dist := a.distance_to(b)
	var slack := maxf(0.0, rope_length - dist)
	var sag := minf(slack * 0.5, 90.0)
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
