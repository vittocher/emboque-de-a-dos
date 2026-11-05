@tool
extends AnimatableBody2D
class_name MovingPlatform

## Plataforma que se mueve entre su posición inicial y inicial + [member travel].
## Sin canal (channel = -1) va y viene sola, con una pausa en cada punta. Con
## canal, va hacia la punta mientras el canal está activo (alguna placa de su
## color presionada) y vuelve al soltarse: un ascensor. Lleva a los jugadores
## parados encima y empuja lo que encuentra. El arte de madera lo pone TerrainArt
## (como un piso); unos rieles punteados muestran el recorrido.

@export var size := Vector2(160, 24):
	set(value):
		size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_apply()
## Recorrido desde la posición inicial (px).
@export var travel := Vector2(0, -200):
	set(value):
		travel = value
		_apply()
@export var speed := 110.0
## Pausa en cada punta (solo sin canal).
@export var wait_time := 0.8
## -1 = se mueve sola; 0..3 = la mueve ese canal.
@export var channel := -1:
	set(value):
		channel = value
		_apply()
@export var require_all := false

var _start := Vector2.ZERO
var _to_end := true
var _wait := 0.0
var _active := false

func _enter_tree() -> void:
	_apply()

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	sync_to_physics = true
	_start = position
	if channel >= 0:
		add_to_group(Channel.LISTENERS)
		_on_channel_changed(channel)
	var rails := get_node_or_null("Rails") as Line2D
	if rails != null:
		# Los rieles no se mueven con la plataforma.
		rails.top_level = true
		rails.global_position = global_position

func _on_channel_changed(ch: int) -> void:
	if ch == channel:
		_active = Channel.is_active(get_tree(), channel, require_all)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var target: Vector2
	if channel >= 0:
		target = _start + (travel if _active else Vector2.ZERO)
	else:
		if _wait > 0.0:
			_wait -= delta
			return
		target = _start + (travel if _to_end else Vector2.ZERO)
	var step := (target - position).limit_length(speed * delta)
	position += step
	if channel < 0 and position.distance_to(target) < 0.01:
		_to_end = not _to_end
		_wait = wait_time

func _apply() -> void:
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null:
		var rect := cs.shape as RectangleShape2D
		if rect == null or not rect.resource_local_to_scene:
			rect = RectangleShape2D.new()
			rect.resource_local_to_scene = true
			cs.shape = rect
		rect.size = size
	var h := size * 0.5
	var visual := get_node_or_null("Visual") as Polygon2D
	if visual != null:
		visual.polygon = PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	var rails := get_node_or_null("Rails") as Line2D
	if rails != null:
		rails.points = PackedVector2Array([Vector2.ZERO, travel])
		rails.default_color = Channel.color(channel) * Color(1, 1, 1, 0.55) if channel >= 0 \
			else Color(0.85, 0.8, 0.7, 0.35)
