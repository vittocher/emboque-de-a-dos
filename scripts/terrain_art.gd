@tool
extends Node
class_name TerrainArt

## Arte del terreno de un nivel: cubre cada StaticBody2D del nivel (todo lo que
## cuelga del padre de este nodo) con su textura, según la forma de su
## CollisionShape2D rectangular: más ancho que alto → piso (piso, plataformas,
## puentes); más alto que ancho → [member wall_texture] (muros).
## Un piso de varios cuadros se arma con extremo izquierdo + tramos del medio +
## extremo derecho ([member floor_left], [member floor_middle], [member floor_right]);
## si cabe un solo cuadro, usa [member floor_texture] (tabla completa).
## La textura se repite en una grilla sin deformarse (solo se ajusta un poco
## para llenar justo el rectángulo). En juego oculta el Polygon2D "Visual" de cada
## cuerpo; en el editor lo deja debajo como referencia.
## Es @tool: al mover o redimensionar terreno en el editor, el arte se actualiza.
## Para usarlo en un nivel basta instanciar scenes/terrain_art.tscn.

## Piso de un solo cuadro (tabla con ambos extremos). También es el respaldo si
## falta alguna de las otras piezas.
@export var floor_texture: Texture2D
## Extremo izquierdo de un piso de varios cuadros.
@export var floor_left: Texture2D
## Tramo del medio (se repite).
@export var floor_middle: Texture2D
## Extremo derecho de un piso de varios cuadros.
@export var floor_right: Texture2D
## Textura de muros (rectángulos verticales).
@export var wall_texture: Texture2D
## Pisos más gruesos que esto (px) se dibujan como una tabla de piso arriba y
## el cuerpo con [member wall_texture] (terreno macizo).
@export var thick_floor_height: float = 40.0
## Alto de la tabla de piso de arriba en los bloques gruesos (px).
@export var floor_top_height: float = 24.0

@export_group("Sombra")
## Sombra difusa de cada pieza de terreno sobre el fondo (la despega de la pared).
## Alfa 0 = sin sombra.
@export var shadow_color := Color(0.0, 0.0, 0.0, 0.5)
## Corrimiento de la sombra (px del mundo): hacia donde no viene la luz.
@export var shadow_offset := VisualFx.LIGHT_OFFSET * 1.4
## Difuminado de la sombra corrida (px).
@export var shadow_radius := 16.0
## Oscurecimiento parejo alrededor de todo el contorno (oclusión ambiental),
## relativo a shadow_color (0 = nada).
@export_range(0.0, 1.0) var ao_strength := 0.55
## Ancho de ese oscurecimiento (px).
@export var ao_radius := 9.0

## Prefijo de los nodos generados (no tienen owner: no se guardan en la escena).
const ART_PREFIX := "TerrainArt_"

var _signature: Array = []

func _ready() -> void:
	_build_all()
	# En juego el terreno no cambia: solo el editor necesita reconstruir.
	set_process(Engine.is_editor_hint())

func _process(_delta: float) -> void:
	if _compute_signature() != _signature:
		_build_all()

## Formas rectangulares de todos los StaticBody2D del nivel.
func _collect_shapes() -> Array[CollisionShape2D]:
	var result: Array[CollisionShape2D] = []
	var level := get_parent()
	if level == null:
		return result
	for body in level.find_children("*", "StaticBody2D", true, false):
		for child in body.get_children():
			var cs := child as CollisionShape2D
			if cs != null and cs.shape is RectangleShape2D:
				result.append(cs)
	return result

## Lo que, si cambia, obliga a rehacer el arte (editor).
func _compute_signature() -> Array:
	var sig: Array = [floor_texture, floor_left, floor_middle, floor_right, wall_texture,
			thick_floor_height, floor_top_height, shadow_color, shadow_offset, shadow_radius,
			ao_strength, ao_radius]
	for cs in _collect_shapes():
		var body := cs.get_parent() as Node2D
		sig.append([cs.get_instance_id(), (cs.shape as RectangleShape2D).size,
				cs.transform, body.scale])
	return sig

func _build_all() -> void:
	_signature = _compute_signature()
	for cs in _collect_shapes():
		_build(cs)

func _build(cs: CollisionShape2D) -> void:
	var body := cs.get_parent() as Node2D
	var art_name := ART_PREFIX + cs.name
	var old := body.get_node_or_null(NodePath(art_name))
	if old != null:
		body.remove_child(old)
		old.queue_free()
	if not Engine.is_editor_hint():
		var visual := body.get_node_or_null("Visual") as CanvasItem
		if visual != null:
			visual.visible = false
	var rect := cs.shape as RectangleShape2D
	var total_scale := body.scale * cs.scale
	if total_scale.x == 0.0 or total_scale.y == 0.0:
		return
	var size := rect.size * total_scale.abs()
	var is_floor := size.x >= size.y
	if (floor_texture if is_floor else wall_texture) == null:
		return
	# Contenedor en el lugar de la forma que deshace la escala: adentro, px reales.
	# Va último entre los hijos del cuerpo, así se dibuja encima del Polygon2D.
	var tiles := Node2D.new()
	tiles.name = art_name
	tiles.position = cs.position
	tiles.rotation = cs.rotation
	tiles.scale = Vector2.ONE / body.scale
	body.add_child(tiles)
	_add_shadow(tiles, size)
	if not is_floor:
		_tile(tiles, size, Vector2.ZERO, wall_texture, false)
	elif size.y > thick_floor_height and wall_texture != null:
		# Bloque grueso: una tabla de piso arriba y el cuerpo de tablas verticales
		# (si no, se vería como varias tablas de piso apiladas, una estantería).
		var top := Vector2(size.x, floor_top_height)
		var body_size := Vector2(size.x, size.y - floor_top_height)
		_tile(tiles, body_size, Vector2(0, floor_top_height * 0.5), wall_texture, false)
		_tile(tiles, top, Vector2(0, -(size.y - floor_top_height) * 0.5), floor_texture, true)
	else:
		_tile(tiles, size, Vector2.ZERO, floor_texture, true)

## Sombra difusa de la pieza (en la capa de sombras: solo oscurece el fondo).
func _add_shadow(tiles: Node2D, size: Vector2) -> void:
	if shadow_color.a <= 0.0 or _off_screen(tiles, size):
		return
	# El corrimiento es en el mundo: se pasa al espacio de la pieza (puede estar
	# rotada, como las tablas del cuenco).
	var offset := tiles.get_global_transform().affine_inverse().basis_xform(shadow_offset)
	var margin := maxf(shadow_radius, ao_radius) * 1.2 + shadow_offset.length()
	VisualFx.soft_box(tiles, size, Vector2.ZERO, margin, VisualFx.Z_SHADOW, {
		"tint": shadow_color,
		"offset": offset,
		"radius": shadow_radius,
		"ao_strength": ao_strength,
		"ao_radius": ao_radius,
	}, "Shadow")

## true si la pieza queda entera fuera de la pantalla a lo ancho (los muros
## WallLeft/WallRight): su sombra solo oscurecería el borde de la imagen.
func _off_screen(tiles: Node2D, size: Vector2) -> bool:
	var width := float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280))
	var box := tiles.get_global_transform() * Rect2(-size * 0.5, size)
	return box.end.x <= 0.0 or box.position.x >= width

## Llena un rectángulo de [param size] centrado en [param center] con la textura
## repetida en grilla (sin deformarse: el cuadro calza con el lado más corto y se
## ajusta para que entre un número entero de cuadros).
func _tile(parent: Node2D, size: Vector2, center: Vector2, tex: Texture2D, is_floor: bool) -> void:
	var tex_size := tex.get_size()
	var fit := minf(size.x / tex_size.x, size.y / tex_size.y)
	var cols := maxi(1, roundi(size.x / (tex_size.x * fit)))
	var rows := maxi(1, roundi(size.y / (tex_size.y * fit)))
	var tile := Vector2(size.x / cols, size.y / rows)
	for r in rows:
		for c in cols:
			var sprite := Sprite2D.new()
			sprite.texture = _floor_piece(c, cols) if is_floor else tex
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			sprite.scale = tile / sprite.texture.get_size()
			sprite.position = center - size * 0.5 + tile * Vector2(c + 0.5, r + 0.5)
			parent.add_child(sprite)

## Pieza de piso para la columna [param c] de [param cols]: tabla completa si es una
## sola; si no, extremo izquierdo, tramos del medio y extremo derecho.
func _floor_piece(c: int, cols: int) -> Texture2D:
	var piece: Texture2D = null
	if cols > 1:
		if c == 0:
			piece = floor_left
		elif c == cols - 1:
			piece = floor_right
		else:
			piece = floor_middle
	return piece if piece != null else floor_texture
