extends Control
class_name KeyCap

## Una tecla dibujada como en la portada: tapita crema de esquinas redondeadas
## con la letra oscura. Muestra la tecla asignada a [member action] en el Input
## Map, así que si se cambian los controles en project.godot se ve al tiro. Las
## flechas se dibujan con líneas (la fuente por defecto no trae los glifos ← → en
## la web, donde no hay fuentes del sistema de respaldo).

const CAP_COLOR := Color(0.96, 0.94, 0.88)
const CAP_EDGE := Color(0.66, 0.6, 0.5)
const INK := Color(0.07, 0.08, 0.16)
## Alto del canto inferior (da volumen de tecla).
const EDGE := 3.0

## Acción del Input Map (p. ej. "p1_jump").
@export var action: StringName = &"":
	set(value):
		action = value
		_refresh()
@export var cap_height: float = 30.0
@export var font_size: int = 17

var _text := ""
var _arrow := Vector2.ZERO  # dirección si la tecla es una flecha
var _font: FontVariation
var _box: StyleBoxFlat
var _edge_box: StyleBoxFlat

func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	size_flags_vertical = SIZE_SHRINK_CENTER
	_font = FontVariation.new()
	_font.base_font = ThemeDB.fallback_font
	_font.variation_embolden = 0.8
	_box = _make_box(CAP_COLOR)
	_edge_box = _make_box(CAP_EDGE)

func _make_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(6)
	box.anti_aliasing = true
	return box

func _refresh() -> void:
	_text = ""
	_arrow = Vector2.ZERO
	var code := KeyCap.physical_key_of(action)
	match code:
		KEY_LEFT: _arrow = Vector2.LEFT
		KEY_RIGHT: _arrow = Vector2.RIGHT
		KEY_UP: _arrow = Vector2.UP
		KEY_DOWN: _arrow = Vector2.DOWN
		_: _text = KeyCap.key_name(code)
	var width := cap_height
	if _text.length() > 1:
		width = maxf(cap_height, _font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 14.0)
	custom_minimum_size = Vector2(width, cap_height)
	queue_redraw()

## Primera tecla física de una acción (KEY_NONE si no tiene).
static func physical_key_of(action_name: StringName) -> Key:
	if action_name.is_empty() or not InputMap.has_action(action_name):
		return KEY_NONE
	for ev in InputMap.action_get_events(action_name):
		var key := ev as InputEventKey
		if key != null:
			return key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	return KEY_NONE

## Nombre corto de una tecla, como se escribe en la tapita.
static func key_name(code: Key) -> String:
	match code:
		KEY_NONE: return "?"
		KEY_COMMA: return ","
		KEY_PERIOD: return "."
		KEY_ESCAPE: return "Esc"
		KEY_SPACE: return "␣"
	return OS.get_keycode_string(code)

func _draw() -> void:
	var face := Rect2(Vector2.ZERO, Vector2(size.x, size.y - EDGE))
	draw_style_box(_edge_box, Rect2(Vector2(0, EDGE), Vector2(size.x, size.y - EDGE)))
	draw_style_box(_box, face)
	var center := face.get_center()
	if _arrow != Vector2.ZERO:
		var half := face.size.y * 0.27
		var tip := center + _arrow * half
		var tail := center - _arrow * half
		draw_line(tail, tip, INK, 3.0, true)
		var back := -_arrow * half * 0.75
		draw_line(tip, tip + back.rotated(0.75), INK, 3.0, true)
		draw_line(tip, tip + back.rotated(-0.75), INK, 3.0, true)
		return
	var ascent := _font.get_ascent(font_size)
	var descent := _font.get_descent(font_size)
	var baseline := center.y + (ascent - descent) * 0.5
	draw_string(_font, Vector2(0, baseline), _text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, INK)
