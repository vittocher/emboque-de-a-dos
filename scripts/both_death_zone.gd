@tool
extends Node2D

## Zona que mata al jugador Y al emboque: compone PlayerKill + EmboqueKill.
## Este script solo arma el arte: llena el rectángulo de la zona con cuadros
## animados (fuego) tan altos como la zona, repetidos a lo ancho. Así el dibujo no
## se deforma aunque la instancia esté escalada (p. ej. el piso de 1280×48).
## Es @tool para que se vea igual en el editor al escalar la zona.

## Animación de cada cuadro (en loop).
@export var frames: SpriteFrames
## Nombre de la animación dentro de [member frames].
@export var animation: StringName = &"default"

var _built_scale := Vector2.ZERO

@onready var _shape: RectangleShape2D = $PlayerKill/CollisionShape2D.shape

func _ready() -> void:
	_build()
	# En juego la escala no cambia: solo el editor necesita reconstruir.
	set_process(Engine.is_editor_hint())

func _process(_delta: float) -> void:
	if scale != _built_scale:
		_build()

func _build() -> void:
	var old := get_node_or_null("Art")
	if old != null:
		remove_child(old)
		old.queue_free()
	_built_scale = scale
	if frames == null or not frames.has_animation(animation) or scale.x == 0.0 or scale.y == 0.0:
		return
	# Contenedor que deshace la escala de la instancia: adentro se trabaja en px reales.
	var art := Node2D.new()
	art.name = "Art"
	art.scale = Vector2.ONE / scale
	add_child(art)
	var size := _shape.size * scale.abs()
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
		art.add_child(sprite)
		sprite.play(animation)
		# Cada cuadro parte en otro frame para que no parpadeen todos juntos.
		sprite.frame = i % frame_count
