extends Node2D
class_name TueTue

## El Tue Tue: el jefe del último nivel, un pájaro de mal agüero que no deja
## embocar. Vuela sin chocar con nada (es un espíritu). Lo maneja BossFight según la
## fase; acá está cómo se mueve y ataca en cada modo, siempre con el MISMO patrón
## (sin azar: se puede aprender, y el bot de pruebas puede ganarle).
##
## - FIGHT (fase 1): planea en el centro (ahí es fácil pegarle), y entre planeo y
##   planeo ataca: PICADA a ras del piso (empuja a quien toque) o RÁFAGA desde un
##   costado (arrastra a todos hacia el foso de púas del otro lado). Un extremo
##   LANZADO (o muy rápido) que lo toca le quita una vida; sin vidas → defeated.
## - FOLLOW (fase 2): vuela arriba de la pantalla mientras la cámara sube.
## - HARASS (fase 3, la cima): da vueltas y cada tanto (o apenas los dos extremos
##   se acercan) se tira en picada sobre el punto del emboque y los desparrama. Si
##   le pegan, queda mareado unos segundos: la ventana para embocar.
## - BEATEN: tras el emboque final se va chillando.

signal hit_taken(hp_left: int)
signal defeated
signal stunned

enum Mode { IDLE, FIGHT, FLEE, FOLLOW, HARASS, BEATEN }
## Estados de la fase de pelea / acoso (el bot de pruebas los lee).
enum State { IDLE, MOVE, HOVER, TELEGRAPH, SWOOP, GUST, HURT, ORBIT, DIVE, STUNNED, GONE }

@export_group("Pelea")
@export var max_hp: int = 5
## Puntos donde planea (al centro, lejos de las plataformas y a tiro de un
## lanzamiento desde el piso: el alcance es el largo máximo de la cuerda).
@export var hover_points: PackedVector2Array = PackedVector2Array([Vector2(640, 420), Vector2(560, 390), Vector2(720, 390)])
@export var hover_time: float = 3.2
## Bamboleo mientras planea (px): de lado y arriba/abajo.
@export var hover_sway: Vector2 = Vector2(40, 10)
## Rapidez al cambiar de lugar (px/s).
@export var fly_speed: float = 430.0
## Bordes del piso de la arena (la picada va de un borde al otro).
@export var arena_left: float = 140.0
@export var arena_right: float = 1140.0
## Altura de la picada (a la altura del pecho de quien está en el piso).
@export var swoop_y: float = 572.0
@export var swoop_speed: float = 700.0
@export var telegraph_time: float = 0.9
## Empujón al jugador que toca en picada (x hacia donde va la picada).
@export var swoop_knockback: Vector2 = Vector2(820, -220)
## Ráfaga: desde dónde sopla (altura), cuánto dura y con qué rapidez arrastra.
@export var gust_y: float = 480.0
@export var gust_time: float = 2.6
@export var gust_push: float = 270.0
## Fuerza de la ráfaga sobre los extremos (px/s², por masa).
@export var gust_end_force: float = 900.0
## Un extremo que lo toca le pega si va lanzado o a más de esto (px/s).
@export var hit_min_speed: float = 550.0
## Tras un golpe: invulnerable este rato (s).
@export var hurt_time: float = 0.7

@export_group("Acoso en la cima")
@export var orbit_radius: Vector2 = Vector2(260, 120)
@export var orbit_time: float = 3.6
## Radio en que la picada desparrama los extremos y con qué rapidez salen (px/s).
@export var blow_radius: float = 230.0
@export var blow_speed: float = 520.0
@export var stun_time: float = 6.5
## Si los dos extremos se acercan a menos de esto (px) se tira en picada sin esperar
## a terminar la vuelta (no deja embocar), pero no antes de orbit_min_time.
@export var react_radius: float = 130.0
@export var orbit_min_time: float = 1.2

## Orden fijo de la pelea: planear en un punto / picada desde un lado / ráfaga
## desde un lado (from = -1 izquierda, 1 derecha).
const FIGHT_PATTERN := [
	{"do": "hover", "at": 0},
	{"do": "swoop", "from": 1},
	{"do": "hover", "at": 1},
	{"do": "gust", "from": -1},
	{"do": "hover", "at": 2},
	{"do": "swoop", "from": -1},
	{"do": "hover", "at": 0},
	{"do": "gust", "from": 1},
]

var mode: Mode = Mode.IDLE
var state: State = State.IDLE
var hp: int = 5
## Paso actual del patrón de pelea (el bot lo lee).
var step: Dictionary = {}

var _pattern_i := -1
var _t := 0.0                 # tiempo en el estado actual
var _target := Vector2.ZERO
var _move_then := ""          # qué hacer al llegar (MOVE)
var _swoop_dir := 0
var _swoop_hit := {}          # jugadores ya empujados en esta picada
var _hurt := 0.0              # invulnerable mientras > 0
var _camera: Camera2D
var _harass_center := Vector2.ZERO
var _orbit_phase := 0.0
var _phase := 0.0             # reloj del bamboleo
var _hover_base := Vector2.ZERO

@onready var _art: Node2D = $Art
@onready var _sprite: AnimatedSprite2D = $Art/Sprite
@onready var _hurtbox: Area2D = $Hurtbox
@onready var _hitbox: Area2D = $Hitbox
@onready var _feathers: CPUParticles2D = $Feathers
@onready var _gust_fx: CPUParticles2D = $GustFx
@onready var _stars: Node2D = $Art/Stars

func _ready() -> void:
	hp = max_hp
	_hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	_stars.visible = false
	_gust_fx.emitting = false
	visible = false

# --- Órdenes de BossFight ---

func start_fight() -> void:
	mode = Mode.FIGHT
	visible = true
	hp = max_hp
	_pattern_i = -1
	_next_pattern()
	_screech()

## Derrotado en la pelea: chilla, da una vuelta y se escapa hacia arriba.
func flee() -> void:
	mode = Mode.FLEE
	_set_state(State.MOVE)
	_target = Vector2(position.x, position.y - 900)
	_screech()

## Fase 2: vuela arriba de la pantalla mientras [param camera] sube.
func follow(camera: Camera2D) -> void:
	mode = Mode.FOLLOW
	visible = true
	_camera = camera
	_set_state(State.MOVE)
	position = camera.global_position + Vector2(0, -470)

## Fase 3: acosa los extremos alrededor de [param center] (donde se emboca).
func harass(center: Vector2) -> void:
	mode = Mode.HARASS
	visible = true
	_harass_center = center
	_orbit_phase = 0.0
	_set_state(State.ORBIT)
	_screech()

## Embocaron: se va chillando y no vuelve.
func beaten() -> void:
	mode = Mode.BEATEN
	_set_state(State.MOVE)
	_target = position + Vector2(0, -800)
	_stars.visible = false
	_screech()

# --- Bucle ---

func _physics_process(delta: float) -> void:
	_t += delta
	_phase += delta
	_hurt = maxf(0.0, _hurt - delta)
	match mode:
		Mode.FIGHT:
			_fight(delta)
		Mode.FLEE, Mode.BEATEN:
			_fly_to(_target, fly_speed * 1.6, delta)
			_art.rotation += delta * 9.0
			if position.distance_to(_target) < 10.0:
				_set_state(State.GONE)
				visible = false
				_art.rotation = 0.0
		Mode.FOLLOW:
			_follow(delta)
		Mode.HARASS:
			_harass(delta)
	_animate(delta)

func _fight(delta: float) -> void:
	match state:
		State.MOVE:
			if _fly_to(_target, fly_speed, delta):
				match _move_then:
					"hover":
						_set_state(State.HOVER)
						_hover_base = position
					"telegraph":
						_set_state(State.TELEGRAPH)
						_screech()
		State.HOVER:
			position = _hover_base + Vector2(sin(_t * 1.9) * hover_sway.x, sin(_t * 3.1) * hover_sway.y)
			if _t >= hover_time:
				_next_pattern()
		State.TELEGRAPH:
			# Tiembla y chilla: se viene el ataque.
			_art.position = Vector2(randf_range(-3, 3), randf_range(-3, 3))
			if _t >= telegraph_time:
				_art.position = Vector2.ZERO
				if step.do == "swoop":
					_set_state(State.SWOOP)
					_swoop_dir = -int(step.from)
					_swoop_hit.clear()
					Sfx.play(&"swoop")
				else:
					_set_state(State.GUST)
					_start_gust_fx(-int(step.from))
					Sfx.play(&"gust")
		State.SWOOP:
			position.x += _swoop_dir * swoop_speed * delta
			_knock_players()
			var end_x := arena_right + 60.0 if _swoop_dir > 0 else arena_left - 60.0
			if (position.x - end_x) * _swoop_dir >= 0.0:
				_next_pattern()
		State.GUST:
			position.y = gust_y + sin(_t * 9.0) * 6.0
			_blow(-int(step.from), delta)
			if _t >= gust_time:
				_gust_fx.emitting = false
				_next_pattern()
		State.HURT:
			# Retrocede un poco y sigue con el siguiente ataque.
			position += (_target - position) * minf(1.0, delta * 6.0)
			if _t >= hurt_time:
				_next_pattern(true)

## Pasa al siguiente paso del patrón. [param skip_hover]: tras un golpe no vuelve a
## planear, ataca directamente.
func _next_pattern(skip_hover := false) -> void:
	for _i in FIGHT_PATTERN.size():
		_pattern_i = (_pattern_i + 1) % FIGHT_PATTERN.size()
		step = FIGHT_PATTERN[_pattern_i]
		if not (skip_hover and step.do == "hover"):
			break
	_set_state(State.MOVE)
	match step.do:
		"hover":
			_target = hover_points[int(step.at) % hover_points.size()]
			_move_then = "hover"
		"swoop":
			var x := arena_right + 40.0 if int(step.from) > 0 else arena_left - 40.0
			_target = Vector2(x, swoop_y)
			_move_then = "telegraph"
		"gust":
			var gx := arena_right - 60.0 if int(step.from) > 0 else arena_left + 60.0
			_target = Vector2(gx, gust_y)
			_move_then = "telegraph"

## Empuja a los jugadores que toca en picada (una vez por picada a cada uno).
func _knock_players() -> void:
	for body in _hitbox.get_overlapping_bodies():
		if body is Player and not _swoop_hit.has(body):
			_swoop_hit[body] = true
			(body as Player).knockback(Vector2(swoop_knockback.x * _swoop_dir, swoop_knockback.y))
			Sfx.play(&"boss_hit", 1.4, -6.0)

## Ráfaga hacia [param dir]: arrastra a todos los jugadores y empuja los extremos
## que cuelgan (no los lanzados: el tiro sigue recto).
func _blow(dir: int, _delta: float) -> void:
	for p in get_tree().get_nodes_in_group(&"players"):
		(p as Player).add_push(Vector2(dir * gust_push, 0))
	for e in _emboques():
		var end := e.get_end()
		if end != null and not e.is_flying() and not e.is_held():
			end.apply_central_force(Vector2(dir * gust_end_force * end.mass, 0))

func _start_gust_fx(dir: int) -> void:
	_gust_fx.direction = Vector2(dir, 0)
	_gust_fx.position = Vector2(dir * 40, 0)
	_gust_fx.emitting = true

func _follow(delta: float) -> void:
	if _camera == null:
		return
	var top := _camera.global_position.y - 360.0
	var want := Vector2(640.0 + sin(_phase * 0.7) * 330.0, top + 110.0 + sin(_phase * 2.3) * 14.0)
	_fly_to(want, fly_speed, delta)
	# Cada tanto chilla (no ataca: la cámara ya los apura).
	if fmod(_phase, 6.0) < delta:
		_screech()

func _harass(delta: float) -> void:
	match state:
		State.ORBIT:
			_orbit_phase += delta * 1.3
			var want := _harass_center + Vector2(cos(_orbit_phase) * orbit_radius.x,
				-160.0 - absf(sin(_orbit_phase)) * orbit_radius.y)
			_fly_to(want, fly_speed, delta)
			if _t >= orbit_time or (_t >= orbit_min_time and _ends_close()):
				_set_state(State.TELEGRAPH)
				_target = _harass_center + Vector2(0, -190)
				_screech()
		State.TELEGRAPH:
			_fly_to(_target, fly_speed, delta)
			_art.position = Vector2(randf_range(-3, 3), randf_range(-3, 3))
			if _t >= telegraph_time:
				_art.position = Vector2.ZERO
				_set_state(State.DIVE)
				Sfx.play(&"swoop")
		State.DIVE:
			if _fly_to(_harass_center + Vector2(0, 20), swoop_speed * 1.1, delta):
				_scatter_ends()
				_set_state(State.ORBIT)
		State.STUNNED:
			_fly_to(_target + Vector2(0, sin(_t * 2.0) * 8.0), fly_speed, delta)
			if _t >= stun_time:
				_stars.visible = false
				_set_state(State.ORBIT)
				_screech()

## Los dos extremos colgando cerca uno del otro (están por embocar).
func _ends_close() -> bool:
	var ends: Array[RopeEnd] = []
	for e in _emboques():
		var end := e.get_end()
		if end == null or e.is_held():
			return false
		ends.append(end)
	return ends.size() == 2 and ends[0].global_position.distance_to(ends[1].global_position) < react_radius

## La picada en la cima: los extremos cerca del punto de emboque salen volando.
func _scatter_ends() -> void:
	Sfx.play(&"gust", 1.3)
	_feathers.restart()
	for e in _emboques():
		var end := e.get_end()
		if end == null or e.is_held() or end.is_attached():
			continue
		var off := end.global_position - _harass_center
		if off.length() > blow_radius:
			continue
		var dir := off.normalized() if off.length() > 4.0 else Vector2(1 if e.end_kind == "palito" else -1, 0)
		dir.x = signf(dir.x) if absf(dir.x) > 0.01 else 1.0
		end.linear_velocity = Vector2(dir.x * blow_speed, -blow_speed * 0.45)

# --- Golpes ---

func _on_hurtbox_body_entered(body: Node) -> void:
	if not body is RopeEnd or _hurt > 0.0:
		return
	if mode != Mode.FIGHT and not (mode == Mode.HARASS and state != State.STUNNED):
		return
	var end := body as RopeEnd
	var emboque := end.get_parent() as Emboque
	var flying := emboque != null and emboque.is_flying()
	if not flying and end.linear_velocity.length() < hit_min_speed:
		return
	var v := end.linear_velocity
	if emboque != null:
		emboque.stop_flight()
	end.linear_velocity = -v * 0.25
	_hurt = hurt_time
	_feathers.restart()
	_flash()
	Sfx.play(&"boss_hit")
	if mode == Mode.FIGHT:
		hp -= 1
		hit_taken.emit(hp)
		_gust_fx.emitting = false
		if hp <= 0:
			defeated.emit()
			return
		_set_state(State.HURT)
		_target = position + v.normalized() * 70.0
	else:
		# En la cima: mareado en un rincón alto.
		_set_state(State.STUNNED)
		var side := -1.0 if position.x > _harass_center.x else 1.0
		_target = _harass_center + Vector2(side * -380.0, -250.0)
		_stars.visible = true
		stunned.emit()

func _flash() -> void:
	var tw := create_tween()
	_sprite.modulate = Color(3, 3, 3)
	tw.tween_property(_sprite, "modulate", Color.WHITE, 0.25)

# --- Utilidades ---

func _set_state(s: State) -> void:
	state = s
	_t = 0.0

## Vuela hacia [param to] (sin pasarse). True al llegar.
func _fly_to(to: Vector2, speed: float, delta: float) -> bool:
	position = position.move_toward(to, speed * delta)
	return position.distance_to(to) < 1.0

func _emboques() -> Array[Emboque]:
	var out: Array[Emboque] = []
	for n in get_tree().get_nodes_in_group(&"emboques"):
		out.append(n as Emboque)
	return out

func _screech() -> void:
	Sfx.play(&"tuetue", randf_range(0.97, 1.03))
	_sprite.play(&"screech")
	get_tree().create_timer(0.6).timeout.connect(func() -> void:
		if is_instance_valid(_sprite):
			_sprite.play(&"fly"))

func _animate(delta: float) -> void:
	# Aletea más rápido al soplar o picar; mareado, las estrellas giran.
	var fast := state == State.GUST or state == State.SWOOP or state == State.DIVE
	_sprite.speed_scale = 2.2 if fast else 1.0
	if _stars.visible:
		_stars.rotation += delta * 4.0
	if mode == Mode.FIGHT or mode == Mode.HARASS or mode == Mode.FOLLOW:
		# Se inclina hacia donde va.
		var lean := 0.0
		if state == State.SWOOP:
			lean = 0.35 * _swoop_dir
		_art.rotation = lerp_angle(_art.rotation, lean, minf(1.0, delta * 8.0))
