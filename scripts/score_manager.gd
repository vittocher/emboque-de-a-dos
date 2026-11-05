extends Node
class_name ScoreManager

## Puntaje del nivel: suma los puntos de los coleccionables y actualiza un Label.
## Si el nivel no tiene coleccionables, oculta el Label (así la escena base de
## nivel puede traerlo siempre).

@export var score_label: NodePath

var score: int = 0
## Coleccionables juntados y totales del nivel (para el mapa: "juntó todas").
var collected: int = 0
var total: int = 0
var _label: Label

func _ready() -> void:
	add_to_group("score_manager")
	_label = get_node_or_null(score_label) as Label
	# Los coleccionables se anotan en su _enter_tree, que corre antes que
	# cualquier _ready: acá ya están todos.
	total = get_tree().get_nodes_in_group(Collectible.GROUP).size()
	if _label != null and total == 0:
		_label.visible = false
	_update_label()

func add_points(points: int) -> void:
	score += points
	collected += 1
	_update_label()

func _update_label() -> void:
	if _label != null:
		_label.text = tr("HUD_POINTS") % score

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_update_label()
