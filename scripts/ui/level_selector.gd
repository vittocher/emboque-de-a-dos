extends Control

## Selector de niveles, en grilla: cada FILA es un tema (1 = ganchos, 2 = cajas,
## 3 = lanzar) y cada COLUMNA (A, B, C, D) el orden dentro de la fila. Los niveles
## de prueba van abajo. Los botones se arman solos desde ROWS / TESTS:
## - el texto es el level_name del WinManager de cada escena,
## - los niveles con la mecánica de lanzar (LevelRules.throw_enabled) salen en
##   verde (LevelRules.THROW_COLOR).
## Para agregar un nivel: crear la escena, ponerle level_id / level_name en su
## WinManager y agregar su ruta a su fila acá.

const ROWS := [
	{"title": "1 · Ganchos", "scenes": [
		"res://scenes/level_1a.tscn",
		"res://scenes/level_1b.tscn",
	]},
	{"title": "2 · Cajas", "scenes": [
		"res://scenes/level_2a.tscn",
	]},
	{"title": "3 · Lanzar", "scenes": [
		"res://scenes/level_3a.tscn",
	]},
]
const TESTS := [
	"res://scenes/test_death.tscn",
	"res://scenes/test_physics.tscn",
]
## Columnas por fila: A–D.
const MAX_COLUMNS := 4

const LEVEL_BUTTON_SIZE := Vector2(170, 100)
const TEST_BUTTON_SIZE := Vector2(170, 56)
const ROW_LABEL_WIDTH := 170.0
## Grosor del borde de los botones de niveles con lanzar (px).
const THROW_BORDER := 3

@onready var _rows: VBoxContainer = $Center/VBox/Rows
@onready var _tests: HBoxContainer = $Center/VBox/Tests

func _ready() -> void:
	$BackButton.pressed.connect(_on_back_pressed)
	for row: Dictionary in ROWS:
		if row.scenes.size() > MAX_COLUMNS:
			push_warning("Fila '%s' con más de %d niveles" % [row.title, MAX_COLUMNS])
		var line := _add_row(_rows, row.title, 26)
		for path: String in row.scenes:
			_add_level_button(line, path, LEVEL_BUTTON_SIZE, 26)
	var tests_line := _add_row(_tests, "Pruebas", 20)
	for path: String in TESTS:
		_add_level_button(tests_line, path, TEST_BUTTON_SIZE, 18)

func _on_back_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _go_to_level(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)

## Una fila: título de ancho fijo (así las columnas quedan alineadas) + botones.
func _add_row(parent: Container, title: String, font_size: int) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override(&"separation", 24)
	parent.add_child(line)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size = Vector2(ROW_LABEL_WIDTH, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", font_size)
	line.add_child(label)
	return line

func _add_level_button(line: HBoxContainer, path: String, size: Vector2, font_size: int) -> void:
	var scene := load(path) as PackedScene
	var button := Button.new()
	button.text = LevelRules.scene_value(scene, &"level_name", path.get_file().get_basename())
	button.custom_minimum_size = size
	button.add_theme_font_size_override(&"font_size", font_size)
	button.pressed.connect(_go_to_level.bind(path))
	line.add_child(button)
	if LevelRules.scene_throw_enabled(scene):
		_mark_throw_level(button)

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
