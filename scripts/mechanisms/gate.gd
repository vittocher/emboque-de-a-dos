@tool
extends AnimatableBody2D
class_name Gate

## Compuerta: un bloque que se desliza para abrir el paso mientras su canal
## está activo (alguna placa de su color presionada) y vuelve cuando se suelta.
## No baja si tiene algo debajo (no aplasta). El arte de madera lo pone
## TerrainArt (como un muro); las franjas del color del canal, este script.

## Tamaño (px). La posición del nodo es el centro de la compuerta CERRADA.
@export var size := Vector2(24, 160):
	set(value):
		size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_apply()
@export var channel := 0:
	set(value):
		channel = value
		_apply()
## Cuánto se mueve al abrirse (por defecto, hacia arriba todo su alto).
@export var open_offset := Vector2.ZERO
## Necesita todas las placas de su canal (no basta una).
@export var require_all := false
## Al revés: abierta mientras el canal está INACTIVO.
@export var inverted := false
@export var speed := 260.0

var is_open := false
var _closed_pos := Vector2.ZERO
var _target := Vector2.ZERO
var _was_moving := false

func _enter_tree() -> void:
	_apply()

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group(Channel.LISTENERS)
	sync_to_physics = true
	# La máscara decide qué "ve" test_move al cerrarse: terreno, jugadores,
	# extremos y cajas (con la de fábrica, solo terreno, aplastaba al jugador).
	collision_mask = 1 | 2 | 4 | 8 | 32
	_closed_pos = position
	_target = _closed_pos
	_on_channel_changed(channel)
	position = _target
	is_open = _target != _closed_pos

func _offset() -> Vector2:
	return open_offset if open_offset != Vector2.ZERO else Vector2(0, -size.y)

func _on_channel_changed(ch: int) -> void:
	if ch != channel:
		return
	var active := Channel.is_active(get_tree(), channel, require_all)
	is_open = active != inverted
	_target = _closed_pos + (_offset() if is_open else Vector2.ZERO)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var step := (_target - position).limit_length(speed * delta)
	if step.length() < 0.01:
		if _was_moving:
			_was_moving = false
		return
	# Cerrándose: si hay un jugador, un extremo o una caja en el camino, espera.
	var col := KinematicCollision2D.new()
	if not is_open and test_move(global_transform, step, col) and not (col.get_collider() is StaticBody2D):
		return
	if not _was_moving:
		_was_moving = true
		Sfx.play(&"gate", randf_range(0.95, 1.05))
	position += step

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
	# Franjas del color del canal (arriba y abajo), encima del arte de madera.
	var bands := get_node_or_null("Bands") as Node2D
	if bands != null:
		for c in bands.get_children():
			bands.remove_child(c)
			c.queue_free()
		var color := Channel.color(channel)
		for y in [-h.y + 10.0, h.y - 18.0]:
			var band := Polygon2D.new()
			band.color = color
			band.polygon = PackedVector2Array([Vector2(-h.x, y), Vector2(h.x, y), Vector2(h.x, y + 8.0), Vector2(-h.x, y + 8.0)])
			bands.add_child(band)
