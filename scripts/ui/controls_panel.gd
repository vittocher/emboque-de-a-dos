extends PanelContainer
class_name ControlsPanel

## Controles de UN jugador, con el estilo de la portada (etiqueta de color del
## jugador + teclas crema) sobre un panel de madera. Las teclas se leen del Input
## Map (KeyCap), así que reflejan cualquier cambio en project.godot. La fila de
## lanzar solo aparece si el nivel tiene la mecánica (LevelRules.throw_enabled).
## Lo usa el menú de pausa: uno a cada lado del tablero.

@export_enum("p1", "p2") var prefix: String = "p1"
@export var font_size: int = 18

## Colores de las etiquetas de la portada.
const TAG_COLORS := {"p1": Color(1.0, 0.58, 0.4), "p2": Color(0.56, 0.8, 0.97)}
const THROW_TEXT_COLOR := Color(0.56, 0.86, 0.35)
const TEXT_COLOR := Color(0.96, 0.94, 0.88)
const INK := Color(0.07, 0.08, 0.16)

## [acciones (sin prefijo), clave del texto, solo con lanzar]
const ROWS := [
	[["left", "right"], "CTRL_MOVE", false],
	[["jump"], "CTRL_JUMP", false],
	[["release"], "CTRL_LET_OUT", false],
	[["pull"], "CTRL_REEL_IN", false],
	[["down"], "CTRL_UNHOOK", false],
	[["throw"], "CTRL_THROW", true],
]

var _bold: FontVariation

func _ready() -> void:
	_bold = FontVariation.new()
	_bold.base_font = ThemeDB.fallback_font
	_bold.variation_embolden = 0.8
	var rules := LevelRules.of(get_tree())
	var throw_enabled := rules != null and rules.throw_enabled
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 9)
	list.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(list)
	list.add_child(_make_tag())
	for row: Array in ROWS:
		if row[2] and not throw_enabled:
			continue
		list.add_child(_make_row(row[0], row[1], THROW_TEXT_COLOR if row[2] else TEXT_COLOR))

func _make_tag() -> Control:
	var tag := Label.new()
	tag.text = "CONTROLS_" + prefix.to_upper()
	tag.uppercase = true
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = TAG_COLORS[prefix]
	style.set_corner_radius_all(6)
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	tag.add_theme_stylebox_override("normal", style)
	tag.add_theme_font_override("font", _bold)
	tag.add_theme_font_size_override("font_size", font_size)
	tag.add_theme_color_override("font_color", INK)
	return tag

func _make_row(actions: Array, text_key: String, color: Color) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = MOUSE_FILTER_IGNORE
	for i in actions.size():
		if i > 0:
			var slash := Label.new()
			slash.text = "/"
			slash.add_theme_color_override("font_color", Color(TEXT_COLOR, 0.55))
			slash.add_theme_font_size_override("font_size", font_size)
			row.add_child(slash)
		var cap := KeyCap.new()
		cap.action = StringName(prefix + "_" + actions[i])
		row.add_child(cap)
	var label := Label.new()
	label.text = text_key
	label.add_theme_font_override("font", _bold)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
	label.add_theme_constant_override("outline_size", 4)
	label.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(label)
	return row
