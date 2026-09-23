extends RigidBody2D
class_name RopeEnd

## Extremo con peso del emboque (palito o campana). Es un cuerpo rígido real:
## se balancea como péndulo, rota sobre sí mismo y colisiona con el otro extremo
## y con el terreno. La cuerda se implementa como restricción de distancia en
## _integrate_forces (por velocidad, sin teletransporte → sin atravesar paredes).

# El Emboque actualiza estos valores cada frame.
var anchor_position: Vector2 = Vector2.ZERO
var rope_length: float = 170.0
var hooked: bool = false
var hook_position: Vector2 = Vector2.ZERO
var constrained: bool = false  # el Emboque lo activa tras posicionar el extremo

## Fracción del exceso de largo que se corrige por frame (estabilización).
@export var stiffness: float = 0.5

var _held: bool = false
var _saved_layer: int = 0
var _saved_mask: int = 0
var _base_gravity_scale: float = 1.0

func _ready() -> void:
	_base_gravity_scale = gravity_scale

## En la mano del jugador (mecánica de lanzar): congelado y SIN colisiones, así
## no empuja al otro extremo, no entra en la cavidad de la campana ni activa
## zonas de muerte. El Emboque lo mueve a la mano cada frame.
func set_held(value: bool) -> void:
	if value == _held:
		return
	_held = value
	if _held:
		_saved_layer = collision_layer
		_saved_mask = collision_mask
		collision_layer = 0
		collision_mask = 0
		freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		freeze = true
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
		constrained = false
	else:
		collision_layer = _saved_layer
		collision_mask = _saved_mask
		freeze = false
		constrained = true

func is_held() -> bool:
	return _held

## Lanzado: sin gravedad para que viaje en línea recta por donde se apuntó.
func start_flight(velocity: Vector2) -> void:
	gravity_scale = 0.0
	linear_velocity = velocity
	angular_velocity = 0.0

func end_flight() -> void:
	gravity_scale = _base_gravity_scale

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if not constrained:
		return

	if hooked:
		# Fijo al gancho (ya está ahí, no cruza paredes al fijarlo).
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity *= 0.85
		var t := state.transform
		t.origin = hook_position
		state.transform = t
		return

	var origin := state.transform.origin
	var to_end := origin - anchor_position
	var dist := to_end.length()
	if dist > rope_length and dist > 0.001:
		var n := to_end / dist  # ancla → extremo
		# Quitar la velocidad radial hacia afuera → solo queda swing tangencial.
		var radial := state.linear_velocity.dot(n)
		if radial > 0.0:
			state.linear_velocity -= n * radial
		# Corregir el exceso con velocidad (no se fija la posición, así el motor
		# resuelve las colisiones y el extremo nunca atraviesa geometría).
		var overshoot := dist - rope_length
		state.linear_velocity -= n * (overshoot / state.step) * stiffness
