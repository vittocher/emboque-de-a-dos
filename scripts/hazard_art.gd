@tool
extends Node2D
class_name HazardArt

## Arte animado de una zona de peligro: llena el rectángulo de [member shape_path]
## con cuadros animados tan altos como la zona, repetidos a lo ancho. Así el dibujo
## no se deforma aunque la instancia de la zona esté escalada (p. ej. un piso de
## 1280×48). Va como hijo directo de la raíz de la zona (se usa la escala de esa raíz).
## Es @tool para que se vea igual en el editor al escalar la zona.

## Animación de cada cuadro (en loop).
@export var frames: SpriteFrames
## Nombre de la animación dentro de [member frames].
@export var animation: StringName = &"default"
## CollisionShape2D (con RectangleShape2D) cuyo rectángulo se llena.
@export var shape_path: NodePath

var _built_scale := Vector2.ZERO

func _ready() -> void:
	_build()
	# En juego la escala no cambia: solo el editor necesita reconstruir.
	set_process(Engine.is_editor_hint())

func _process(_delta: float) -> void:
	if _zone_scale() != _built_scale:
		_build()

func _zone_scale() -> Vector2:
	var zone := get_parent() as Node2D
	return zone.scale if zone != null else Vector2.ONE

func _build() -> void:
	var old := get_node_or_null("Tiles")
	if old != null:
		remove_child(old)
		old.queue_free()
	var zone_scale := _zone_scale()
	_built_scale = zone_scale
	var shape_node := get_node_or_null(shape_path) as CollisionShape2D
	var rect := shape_node.shape as RectangleShape2D if shape_node != null else null
	if rect == null or frames == null or not frames.has_animation(animation) \
			or zone_scale.x == 0.0 or zone_scale.y == 0.0:
		return
	# Contenedor que deshace la escala de la zona: adentro se trabaja en px reales.
	# No tiene owner, así que no se guarda en la escena.
	var tiles := Node2D.new()
	tiles.name = "Tiles"
	tiles.scale = Vector2.ONE / zone_scale
	add_child(tiles)
	var size := rect.size * zone_scale.abs()
	var count := maxi(1, roundi(size.x / size.y))
	# Cuadros casi cuadrados: se estiran apenas a lo ancho para llenar justo la zona.
	var tile := Vector2(size.x / count, size.y)
	var frame_count := frames.get_frame_count(animation)
	var tex_size := frames.get_frame_texture(animation, 0).get_size()
	for i in count:
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = frames
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.scale = tile / tex_size
		sprite.position = Vector2(-size.x * 0.5 + tile.x * (i + 0.5), 0.0)
		tiles.add_child(sprite)
		sprite.play(animation)
		# Cada cuadro parte en otro frame para que no parpadeen todos juntos.
		sprite.frame = i % frame_count
