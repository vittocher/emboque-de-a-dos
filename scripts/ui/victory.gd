extends Control

## Pantalla de victoria: muestra el puntaje de la partida y el récord del nivel,
## y permite volver al menú principal. Lee los datos de la victoria desde ScoreBoard
## (el WinManager del nivel los deja ahí antes de cambiar a esta escena).

func _ready() -> void:
	if ScoreBoard.last_level_name != "":
		$Center/VBox/Subtitle.text = ScoreBoard.last_level_name
	$Center/VBox/ScoreLabel.text = "Puntaje: %d" % ScoreBoard.last_score
	var best := ScoreBoard.get_highscore(ScoreBoard.last_level_id)
	if ScoreBoard.last_is_record:
		$Center/VBox/HighscoreLabel.text = "¡Nuevo récord!  %d" % best
	else:
		$Center/VBox/HighscoreLabel.text = "Mejor puntaje: %d" % best
	$Center/VBox/MainMenuButton.pressed.connect(_on_main_menu_pressed)

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
