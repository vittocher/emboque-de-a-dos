extends Control

## Selector de niveles. Por ahora un solo nivel (el que estamos desarrollando).
## Más adelante los niveles se mostrarán todos como un grafo conectado; para eso,
## extender LEVELS y disponer los botones con líneas de conexión.

const LEVELS := [
	"res://scenes/main.tscn",
	"res://scenes/level_2.tscn",
]

func _ready() -> void:
	$BackButton.pressed.connect(_on_back_pressed)
	$Center/LevelsRow/Level1Button.pressed.connect(_on_level_1_pressed)
	$Center/LevelsRow/Level2Button.pressed.connect(_on_level_2_pressed)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_level_1_pressed() -> void:
	get_tree().change_scene_to_file(LEVELS[0])

func _on_level_2_pressed() -> void:
	get_tree().change_scene_to_file(LEVELS[1])
