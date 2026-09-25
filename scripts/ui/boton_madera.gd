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

## El glow dorado se activa con mouse encima o foco de teclado.
func _refresh() -> void:
	var mat := _fondo.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("active", 1.0 if (_hover or _focus) else 0.0)

func _update_size() -> void:
	var mat := _fondo.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("rect_size", size)
