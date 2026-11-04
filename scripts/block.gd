@tool
extends StaticBody2D
class_name Block

## Bloque de terreno rectangular (piso, plataforma o muro) con su tamaño editable
## en el Inspector. Crea su propia forma de colisión y el placeholder "Visual";
## el arte real lo pone TerrainArt (piso si es más ancho que alto, muro si no).
## Para trazar un nivel basta instanciar scenes/block.tscn y ajustar position + size.

## Tamaño en px (ancho, alto). La posición del nodo es el CENTRO del bloque.
@export var size := Vector2(200, 24):
	set(value):
		size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_apply()

func _enter_tree() -> void:
	# En _enter_tree (antes de cualquier _ready): TerrainArt, que está antes en el
	# árbol del nivel, lee la forma en su _ready y ya la encuentra con su tamaño.
	_apply()

func _apply() -> void:
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null:
		var rect := cs.shape as RectangleShape2D
		# Cada bloque necesita su propia forma (si no, todas las instancias
		# compartirían el tamaño de la última).
		if rect == null or not rect.resource_local_to_scene:
			rect = RectangleShape2D.new()
			rect.resource_local_to_scene = true
			cs.shape = rect
		rect.size = size
	var visual := get_node_or_null("Visual") as Polygon2D
	if visual != null:
		var h := size * 0.5
		visual.polygon = PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y),
				Vector2(h.x, h.y), Vector2(-h.x, h.y)])

## Borde superior del bloque en coordenadas globales (donde se para un jugador).
func top_y() -> float:
	return global_position.y - size.y * 0.5
