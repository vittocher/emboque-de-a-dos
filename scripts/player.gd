extends CharacterBody2D
class_name Player

## Controlador de plataformas para un jugador.
## Se parametriza con [member input_prefix] ("p1" o "p2") para reutilizar
## la misma escena con distintos controles (WASD vs. flechas).

## Prefijo de las acciones del Input Map: "p1" o "p2".
@export var input_prefix: String = "p1"

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

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	# Gravedad.
	if not is_on_floor():
		velocity.y += _gravity * delta

	# Salto (solo desde el suelo).
	if is_on_floor() and Input.is_action_just_pressed(input_prefix + "_jump"):
		velocity.y = jump_velocity

	# Movimiento horizontal.
	var direction := Input.get_axis(input_prefix + "_left", input_prefix + "_right")
	var control := 1.0 if is_on_floor() else air_control
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * control * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)

	move_and_slide()
