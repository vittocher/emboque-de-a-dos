extends Control

## Selector de niveles. Más adelante los niveles se mostrarán todos como un grafo
## conectado; para eso, extender LEVEL_BUTTONS y disponer los botones con líneas
## de conexión.
##
## Los niveles con la mecánica de lanzar (LevelRules.throw_enabled) se marcan
## solos con LevelRules.THROW_COLOR.

## Botón (en Center/LevelsRow) → escena del nivel. Para agregar un nivel: su
## botón en level_selector.tscn + una línea acá.
const LEVEL_BUTTONS := {
	"Level1Button": "res://scenes/main.tscn",
	"Level2Button": "res://scenes/level_2.tscn",
	"Level3Button": "res://scenes/level_3.tscn",
	"TestDeathButton": "res://scenes/test_death.tscn",
	"TestPhysicsButton": "res://scenes/test_physics.tscn",
	"TestThrowButton": "res://scenes/test_throw.tscn",
}
## Grosor del borde de los botones de niveles con lanzar (px).
const THROW_BORDER := 3

func _ready() -> void:
	$BackButton.pressed.connect(_on_back_pressed)
	for button_name: String in LEVEL_BUTTONS:
		var button := get_node("Center/LevelsRow/" + button_name) as Button
		var path: String = LEVEL_BUTTONS[button_name]
		button.pressed.connect(_go_to_level.bind(path))
		if LevelRules.scene_throw_enabled(load(path)):
			_mark_throw_level(button)

func _on_back_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _go_to_level(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)

## Texto y borde del botón en el color de la mecánica de lanzar.
func _mark_throw_level(button: Button) -> void:
	for color_name in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		button.add_theme_color_override(color_name, LevelRules.THROW_COLOR)
	for style_name in [&"normal", &"hover", &"pressed", &"focus"]:
		var box := button.get_theme_stylebox(style_name).duplicate() as StyleBoxFlat
		if box == null:
			continue
		box.border_color = LevelRules.THROW_COLOR
		box.set_border_width_all(THROW_BORDER)
		button.add_theme_stylebox_override(style_name, box)
