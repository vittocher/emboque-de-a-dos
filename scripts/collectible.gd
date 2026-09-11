extends Area2D
class_name Collectible

@export var points: int = 100

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	var score_manager := get_tree().get_first_node_in_group("score_manager") as ScoreManager
	if score_manager == null:
		push_warning("Collectible needs a ScoreManager in the current level.")
		return
	score_manager.add_points(points)
	queue_free()
