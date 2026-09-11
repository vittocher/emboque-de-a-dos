extends Node
class_name ScoreManager

@export var score_label: NodePath

var score: int = 0
var _label: Label

func _ready() -> void:
	add_to_group("score_manager")
	_label = get_node_or_null(score_label) as Label
	_update_label()

func add_points(points: int) -> void:
	score += points
	_update_label()

func _update_label() -> void:
	if _label != null:
		_label.text = "Puntos: %d" % score
