extends Control

## Selector de niveles. Más adelante los niveles se mostrarán todos como un grafo
## conectado; para eso, extender los botones/rutas y disponerlos con líneas.

func _ready() -> void:
	$BackButton.pressed.connect(_on_back_pressed)
	$Center/LevelsRow/Level1Button.pressed.connect(
		_load_level.bind("res://scenes/main.tscn"))
	$Center/LevelsRow/TestDeathButton.pressed.connect(
		_load_level.bind("res://scenes/test_death.tscn"))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _load_level(path: String) -> void:
	get_tree().change_scene_to_file(path)
