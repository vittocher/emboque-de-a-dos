extends PanelContainer

## Indicador de pausa del HUD (esquina superior izquierda): una tecla de madera
## con la "P" y al lado "Pausa", en una placa de madera como los botones del
## menú. Va dentro de ui/pause_menu.tscn (así está en todos los niveles), que lo
## oculta mientras el juego está en pausa. Con el mouse encima brilla y un clic
## pausa (útil en web, donde Esc lo toma la pantalla completa).

signal pressed

@onready var _fondo: WoodPlaque = $Fondo

func _ready() -> void:
	mouse_entered.connect(func() -> void: _fondo.active = true)
	mouse_exited.connect(func() -> void: _fondo.active = false)
	# Al ocultarse con el mouse encima no llega mouse_exited: que no vuelva
	# brillando al reanudar.
	visibility_changed.connect(func() -> void: _fondo.active = false)

func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		pressed.emit()
