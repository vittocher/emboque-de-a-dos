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

@export_group("Brillo")
## Luz difusa alrededor de toda la zona (se suma al fondo). Alfa 0 = sin brillo;
## el alfa es la intensidad.
@export var glow_color := Color(1, 1, 1, 0)
## Hasta dónde llega la luz (px).
@export var glow_radius := 70.0
## Corrimiento de la luz (px; negativo en y = sube, como el calor).
@export var glow_offset := Vector2.ZERO
## Parpadeo rápido (0..1) y respiración lenta (0..1) de la luz.
@export_range(0.0, 1.0) var glow_flicker := 0.0
@export_range(0.0, 1.0) var glow_breathe := 0.0
## Rapidez del parpadeo / la respiración.
@export var glow_speed := 1.0
## Fracción de la luz que también se dibuja ENCIMA del terreno y los jugadores
## (los tiñe al acercarse). 0 = la luz queda solo sobre el fondo.
@export_range(0.0, 1.0) var glow_front := 0.0
## Alcance de esa luz de encima, relativo a glow_radius.
@export_range(0.1, 1.0) var glow_front_radius := 0.6
## Degradado desde el centro: la luz es glow_core × alfa en la línea central de la
## zona y baja hasta 0 a glow_radius del borde. 0 = pareja dentro de la zona.
@export_range(0.0, 6.0) var glow_core := 0.0
## Curva del degradado (1 = lineal; más alto = centro más concentrado).
@export_range(0.5, 6.0) var glow_core_power := 2.0

@export_group("Halo")
## Halo con la FORMA del dibujo, detrás de él: luz (halo_additive = true) o sombra
## (false). Alfa 0 = sin halo; el alfa es la intensidad.
@export var halo_color := Color(1, 1, 1, 0)
## Difuminado del halo (px).
@export var halo_blur := 6.0
## Engorda el halo (0..1).
@export_range(0.0, 1.0) var halo_grow := 0.0
## Corrimiento del halo (px del mundo).
@export var halo_offset := Vector2.ZERO
@export var halo_additive := true

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
	if glow_color.a > 0.0:
		_add_glow(tiles, size, glow_color, glow_radius, VisualFx.Z_GLOW, "Glow")
		if glow_front > 0.0:
			_add_glow(tiles, size, Color(glow_color, glow_color.a * glow_front),
					glow_radius * glow_front_radius, VisualFx.Z_LIGHT, "GlowFront")
	var halo_mat: ShaderMaterial = null
	if halo_color.a > 0.0:
		halo_mat = VisualFx.silhouette_material({
			"tint": halo_color,
			"blur_px": halo_blur,
			"grow": halo_grow,
			"additive": 1.0 if halo_additive else 0.0,
			"flicker": glow_flicker * 0.5,
			"flicker_speed": glow_speed,
		})
	for i in count:
		var pos := Vector2(-size.x * 0.5 + tile.x * (i + 0.5), 0.0)
		# Cada cuadro parte en otro frame para que no parpadeen todos juntos.
		if halo_mat != null:
			var halo := _make_tile(tiles, tile / tex_size, pos + halo_offset, i % frame_count)
			halo.material = halo_mat
			halo.z_index = VisualFx.Z_HALO
			halo.z_as_relative = false
		_make_tile(tiles, tile / tex_size, pos, i % frame_count)

## Luz difusa (aditiva) alrededor del rectángulo de la zona.
func _add_glow(parent: Node2D, size: Vector2, color: Color, radius: float, z: int, node_name: String) -> void:
	VisualFx.soft_box(parent, size, Vector2.ZERO, radius * 1.1 + glow_offset.length(), z, {
		"tint": color,
		"additive": 1.0,
		"offset": glow_offset,
		"radius": radius,
		"corner": size.y * 0.5,
		"flicker": glow_flicker,
		"breathe": glow_breathe,
		"flicker_speed": glow_speed,
		"core": glow_core,
		"core_power": glow_core_power,
	}, node_name)

func _make_tile(parent: Node2D, tile_scale: Vector2, pos: Vector2, start_frame: int) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.scale = tile_scale
	sprite.position = pos
	parent.add_child(sprite)
	sprite.play(animation)
	sprite.frame = start_frame
	return sprite
