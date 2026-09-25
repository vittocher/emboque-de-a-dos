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
	var sig: Array = [floor_texture, floor_left, floor_middle, floor_right, wall_texture]
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
	var tex := floor_texture if is_floor else wall_texture
	if tex == null:
		return
	# Contenedor en el lugar de la forma que deshace la escala: adentro, px reales.
	# Va último entre los hijos del cuerpo, así se dibuja encima del Polygon2D.
	var tiles := Node2D.new()
	tiles.name = art_name
	tiles.position = cs.position
	tiles.rotation = cs.rotation
	tiles.scale = Vector2.ONE / body.scale
	body.add_child(tiles)
	# Tamaño del cuadro: la textura escalada hasta calzar con el lado más corto,
	# y luego ajustada para que entre un número entero de cuadros.
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
			sprite.scale = tile / tex_size
			sprite.position = -size * 0.5 + tile * Vector2(c + 0.5, r + 0.5)
			tiles.add_child(sprite)

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
