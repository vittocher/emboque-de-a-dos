extends RigidBody2D
class_name PushBox

## Caja empujable. Es un cuerpo rígido real: los extremos del emboque (palito /
## campana) la golpean y la mueven, se puede pisar, apilar y cae de los bordes.
## Los jugadores la empujan caminando contra ella desde el suelo: el Player llama
## push() y la caja se mueve a la velocidad del jugador (predecible, sin inercia
## rara). La rotación va bloqueada en la escena para que no se vuelque.

## Velocidad máxima a la que la mueve un jugador que la empuja (px/s).
@export var push_speed: float = 150.0

## Tope de la compensación de roce (px/s por paso). Evita que crezca sin fin
## cuando la caja está trabada contra un muro.
const MAX_FRICTION_BOOST := 25.0
## Bajo esta velocidad real (px/s) la caja no suena al arrastrarse.
const SCRAPE_MIN_SPEED := 15.0

var _push_velocity: float = 0.0  # suma de los empujes de este tick
var _pushed: bool = false
var _was_pushed: bool = false
var _boost: float = 0.0          # compensación de roce del paso actual (px/s)
var _pre_solve_velocity: float = 0.0
var _scrape: AudioStreamPlayer   # sonido de arrastre en loop
var _last_x: float = 0.0

func _ready() -> void:
	_last_x = global_position.x
	var stream := Sfx.get_stream(&"box_push")
	if stream != null:
		Sfx.make_looping(stream)
		_scrape = AudioStreamPlayer.new()
		_scrape.stream = stream
		add_child(_scrape)

func _physics_process(delta: float) -> void:
	# Velocidad real (por desplazamiento): linear_velocity puede decir que se
	# mueve aunque esté trabada contra un muro.
	var real_speed := absf(global_position.x - _last_x) / delta
	_last_x = global_position.x
	_update_scrape_sound(real_speed)

## Lo llama el jugador que empuja (cada tick que sigue empujando).
func push(speed: float) -> void:
	_push_velocity += speed
	_pushed = true

## Arrastre en loop mientras se desliza por el piso (la empuje un jugador o la
## golpee un extremo). El volumen y el tono siguen a la velocidad.
func _update_scrape_sound(real_speed: float) -> void:
	if _scrape == null:
		return
	var sliding := real_speed > SCRAPE_MIN_SPEED and test_move(global_transform, Vector2(0, 2))
	if sliding:
		var t := clampf(real_speed / push_speed, 0.0, 1.0)
		_scrape.volume_db = Sfx.base_volume(&"box_push") + linear_to_db(lerpf(0.4, 1.0, t))
		_scrape.pitch_scale = lerpf(0.85, 1.05, t)
		if not _scrape.playing:
			_scrape.play()
	elif _scrape.playing:
		_scrape.stop()

## True mientras suena el arrastre (para tests).
func is_scraping() -> bool:
	return _scrape != null and _scrape.playing

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _pushed:
		# Se fija la velocidad (no una fuerza) para que la rapidez no dependa de
		# lo que tenga encima. Dos jugadores en contra se anulan.
		var target := clampf(_push_velocity, -push_speed, push_speed)
		# El roce con el suelo le quita velocidad dentro del paso, pero quien va
		# parado encima se mueve con la velocidad informada (target). Se mide lo
		# que se perdió en el paso anterior y se devuelve como fuerza de un paso
		# (no cambia la velocidad informada), así la caja avanza justo a target.
		if _was_pushed and target != 0.0 and signf(target) == signf(_pre_solve_velocity):
			var lost := absf(_pre_solve_velocity) - absf(state.linear_velocity.x)
			_boost = clampf(lost, 0.0, MAX_FRICTION_BOOST)
		else:
			_boost = 0.0
		var v := state.linear_velocity
		v.x = target
		state.linear_velocity = v
		var boost := signf(target) * _boost
		state.apply_central_force(Vector2(boost * mass / state.step, 0.0))
		_pre_solve_velocity = target + boost
	_was_pushed = _pushed
	_push_velocity = 0.0
	_pushed = false
