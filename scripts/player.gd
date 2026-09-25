extends CharacterBody2D
class_name Player

## Controlador de plataformas para un jugador.
## Se parametriza con [member input_prefix] ("p1" o "p2") para reutilizar
## la misma escena con distintos controles (WASD vs. flechas).
##
## Cuando el Emboque se engancha a un HookPoint, el jugador pasa a un estado de
## balanceo propio (péndulo con ángulo + velocidad angular, estilo Donkey Kong
## Country) en vez de mezclar fuerzas con el controlador de plataformas.
##
## Arte: todo lo que está bajo Visual/Art se dibuja MIRANDO A LA DERECHA y el
## código lo espeja según [member facing]. Si Art tiene un AnimatedSprite2D
## llamado "Sprite", se reproducen solas sus animaciones con los nombres de
## [method get_anim_state] ("idle", "walk", "jump", "fall", "swing", "push", "aim").

## Se emite cuando el jugador salta para soltarse del gancho (el Emboque lo desengancha).
signal swing_jumped

## Prefijo de las acciones del Input Map: "p1" o "p2".
@export var input_prefix: String = "p1"

@export_group("Arte")
## Animaciones del Sprite de J1 (input_prefix "p1").
@export var frames_p1: SpriteFrames
## Animaciones del Sprite de J2 (input_prefix "p2").
@export var frames_p2: SpriteFrames

@export_group("Movimiento")
## Velocidad horizontal máxima (px/s).
@export var speed: float = 320.0
## Impulso vertical del salto (negativo = hacia arriba).
@export var jump_velocity: float = -680.0
## Qué tan rápido alcanza la velocidad objetivo en el suelo (px/s^2).
@export var acceleration: float = 2200.0
## Qué tan rápido frena al soltar la dirección (px/s^2).
@export var friction: float = 2600.0
## Control en el aire, 0 = ninguno, 1 = igual que en el suelo.
@export_range(0.0, 1.0) var air_control: float = 0.5

@export_group("Balanceo")
## Multiplica la gravedad del péndulo: >1 = balanceo más ágil que la caída libre.
@export var swing_gravity_scale: float = 1.8
## Aceleración tangencial al empujar a favor del movimiento (px/s^2).
@export var swing_pump_accel: float = 900.0
## Fracción del empuje que se aplica al empujar en contra del movimiento (frena suave).
@export_range(0.0, 1.0) var swing_brake_factor: float = 0.4
## Ángulo máximo del balanceo respecto a la vertical (grados). Define también la
## velocidad máxima: el péndulo nunca tiene más energía que la de este ángulo.
@export_range(10.0, 170.0) var swing_max_angle_deg: float = 80.0
## Amortiguación constante del balanceo (1/s).
@export var swing_damping: float = 0.15
## Qué tan rápido el radio alcanza el largo de la cuerda al hacer rapel (px/s).
@export var swing_radius_speed: float = 400.0
## Cuánto se inclina el cuerpo siguiendo la cuerda (0 = nada, 1 = alineado).
@export_range(0.0, 1.0) var swing_tilt_amount: float = 0.8

@export_group("Salto desde la cuerda")
## Impulso vertical que se suma al saltar desde la cuerda (negativo = arriba).
@export var swing_jump_velocity: float = -450.0
## Multiplica la velocidad del balanceo al saltar.
@export var swing_launch_multiplier: float = 1.1
## Frenado horizontal suave mientras se conserva el impulso del lanzamiento (px/s^2).
@export var launch_air_drag: float = 180.0

## Holgura para considerar la cuerda tensa (px).
const TAUT_TOLERANCE := 2.0
## Distancia al piso bajo la cual el balanceo cuenta como "pisando" (px).
const GROUND_PROBE := 2.0
## Distancia a la que el jugador detecta una caja delante para empujarla (px).
const PUSH_PROBE := 2.0
## Bajo esta velocidad tangencial (px/s) el empuje siempre cuenta como "a favor".
const SWING_REST_SPEED := 40.0
## Qué tan rápido se disipa la energía sobre el tope del ángulo máximo (1/s).
const SWING_CAP_SHARPNESS := 12.0
## Qué tan rápido el cuerpo se inclina hacia la cuerda (1/s).
const TILT_SHARPNESS := 14.0
## Sin input, colgando o lanzado, mira hacia donde se mueve si va más rápido que esto (px/s).
const FACE_MIN_SPEED := 60.0
## Distancia caminada entre dos sonidos de paso (px).
const STEP_LENGTH := 40.0
## Bajo esta velocidad (px/s) no cuenta como caminar.
const STEP_MIN_SPEED := 30.0
## Velocidad mínima al pasar por abajo del péndulo para que suene el "whoosh" (px/s).
const SWING_WHOOSH_MIN_SPEED := 150.0
## Animación de reemplazo cuando el arte no trae la del estado (si no está acá, "idle").
const ANIM_FALLBACK := {"push": "walk"}

## Hacia dónde mira: 1 = derecha, -1 = izquierda.
var facing: int = 1
## Apuntando un lanzamiento (lo activa el Emboque): no camina ni salta;
## izquierda/derecha solo lo giran (cambian hacia dónde apunta).
var aiming: bool = false

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _pushing: bool = false
var _step_distance: float = STEP_LENGTH

# Estado de enganche (lo controla el Emboque con attach_swing / detach_swing).
var _hooked: bool = false
var _swing_pivot: Vector2 = Vector2.ZERO
var _swing_length: float = 0.0
var _taut: bool = false         # colgando en el aire con la cuerda tensa → péndulo
var _swing_radius: float = 0.0
var _swing_omega: float = 0.0   # velocidad angular (rad/s); + = hacia la derecha abajo
var _launched: bool = false     # conserva el impulso tras soltarse de la cuerda
var _squash_tween: Tween

@onready var _visual: Node2D = $Visual
@onready var _art: Node2D = $Visual/Art
@onready var _sprite: AnimatedSprite2D = $Visual/Art.get_node_or_null("Sprite") as AnimatedSprite2D
@onready var _anchor_offset: Vector2 = ($RopeAnchor as Node2D).position

func _ready() -> void:
	# Al empezar mira hacia el centro de la pantalla (hacia su compañero).
	facing = 1 if global_position.x < get_viewport_rect().get_center().x else -1
	_art.scale.x = facing
	# Cada jugador usa su propio arte según su prefijo.
	var frames := frames_p2 if input_prefix == "p2" else frames_p1
	if _sprite != null and frames != null:
		_sprite.sprite_frames = frames
		_sprite.play("idle")

func _physics_process(delta: float) -> void:
	if _hooked and _taut:
		_pushing = false
		_process_swing(delta)
	else:
		_process_platformer(delta)
		_check_rope_taut()
	_update_facing()
	_update_visual(delta)
	_update_animation()

func _process_platformer(delta: float) -> void:
	# Gravedad.
	if not is_on_floor():
		velocity.y += _gravity * delta

	# Salto (solo desde el suelo).
	if not aiming and is_on_floor() and Input.is_action_just_pressed(input_prefix + "_jump"):
		velocity.y = jump_velocity
		Sfx.play(&"jump")

	# Movimiento horizontal (apuntando se queda quieto; el input solo lo gira).
	var direction := 0.0 if aiming else Input.get_axis(input_prefix + "_left", input_prefix + "_right")
	var control := 1.0 if is_on_floor() else air_control
	if _launched and not is_on_floor() and _apply_launch_air_control(direction, delta):
		pass
	elif direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * control * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)

	_pushing = direction != 0.0 and is_on_floor() and _try_push_box(direction)
	var push_velocity := velocity.x
	move_and_slide()
	if _pushing:
		# Al chocar con la caja el deslizamiento anula la velocidad; se restaura
		# para seguir empujando parejo el próximo tick (sin tirones).
		velocity.x = push_velocity
	if _launched and (is_on_floor() or is_on_wall()):
		_launched = false
	_update_footsteps(delta)

## Pasos: un sonido cada STEP_LENGTH px caminados de verdad sobre el piso (sin
## contar lo que lo mueve una caja de abajo, ni empujar contra un muro).
func _update_footsteps(delta: float) -> void:
	var walk_speed := absf(get_real_velocity().x - get_platform_velocity().x)
	if not is_on_floor() or walk_speed < STEP_MIN_SPEED:
		_step_distance = STEP_LENGTH  # el primer paso suena apenas empieza a caminar
		return
	_step_distance += walk_speed * delta
	if _step_distance >= STEP_LENGTH:
		_step_distance -= STEP_LENGTH
		Sfx.play(&"step", randf_range(0.9, 1.1))

## Si hay una caja justo delante (contacto lateral), la empuja a la velocidad del
## jugador, que a su vez queda limitada a la velocidad de empuje de la caja.
func _try_push_box(direction: float) -> bool:
	var col := KinematicCollision2D.new()
	if not test_move(global_transform, Vector2(direction * PUSH_PROBE, 0.0), col):
		return false
	var box := col.get_collider() as PushBox
	if box == null or col.get_normal().x * direction > -0.7:
		return false
	velocity.x = clampf(velocity.x, -box.push_speed, box.push_speed)
	box.push(velocity.x)
	return true

## Tras soltarse de la cuerda, el impulso se conserva: sin input o empujando a
## favor solo frena suave. Empujar en contra (o ir lento) usa el control normal.
## Devuelve true si se encargó de la velocidad horizontal.
func _apply_launch_air_control(direction: float, delta: float) -> bool:
	if direction == 0.0:
		velocity.x = move_toward(velocity.x, 0.0, launch_air_drag * delta)
		return true
	if signf(direction) == signf(velocity.x) and absf(velocity.x) > speed:
		velocity.x = move_toward(velocity.x, direction * speed, launch_air_drag * delta)
		return true
	return false

# --- Balanceo (péndulo) ---

## Lo llama el Emboque al engancharse. La velocidad que traía el jugador se
## convierte en balanceo en el mismo instante (enganche instantáneo).
func attach_swing(pivot: Vector2, length: float) -> void:
	_hooked = true
	_swing_pivot = pivot
	_swing_length = length
	_taut = false
	_launched = false
	if not _touching_ground():
		_enter_taut()

## Largo actual de la cuerda (cambia con soltar/tirar).
func set_swing_length(length: float) -> void:
	_swing_length = length

## Suelta el gancho sin impulso extra (abajo): conserva la velocidad del balanceo.
func detach_swing() -> void:
	if not _hooked:
		return
	if _taut:
		velocity = _swing_velocity()
		_launched = true
	_hooked = false
	_taut = false

## True si el jugador cuelga con la cuerda tensa (el péndulo ya respeta el largo).
func is_swing_taut() -> bool:
	return _hooked and _taut

func _hand_position() -> Vector2:
	return global_position + _anchor_offset

## En el suelo o rozándolo: un balanceo que pasa justo a ras del piso cuenta
## como pisar (si no, el péndulo podría deslizarse sobre el piso sin tocarlo).
func _touching_ground() -> bool:
	return is_on_floor() or test_move(global_transform, Vector2(0, GROUND_PROBE))

## Colgando en el aire: si la mano llegó al largo de la cuerda y se aleja del
## gancho, la cuerda se tensa y empieza el péndulo.
func _check_rope_taut() -> void:
	if not _hooked or _touching_ground():
		return
	var offset := _hand_position() - _swing_pivot
	if offset.length() >= _swing_length - TAUT_TOLERANCE and velocity.dot(offset) >= 0.0:
		_enter_taut()

func _enter_taut() -> void:
	var offset := _hand_position() - _swing_pivot
	var dist := offset.length()
	if dist < 0.001:
		return
	_taut = true
	_launched = false
	_swing_radius = dist
	# La velocidad tangencial se conserva; la radial la absorbe la cuerda.
	_swing_omega = velocity.dot(_swing_tangent(atan2(offset.x, offset.y))) / dist
	_squash(Vector2(1.2, 0.8))

func _process_swing(delta: float) -> void:
	if Input.is_action_just_pressed(input_prefix + "_jump"):
		_jump_off_swing()
		_process_platformer(delta)
		return

	var hand := _hand_position()
	var offset := hand - _swing_pivot
	var theta := atan2(offset.x, offset.y)  # 0 = colgando recto hacia abajo

	# El radio se acerca al largo de la cuerda (rapel). Al cambiar el radio se
	# conserva la velocidad tangencial, no la angular.
	var new_radius := maxf(move_toward(_swing_radius, _swing_length, swing_radius_speed * delta), 1.0)
	_swing_omega *= _swing_radius / new_radius
	_swing_radius = new_radius
	var r := _swing_radius
	var g := _gravity * swing_gravity_scale

	# Una cuerda no empuja: sobre el gancho y sin velocidad, se afloja y cae.
	if _swing_omega * _swing_omega * r + g * cos(theta) < 0.0:
		velocity = _swing_velocity()
		_taut = false
		_launched = true
		_process_platformer(delta)
		return

	var alpha := -(g / r) * sin(theta)
	# Bombeo híbrido: empujar a favor del movimiento suma mucho; en contra, frena suave.
	var direction := Input.get_axis(input_prefix + "_left", input_prefix + "_right")
	if direction != 0.0:
		var with_motion := absf(_swing_omega * r) < SWING_REST_SPEED or signf(direction) == signf(_swing_omega)
		alpha += direction * swing_pump_accel / r * (1.0 if with_motion else swing_brake_factor)
	_swing_omega += alpha * delta
	_swing_omega *= exp(-swing_damping * delta)
	_cap_swing_energy(theta, g / r, delta)

	# Mover hacia el punto del círculo con barrido de colisión (sin teletransporte).
	var new_theta := theta + _swing_omega * delta
	if signf(new_theta) != signf(theta):
		_play_swing_whoosh(absf(_swing_omega) * r)
	var target := _swing_pivot + Vector2(sin(new_theta), cos(new_theta)) * r
	velocity = (target - hand) / delta
	move_and_slide()

	if get_slide_collision_count() > 0:
		# Chocó: la velocidad angular es la que realmente logró moverse.
		var real := _hand_position() - _swing_pivot
		_swing_omega = angle_difference(theta, atan2(real.x, real.y)) / delta
	if _touching_ground():
		_taut = false

## Limita la energía del péndulo a la de [member swing_max_angle_deg]: el
## balanceo sube como máximo hasta ese ángulo y se frena de forma natural.
func _cap_swing_energy(theta: float, g_over_r: float, delta: float) -> void:
	var room := cos(theta) - cos(deg_to_rad(swing_max_angle_deg))
	if room <= 0.0:
		# Pasado el ángulo máximo: solo se quita la velocidad que lo aleja más.
		if signf(_swing_omega) == signf(theta):
			_swing_omega = 0.0
		return
	var cap := sqrt(2.0 * g_over_r * room)
	if absf(_swing_omega) > cap:
		var weight := 1.0 - exp(-SWING_CAP_SHARPNESS * delta)
		_swing_omega = lerpf(_swing_omega, signf(_swing_omega) * cap, weight)

## "Whoosh" al pasar por el punto más bajo: más fuerte y agudo cuanto más rápido.
func _play_swing_whoosh(speed_px: float) -> void:
	if speed_px < SWING_WHOOSH_MIN_SPEED:
		return
	var t := clampf((speed_px - SWING_WHOOSH_MIN_SPEED) / 500.0, 0.0, 1.0)
	Sfx.play(&"swing", lerpf(0.85, 1.15, t), lerpf(-8.0, 0.0, t))

func _jump_off_swing() -> void:
	var launch := _swing_velocity() * swing_launch_multiplier
	launch.y = minf(launch.y, 0.0) + swing_jump_velocity
	velocity = launch
	_hooked = false
	_taut = false
	_launched = true
	_squash(Vector2(0.85, 1.2))
	Sfx.play(&"jump", 1.2)
	swing_jumped.emit()

## Dirección en que avanza el péndulo cuando el ángulo crece.
func _swing_tangent(theta: float) -> Vector2:
	return Vector2(cos(theta), -sin(theta))

## Velocidad lineal actual del balanceo.
func _swing_velocity() -> Vector2:
	var offset := _hand_position() - _swing_pivot
	return _swing_tangent(atan2(offset.x, offset.y)) * _swing_omega * _swing_radius

# --- Visual ---

## Hacia dónde mira: la dirección del input; sin input, colgando o lanzado, hacia
## donde se mueve. El arte (Visual/Art) se espeja según esto.
func _update_facing() -> void:
	var direction := Input.get_axis(input_prefix + "_left", input_prefix + "_right")
	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1
	elif ((_hooked and _taut) or _launched) and absf(velocity.x) > FACE_MIN_SPEED:
		facing = 1 if velocity.x > 0.0 else -1
	_art.scale.x = facing

## Nombre del estado para animar el arte: "idle", "walk", "jump", "fall", "swing",
## "push" o "aim".
func get_anim_state() -> String:
	if _hooked and _taut:
		return "swing"
	if aiming:
		return "aim"
	if not is_on_floor():
		return "jump" if velocity.y < 0.0 else "fall"
	if _pushing:
		return "push"
	if absf(get_real_velocity().x - get_platform_velocity().x) > STEP_MIN_SPEED:
		return "walk"
	return "idle"

## Si el arte trae un AnimatedSprite2D "Sprite", reproduce la animación del estado.
## Si sus SpriteFrames no la tienen, usa la de [constant ANIM_FALLBACK] o "idle"
## (así no se queda caminando en el aire).
func _update_animation() -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var anim := get_anim_state()
	if not _sprite.sprite_frames.has_animation(anim):
		anim = ANIM_FALLBACK.get(anim, "idle")
	if _sprite.animation != anim and _sprite.sprite_frames.has_animation(anim):
		_sprite.play(anim)

## Inclina el cuerpo siguiendo la cuerda, pivotando en la mano (RopeAnchor).
## Solo rota el visual; la colisión se queda recta.
func _update_visual(delta: float) -> void:
	var target_rotation := 0.0
	if _hooked and _taut:
		var offset := _hand_position() - _swing_pivot
		target_rotation = -atan2(offset.x, offset.y) * swing_tilt_amount
	var weight := 1.0 - exp(-TILT_SHARPNESS * delta)
	_visual.rotation = lerp_angle(_visual.rotation, target_rotation, weight)
	_visual.position = _anchor_offset - (_anchor_offset * _visual.scale).rotated(_visual.rotation)

## Aplasta/estira el visual y lo devuelve a su tamaño con un rebote corto.
func _squash(amount: Vector2) -> void:
	if _squash_tween != null:
		_squash_tween.kill()
	_visual.scale = amount
	_squash_tween = create_tween()
	_squash_tween.tween_property(_visual, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
