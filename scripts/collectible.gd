extends Area2D
class_name Collectible

## Coleccionable: lo recoge un jugador o un extremo del emboque (palito/campana;
## la cuerda es solo visual, no recoge). Mask 14 = jugadores 2 + campana 4 + palito 8.

@export var points: int = 100

# queue_free es diferido: si un jugador y su extremo lo tocan en el mismo tick,
# sin esto sumaría dos veces.
var _collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _collected or not (body is Player or body is RopeEnd):
		return
	var score_manager := get_tree().get_first_node_in_group("score_manager") as ScoreManager
	if score_manager == null:
		push_warning("Collectible needs a ScoreManager in the current level.")
		return
	_collected = true
	score_manager.add_points(points)
	queue_free()
