extends Node

## AUTOLOAD (UiFx). La respuesta de la interfaz, en un solo lugar:
##
## 1. Cada control interactivo que entra al árbol (BaseButton, Slider, PopupMenu)
##    se conecta solo (SceneTree.node_added), en cualquier escena, sin tocarla:
##    - cursor de mano encima;
##    - el mouse le pasa el foco (así brilla uno solo: mouse y teclado van juntos);
##    - sonido al pasar el mouse (ui_hover) o al moverse con flechas/control;
##    - sonido al apretarlo (ui_click; en un toggle, más agudo al prender);
##    - slider: un "tic" que sube de tono con el valor;
##    - lista desplegable (PopupMenu): tic al recorrerla, click al elegir.
##    Lo visual de cada botón (brillo, hundirse) es de su estilo o su escena
##    (tema_madera.tres, boton_madera.tscn, level_node.tscn).
## 2. Cambios de pantalla con fundido: go_to(escena) / reload() (y reveal()).
##
## Ajustes por control, como metadata (en la escena: Inspector → Metadata):
##   ui_fx = false                 no conectarlo
##   ui_press_sound = &"ui_back"   sonido al apretarlo (default ui_click; &"" = ninguno,
##                                 cuando el script ya pone el suyo)
##   ui_slider_sound = false       slider sin "tic" (p. ej. Efectos, que ya suena)

## Separación mínima entre dos sonidos de hover (pasar rápido por una lista).
const HOVER_GAP_MS := 45
## Separación mínima entre dos "tic" de un slider arrastrado.
const SLIDER_GAP_MS := 55
## Al entrar una escena: sin sonidos de hover (el foco inicial y el mouse que ya
## estaba encima de un botón no suenan).
const SCENE_GRACE_MS := 300
## Acciones que mueven el foco (el foco que cambie por ellas suena).
const NAV_ACTIONS: Array[StringName] = [&"ui_up", &"ui_down", &"ui_left", &"ui_right",
	&"ui_focus_next", &"ui_focus_prev"]
## Fundido entre pantallas (s) y su color (el azul de fondo de los menús).
const FADE_OUT := 0.2
const FADE_IN := 0.3
const FADE_COLOR := Color(0.039, 0.059, 0.149)

var _last_hover_ms := -100000
var _last_slider_ms := -100000
var _scene_start_ms := -100000
var _nav_frame := -10
var _busy := false
var _fade: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	var layer := CanvasLayer.new()
	layer.layer = 128  # encima de todo (HUD, pausa, confetti)
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(FADE_COLOR, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)

func _input(event: InputEvent) -> void:
	for action in NAV_ACTIONS:
		if event.is_action_pressed(action, true):
			_nav_frame = Engine.get_process_frames()
			return

# --- Conexión automática ---------------------------------------------------------

func _on_node_added(node: Node) -> void:
	if node.get_parent() == get_tree().root:
		_scene_start_ms = Time.get_ticks_msec()
	if node.get_meta(&"ui_fx", true) == false:
		return
	if node is BaseButton:
		_wire_button(node)
	elif node is Slider:
		_wire_slider(node)
	elif node is PopupMenu:
		_wire_popup(node)

func _wire_button(button: BaseButton) -> void:
	_hand_cursor(button)
	button.mouse_entered.connect(_on_mouse_entered.bind(button))
	button.focus_entered.connect(_on_focus_entered)
	button.pressed.connect(_on_pressed.bind(button))

func _wire_slider(slider: Slider) -> void:
	_hand_cursor(slider)
	slider.mouse_entered.connect(_on_mouse_entered.bind(slider))
	slider.focus_entered.connect(_on_focus_entered)
	slider.value_changed.connect(_on_slider_changed.bind(slider))

func _wire_popup(popup: PopupMenu) -> void:
	popup.id_focused.connect(func(_id: int) -> void: hover_sound())
	popup.index_pressed.connect(func(_index: int) -> void: Sfx.play(&"ui_click"))

func _hand_cursor(control: Control) -> void:
	if control.mouse_default_cursor_shape == Control.CURSOR_ARROW:
		control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _on_mouse_entered(control: Control) -> void:
	var button := control as BaseButton
	if button != null and button.disabled:
		return
	hover_sound()
	if control.focus_mode != Control.FOCUS_NONE and control.is_visible_in_tree():
		control.grab_focus()

## El foco suena solo si lo movió el teclado/control en este cuadro (no el
## código al abrir una pantalla, ni el mouse, que ya sonó al entrar).
func _on_focus_entered() -> void:
	if Engine.get_process_frames() - _nav_frame <= 1:
		hover_sound()

func _on_pressed(button: BaseButton) -> void:
	var sound: StringName = button.get_meta(&"ui_press_sound", &"ui_click")
	# Un clic que mueve el foco (p. ej. volver de un submenú) no suena dos veces.
	_last_hover_ms = Time.get_ticks_msec()
	if sound == &"":
		return
	var pitch := 1.0
	if button.toggle_mode:
		pitch = 1.12 if button.button_pressed else 0.88
	Sfx.play(sound, pitch)

func _on_slider_changed(value: float, slider: Slider) -> void:
	if slider.get_meta(&"ui_slider_sound", true) == false:
		return
	var now := Time.get_ticks_msec()
	if now - _last_slider_ms < SLIDER_GAP_MS:
		return
	_last_slider_ms = now
	var ratio := 0.5
	if slider.max_value > slider.min_value:
		ratio = inverse_lerp(slider.min_value, slider.max_value, value)
	Sfx.play(&"ui_tick", lerpf(0.75, 1.5, ratio))

# --- Sonidos para los scripts de la interfaz ------------------------------------

## "Tic" de pasar por encima (con un poco de variación para que no canse).
func hover_sound(pitch: float = 1.0) -> void:
	var now := Time.get_ticks_msec()
	if now - _scene_start_ms < SCENE_GRACE_MS or now - _last_hover_ms < HOVER_GAP_MS:
		return
	_last_hover_ms = now
	Sfx.play(&"ui_hover", pitch * randf_range(0.96, 1.04))

# --- Transiciones ----------------------------------------------------------------

## Cambia a otra pantalla con un fundido. Mientras dura no se puede hacer clic, y
## un segundo cambio pedido en ese rato se ignora (doble clic, Enter repetido).
func go_to(scene_path: String) -> void:
	transition(func() -> void: get_tree().change_scene_to_file(scene_path))

## Reinicia la escena actual con fundido (Reiniciar de la pausa).
func reload() -> void:
	transition(func() -> void: get_tree().reload_current_scene())

## Funde a negro (azul), ejecuta `change` y vuelve a mostrar. Despausa el árbol
## antes del cambio (desde la pausa).
func transition(change: Callable) -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var out := _fade_tween()
	out.tween_property(_fade, "color:a", 1.0, FADE_OUT).set_trans(Tween.TRANS_SINE)
	await out.finished
	get_tree().paused = false
	change.call()
	# change_scene es diferido: la escena nueva entra al final de este cuadro, y
	# el layout de sus contenedores en el siguiente.
	await get_tree().process_frame
	await get_tree().process_frame
	await _reveal(FADE_IN)
	_busy = false

## La pantalla aparece desde el azul (para escenas a las que se llega sin
## go_to, como la victoria, que la abre el WinManager).
func reveal(seconds: float = FADE_IN) -> void:
	if _busy:
		return
	_fade.color.a = 1.0
	_reveal(seconds)

func is_transitioning() -> bool:
	return _busy

func _reveal(seconds: float) -> void:
	var back := _fade_tween()
	back.tween_property(_fade, "color:a", 0.0, seconds).set_trans(Tween.TRANS_SINE)
	await back.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

## Tween de tiempo real: sin importar la cámara lenta del closeup ni la pausa.
func _fade_tween() -> Tween:
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	return tween
