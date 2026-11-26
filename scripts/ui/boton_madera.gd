extends Control
class_name BotonMadera

## Botón de madera reutilizable (menú principal, mapa, victoria). Se lee como un
## botón de verdad: tabla con canto y sombra que se hunde al apretarla; al
## resaltarla (mouse encima o foco de teclado) crece un poco, se aclara, se
## prende el borde dorado con un halo y la cruza un destello. Emite
## [signal pressed] como un botón normal.
##
## Estructura: Cara (lo visual; crece y aparece sin mover el área de clic) con
## Fondo (shader madera_boton: tabla, canto, sombra) y Texto (Button solo de
## dibujo: texto + ícono), y encima Btn, el Button transparente que recibe clic
## y foco. Sonido, cursor de mano y foco con el mouse los pone el autoload UiFx.

signal pressed

## Margen a los costados cuando el botón lleva ícono (que no toque el borde).
const ICON_MARGIN := 18.0
## Alto del canto (px): la cara se hunde esto al apretar. Igual que `depth` del
## material y que el offset_bottom de Texto en la escena.
const DEPTH := 7.0
## Escala de la cara resaltada.
const LIT_SCALE := 1.045

@export var text: String = "Botón":
	set(value):
		text = value
		if _texto != null:
			_texto.text = value

## Ícono a la izquierda del texto (p. ej. la bandera del botón de idioma).
@export var icon: Texture2D:
	set(value):
		icon = value
		if _texto != null:
			_texto.icon = value
## Ancho máximo del ícono (px); 0 = su tamaño real.
@export var icon_max_width: int = 0
## Sonido al apretarlo (nombre de Sfx): ui_click, ui_confirm (Jugar, Continuar),
## ui_back (Volver); vacío = ninguno.
@export var press_sound: StringName = &"ui_click":
	set(value):
		press_sound = value
		if _btn != null:
			_btn.set_meta(&"ui_press_sound", value)

@onready var _cara: Control = $Cara
@onready var _fondo: ColorRect = $Cara/Fondo
@onready var _texto: Button = $Cara/Texto
@onready var _btn: Button = $Btn

var _hover := false
var _focus := false
var _lit := false
var _down := false
var _press := 0.0
var _lit_tween: Tween
var _press_tween: Tween
var _shine_tween: Tween

func _ready() -> void:
	_texto.text = text
	_texto.icon = icon
	if icon_max_width > 0:
		_texto.add_theme_constant_override("icon_max_width", icon_max_width)
		# Con ícono, margen para que no pise el borde dorado.
		var box := StyleBoxEmpty.new()
		box.content_margin_left = ICON_MARGIN
		box.content_margin_right = ICON_MARGIN
		_texto.add_theme_stylebox_override("normal", box)
	_btn.set_meta(&"ui_press_sound", press_sound)
	_btn.pressed.connect(_on_pressed)
	_btn.button_down.connect(func() -> void: _down = true; _animate_press(1.0, 0.05))
	_btn.button_up.connect(func() -> void: _down = false; _animate_press(0.0, 0.14))
	_btn.mouse_entered.connect(func() -> void: _hover = true; _refresh())
	_btn.mouse_exited.connect(func() -> void: _hover = false; _refresh())
	_btn.focus_entered.connect(func() -> void: _focus = true; _refresh())
	_btn.focus_exited.connect(func() -> void: _focus = false; _refresh())
	_fondo.resized.connect(_update_size)
	resized.connect(_update_size)
	_update_size()
	_refresh()
	_fix_hover_after_layout.call_deferred()

## El Button interno (para darle el foco desde otro script).
func button() -> Button:
	return _btn

## Entrada animada (p. ej. los botones del menú, uno tras otro): la cara sube
## desde un poco más abajo y aparece. Solo mueve la Cara: sirve aunque el botón
## esté dentro de un contenedor.
func appear(delay: float = 0.0) -> void:
	_cara.modulate.a = 0.0
	_cara.position.y = 26.0
	var tween := create_tween().set_parallel()
	tween.tween_property(_cara, "modulate:a", 1.0, 0.25).set_delay(delay)
	tween.tween_property(_cara, "position:y", 0.0, 0.45).set_delay(delay) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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

func _on_pressed() -> void:
	# Con teclado (Enter) no hay button_down visible: un golpe corto igual.
	if not _down:
		_press = 1.0
		_apply_press(1.0)
		_animate_press(0.0, 0.16)
	pressed.emit()

## Resaltado con mouse encima o foco de teclado: crece, se aclara, borde dorado
## con halo y (al empezar) un destello que lo cruza.
func _refresh() -> void:
	var lit := _hover or _focus
	if lit == _lit and _lit_tween != null:
		return
	var was_lit := _lit
	_lit = lit
	_cara.pivot_offset = _cara.size * 0.5
	if _lit_tween != null:
		_lit_tween.kill()
	_lit_tween = create_tween().set_parallel()
	_lit_tween.tween_method(_set_param.bind(&"active"), _get_param(&"active"),
		1.0 if lit else 0.0, 0.12)
	_lit_tween.tween_property(_cara, "scale", Vector2.ONE * (LIT_SCALE if lit else 1.0), 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_texto.add_theme_color_override("font_color",
		Color(1, 1, 1) if lit else Color(0.96, 0.93, 0.85))
	if lit and not was_lit:
		_shine()

func _shine() -> void:
	if _shine_tween != null:
		_shine_tween.kill()
	_shine_tween = create_tween()
	_shine_tween.tween_method(_set_param.bind(&"shine"), -0.1, 1.1, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_shine_tween.tween_callback(_set_param.bind(-1.0, &"shine"))

func _animate_press(target: float, seconds: float) -> void:
	if _press_tween != null:
		_press_tween.kill()
	_press_tween = create_tween()
	_press_tween.tween_method(_apply_press, _press, target, seconds) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

## Hundida 0..1: la cara del shader y el texto bajan juntos.
func _apply_press(amount: float) -> void:
	_press = amount
	_set_param(amount, &"press")
	_texto.offset_top = DEPTH * amount
	_texto.offset_bottom = -DEPTH + DEPTH * amount

func _update_size() -> void:
	_set_param(_fondo.size, &"rect_size")
	_cara.pivot_offset = _cara.size * 0.5

func _set_param(value: Variant, param: StringName) -> void:
	var mat := _fondo.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter(param, value)

func _get_param(param: StringName) -> Variant:
	var mat := _fondo.material as ShaderMaterial
	return mat.get_shader_parameter(param) if mat != null else 0.0
