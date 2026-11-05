@tool
extends StaticBody2D

## Cuenco en V (la "meta" de muchos niveles): dos tablas inclinadas y
## resbalosas; lo que cae adentro se desliza al fondo, así los dos extremos del
## emboque se juntan solos. El arte lo pone TerrainArt (tablas de piso).

## Ancho total (px), de punta a punta.
@export var width := 142.0:
	set(value):
		width = maxf(value, 40.0)
		_apply()
## Inclinación de cada tabla (radianes).
@export var slope := 0.42:
	set(value):
		slope = clampf(value, 0.1, 1.2)
		_apply()

const THICKNESS := 12.0

func _enter_tree() -> void:
	_apply()

func _apply() -> void:
	var half := width * 0.5
	var length := half / cos(slope) + THICKNESS * 0.5
	for side in [-1, 1]:
		var cs := get_node_or_null("LeftPlank" if side < 0 else "RightPlank") as CollisionShape2D
		if cs == null:
			continue
		var rect := cs.shape as RectangleShape2D
		if rect == null or not rect.resource_local_to_scene:
			rect = RectangleShape2D.new()
			rect.resource_local_to_scene = true
			cs.shape = rect
		rect.size = Vector2(length, THICKNESS)
		cs.position = Vector2(side * half * 0.5, 0)
		cs.rotation = -side * slope
	var visual := get_node_or_null("Visual") as Polygon2D
	if visual != null:
		var dy := half * tan(slope) * 0.5
		visual.polygon = PackedVector2Array([Vector2(-half, -dy - 6), Vector2(0, dy - 6), Vector2(half, -dy - 6),
				Vector2(half, -dy + 6), Vector2(0, dy + 6), Vector2(-half, -dy + 6)])
