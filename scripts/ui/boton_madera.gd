extends Control

## Botón de madera reutilizable: fondo con shader procedural (esquinas
## redondeadas, borde dorado, glow al enfocar) + un Button transparente encima
## que captura el clic y el foco. Emite [signal pressed] como un botón normal.

signal pressed

@export var text: String = "Botón":
	set(value):
		text = value
		if _btn != null:
			_btn.text = value

@onready var _fondo: ColorRect = $Fondo
@onready var _btn: Button = $Btn

var _hover := false
var _focus := false

func _ready() -> void:
	_btn.text = text
	_btn.pressed.connect(func() -> void: pressed.emit())
	_btn.mouse_entered.connect(func() -> void: _hover = true; _refresh())
	_btn.mouse_exited.connect(func() -> void: _hover = false; _refresh())
	_btn.focus_entered.connect(func() -> void: _focus = true; _refresh())
	_btn.focus_exited.connect(func() -> void: _focus = false; _refresh())
	resized.connect(_update_size)
	_update_size()
	_refresh()
	_fix_hover_after_layout.call_deferred()

## Al cargar la escena el botón está un instante en (0,0) antes de que el
## contenedor lo acomode: si el mouse estaba en esa esquina (o en web, donde aún
## no se ha movido), Godot lo da por "encima" y el brillo queda pegado; y si el
## mouse sí estaba sobre el botón, no brilla hasta moverlo. Tras el primer
## cuadro, con el layout hecho, se re-sincroniza el hover con la posición real
## (emite mouse_entered/exited como corresponda).
func _fix_hover_after_layout() -> void:
	await get_tree().process_frame
	if is_inside_tree():
		get_viewport().update_mouse_cursor_state()

## El glow dorado se activa con mouse encima o foco de teclado.
func _refresh() -> void:
	var mat := _fondo.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("active", 1.0 if (_hover or _focus) else 0.0)

func _update_size() -> void:
	var mat := _fondo.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("rect_size", size)
