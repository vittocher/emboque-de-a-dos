@tool
extends Area2D
class_name WindZone

## Corriente de aire (como la que levanta un volantín). Empuja a los extremos
## del emboque (son livianos: suben como un volantín) y un poco a los jugadores
## (los ayuda a subir o los frena). Se ve como rayitas de aire que corren en su
## dirección y suena mientras haya algo adentro.

## Tamaño de la zona (px). La posición del nodo es el centro.
@export var size := Vector2(120, 300):
	set(value):
		size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_apply()
## Hacia dónde sopla (se normaliza).
@export var direction := Vector2.UP:
	set(value):
		direction = value
		_apply()
## Aceleración sobre los extremos y cajas (px/s²). La gravedad es 980.
@export var strength := 1700.0
## Fracción de [member strength] que reciben los jugadores.
@export_range(0.0, 2.0) var player_factor := 1.25
## Velocidad máxima a la que el viento lleva a un jugador (px/s).
@export var player_max_speed := 330.0

var _sound: AudioStreamPlayer2D

func _enter_tree() -> void:
	_apply()

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 2 | 4 | 8 | 32  # jugadores + extremos + cajas
	monitorable = false
	var stream := Sfx.get_stream(&"wind")
	if stream != null:
		Sfx.make_looping(stream)
		_sound = AudioStreamPlayer2D.new()
		_sound.stream = stream
		_sound.bus = SettingsManager.SFX_BUS
		_sound.volume_db = Sfx.base_volume(&"wind")
		_sound.max_distance = 900.0
		add_child(_sound)
		_sound.play()

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var dir := direction.normalized()
	for body in get_overlapping_bodies():
		if body is RigidBody2D:
			(body as RigidBody2D).apply_central_force(dir * strength * (body as RigidBody2D).mass)
		elif body is Player:
			(body as Player).add_wind(dir * strength * player_factor, player_max_speed)

func _apply() -> void:
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null:
		var rect := cs.shape as RectangleShape2D
		if rect == null or not rect.resource_local_to_scene:
			rect = RectangleShape2D.new()
			rect.resource_local_to_scene = true
			cs.shape = rect
		rect.size = size
	var dir := direction.normalized() if direction != Vector2.ZERO else Vector2.UP
	var tint := get_node_or_null("Tint") as Polygon2D
	if tint != null:
		var h := size * 0.5
		tint.polygon = PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	var streaks := get_node_or_null("Streaks") as CPUParticles2D
	if streaks != null:
		# Las rayitas nacen en el lado de entrada y cruzan la zona en ~1 s.
		var along := absf(dir.dot(size))
		var across := absf(dir.orthogonal().dot(size))
		streaks.position = -dir * along * 0.5
		streaks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		streaks.emission_rect_extents = (dir.orthogonal().abs() * across * 0.5) + dir.abs() * 4.0
		streaks.direction = dir
		streaks.spread = 4.0
		streaks.gravity = Vector2.ZERO
		streaks.initial_velocity_min = along * 0.9
		streaks.initial_velocity_max = along * 1.2
		streaks.lifetime = 1.0
		streaks.amount = maxi(8, int(across / 9.0))
		streaks.rotation = 0.0
		streaks.particle_flag_align_y = true
