extends PanelContainer
class_name LevelHint

## Cartel de controles dentro de un nivel (el primero de una mecánica): filas de
## teclas + texto con el estilo de la pausa y la portada, sobre madera. Va en la
## UI del nivel (ui/level_hint.tscn); uno por jugador, en su mitad de la pantalla.
##
## Cada fila es un texto con fichas separadas por espacios:
##   "@accion" → la tecla de esa acción del Input Map (p. ej. @p1_release)
##   "/"       → una barra
##   lo demás  → una clave de i18n/textos.csv (se traduce sola)
## Ejemplo: "@p1_release HINT_LET_OUT".

## Etiqueta "Jugador N" arriba ("ninguno" = sin etiqueta).
@export_enum("ninguno", "p1", "p2") var player: String = "ninguno"
@export var rows: PackedStringArray = PackedStringArray()
@export var font_size: int = 18

const TEXT_COLOR := Color(0.96, 0.94, 0.88)

var _bold: FontVariation

func _ready() -> void:
	_bold = ControlsPanel.bold_font()
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(list)
	if player in ControlsPanel.TAG_COLORS:
		list.add_child(ControlsPanel.make_tag(player, font_size, _bold))
	for spec in rows:
		list.add_child(_make_row(spec))

func _make_row(spec: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = MOUSE_FILTER_IGNORE
	for token in spec.split(" ", false):
		if token.begins_with("@"):
			var cap := KeyCap.new()
			cap.action = StringName(token.substr(1))
			row.add_child(cap)
		elif token == "/":
			row.add_child(_make_label("/", Color(TEXT_COLOR, 0.55)))
		else:
			row.add_child(_make_label(token, TEXT_COLOR))
	return row

func _make_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", _bold)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.size_flags_vertical = SIZE_SHRINK_CENTER
	return label
