extends Control

## Selector de niveles. Por ahora un solo nivel (el que estamos desarrollando).
## Más adelante los niveles se mostrarán todos como un grafo conectado; para eso,
## extender LEVELS y disponer los botones con líneas de conexión.

const LEVELS := [
	"res://scenes/main.tscn",
]

@onready var _back_button: Button = $BackButton
@onready var _level_1_button: Button = $Center/LevelsRow/Level1Button

func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_level_1_button.pressed.connect(_on_level_1_pressed)

func _on_back_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_level_1_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(LEVELS[0])
