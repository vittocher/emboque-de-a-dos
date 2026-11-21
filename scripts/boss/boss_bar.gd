extends PanelContainer
class_name BossBar

## Vida del Tue Tue en el HUD (arriba al centro): su nombre y una pluma dorada por
## vida sobre madera, como la placa de puntaje. BossFight llama setup() y set_hp().

const FULL := Color(1, 1, 1, 1)
const EMPTY := Color(0.15, 0.1, 0.18, 0.55)

@export var feather_texture: Texture2D

@onready var _pips: HBoxContainer = $Margin/Row/Pips

var _tween: Tween

func setup(max_hp: int) -> void:
	for c in _pips.get_children():
		c.queue_free()
	for i in max_hp:
		var pip := TextureRect.new()
		pip.texture = feather_texture
		pip.custom_minimum_size = Vector2(32, 32)
		pip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pips.add_child(pip)

## Vidas que le quedan: las perdidas se apagan, con un saltito de la placa.
func set_hp(hp: int) -> void:
	var i := 0
	for pip in _pips.get_children():
		(pip as CanvasItem).modulate = FULL if i < hp else EMPTY
		i += 1
	if _tween != null:
		_tween.kill()
	pivot_offset = size * 0.5
	scale = Vector2.ONE * 1.18
	_tween = create_tween().set_ignore_time_scale()
	_tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Aparece/desaparece con un fundido.
func show_bar(on: bool) -> void:
	var tw := create_tween()
	if on:
		visible = true
		modulate.a = 0.0
		tw.tween_property(self, "modulate:a", 1.0, 0.4)
	else:
		tw.tween_property(self, "modulate:a", 0.0, 0.6)
		tw.tween_callback(hide)
