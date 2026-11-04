extends Control

## Pantalla de victoria: nombre del nivel, puntaje, sopaipillas juntadas y récord.
## Lee los datos de la victoria desde ScoreBoard (el WinManager del nivel los deja
## ahí antes de cambiar a esta escena). Continuar vuelve al mapa de niveles (que
## anima lo que se desbloqueó); Reintentar vuelve a jugar el mismo nivel.

const MAP_SCENE := "res://scenes/ui/level_selector.tscn"

@onready var _subtitle: Label = $Center/VBox/Subtitle
@onready var _score: Label = $Center/VBox/ScoreLabel
@onready var _collected: Label = $Center/VBox/Collected/Count
@onready var _collected_row: Control = $Center/VBox/Collected
@onready var _record: Label = $Center/VBox/HighscoreLabel
@onready var _continue: Control = $Center/VBox/Buttons/ContinueButton
@onready var _retry: Control = $Center/VBox/Buttons/RetryButton

func _ready() -> void:
	get_tree().paused = false
	if ScoreBoard.last_level_name != "":
		var number := LevelCatalog.number_of(ScoreBoard.last_level_id)
		_subtitle.text = ScoreBoard.last_level_name if number == 0 \
			else "%d · %s" % [number, ScoreBoard.last_level_name]
	_score.text = "Puntaje: %d" % ScoreBoard.last_score
	_collected_row.visible = ScoreBoard.last_total > 0
	_collected.text = "%d / %d" % [ScoreBoard.last_collected, ScoreBoard.last_total]
	var best := ScoreBoard.get_highscore(ScoreBoard.last_level_id)
	if ScoreBoard.last_is_record and ScoreBoard.last_score > 0:
		_record.text = "¡Nuevo récord!"
		_record.add_theme_color_override("font_color", Color(1, 0.86, 0.38))
	else:
		_record.text = "Mejor puntaje: %d" % best
	_continue.pressed.connect(_on_continue)
	_retry.pressed.connect(_on_retry)
	_retry.visible = _level_scene() != ""
	(_continue.get_node("Btn") as Button).grab_focus()

func _level_scene() -> String:
	return LevelCatalog.get_level(ScoreBoard.last_level_id).get("scene", "")

func _on_continue() -> void:
	get_tree().change_scene_to_file(MAP_SCENE)

func _on_retry() -> void:
	get_tree().change_scene_to_file(_level_scene())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_continue()
