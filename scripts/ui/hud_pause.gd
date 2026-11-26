extends PanelContainer

## Indicador de pausa del HUD (esquina superior izquierda): una tecla de madera
## con la "P" y al lado "Pausa", en una placa de madera como los botones del
## menú. Va dentro de ui/pause_menu.tscn (así está en todos los niveles), que lo
## oculta mientras el juego está en pausa. Con el mouse encima brilla y un clic
## pausa (útil en web, donde Esc lo toma la pantalla completa).

signal pressed

@onready var _fondo: WoodPlaque = $Fondo

var _tween: Tween

func _ready() -> void:
	mouse_entered.connect(func() -> void:
		UiFx.hover_sound()
		_set_lit(true))
	mouse_exited.connect(_set_lit.bind(false))
	# Al ocultarse con el mouse encima no llega mouse_exited: que no vuelva
	# brillando al reanudar.
	visibility_changed.connect(func() -> void:
		_fondo.active = false
		scale = Vector2.ONE)

## Con el mouse encima la placa brilla y crece un poco.
func _set_lit(lit: bool) -> void:
	_fondo.active = lit
	pivot_offset = size * 0.5
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE * (1.06 if lit else 1.0), 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		pressed.emit()
