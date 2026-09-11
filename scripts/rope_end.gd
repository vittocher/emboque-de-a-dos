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
