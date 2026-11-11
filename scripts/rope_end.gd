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
# Pegado a otro extremo (al embocar): _carrier lo lleva; _carried es lo que lleva.
var _carrier: RopeEnd = null
var _carried: RopeEnd = null
var _carry_xform := Transform2D.IDENTITY

func _ready() -> void:
	_base_gravity_scale = gravity_scale

## En la mano del jugador (mecánica de lanzar): congelado y SIN colisiones, así
## no empuja al otro extremo, no entra en la cavidad de la campana ni activa
## zonas de muerte. El Emboque lo mueve a la mano cada frame.
func set_held(value: bool) -> void:
	if value == _held or _carrier != null:
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

## Pegado a otro extremo (al embocar, lo llama el WinManager): desde ahora este
## cuerpo no tiene física propia (congelado y sin colisiones) y va montado en
## [param carrier] con la posición y el ÁNGULO RELATIVOS de este instante, exactos.
## Su cuerda sigue actuando: [param carrier] la aplica en su _integrate_forces en el
## punto donde está este extremo, así el par cuelga de las dos cuerdas.
func attach_to(carrier: RopeEnd) -> void:
	if _carrier != null or carrier == null or carrier == self:
		return
	_carrier = carrier
	_carry_xform = carrier.global_transform.affine_inverse() * global_transform
	carrier._carried = self
	collision_layer = 0
	collision_mask = 0
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	constrained = false

func is_attached() -> bool:
	return _carrier != null

# Montado: se copia la transformación del que lo lleva en cada tick de física y en
# cada cuadro dibujado (así no se ve un tick de atraso).
func _physics_process(_delta: float) -> void:
	_follow_carrier()

func _process(_delta: float) -> void:
	_follow_carrier()

func _follow_carrier() -> void:
	if _carrier != null and is_instance_valid(_carrier):
		global_transform = _carrier.global_transform * _carry_xform

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

	_apply_rope(state, state.transform.origin, anchor_position, rope_length)
	# Lleva pegado al otro extremo: también lo sostiene la cuerda de ese, en el punto
	# donde está (su Emboque le sigue pasando el ancla y el largo cada frame).
	if _carried != null and is_instance_valid(_carried):
		var point := (state.transform * _carried._carry_xform).origin
		_apply_rope(state, point, _carried.anchor_position, _carried.rope_length)

## Restricción de una cuerda (ancla, largo) sobre el punto [param point] del cuerpo,
## por velocidad (sobre la velocidad lineal del cuerpo).
func _apply_rope(state: PhysicsDirectBodyState2D, point: Vector2, anchor: Vector2, length: float) -> void:
	var to_end := point - anchor
	var dist := to_end.length()
	if dist > length and dist > 0.001:
		var n := to_end / dist  # ancla → extremo
		# Quitar la velocidad radial hacia afuera → solo queda swing tangencial.
		var radial := state.linear_velocity.dot(n)
		if radial > 0.0:
			state.linear_velocity -= n * radial
		# Corregir el exceso con velocidad (no se fija la posición, así el motor
		# resuelve las colisiones y el extremo nunca atraviesa geometría).
		var overshoot := dist - length
		state.linear_velocity -= n * (overshoot / state.step) * stiffness
