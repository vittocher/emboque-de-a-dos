extends CanvasLayer

## Menú de pausa (acción "pause": Esc o P; en web con pantalla completa el
## navegador se queda con Esc para salir de ella, por eso existe P). Único para
## todos los niveles: se instancia desde ui/pause_menu.tscn. El diseño es una
## imagen (assets/ui/pause_menu.webp) y los botones son áreas invisibles encima
## de los botones pintados; el brillo dorado (borde que respira + luz cálida
## encima del botón pintado) lo dibuja el botón con foco, y el mouse le pasa el
## foco. Al abrir, el tablero entra deslizándose y suena ui_open; al cerrar, lo
## mismo más grave. Sonido de cada botón, cursor de mano: autoload UiFx.

@onready var pause_panel: Control = $PausePanel
## Indicador "P · Pausa" de la esquina superior izquierda (ui/hud_pause.tscn):
## visible mientras se juega; un clic en él también pausa.
@onready var hud_pause: Control = $HudPause
@onready var board: Control = $PausePanel/Board
@onready var buttons: Control = $PausePanel/Board/Buttons
@onready var continue_button: Button = $PausePanel/Board/Buttons/ContinueButton
@onready var restart_button: Button = $PausePanel/Board/Buttons/RestartButton
@onready var settings_button: Button = $PausePanel/Board/Buttons/SettingsButton
@onready var main_menu_button: Button = $PausePanel/Board/Buttons/MainMenuButton
@onready var settings_box: Control = $PausePanel/SettingsPanel
@onready var settings_master_volume: HSlider = $PausePanel/SettingsPanel/SettingsVBox/VolumeRow/VolumeSlider
@onready var settings_music_volume: HSlider = $PausePanel/SettingsPanel/SettingsVBox/MusicVolumeRow/MusicVolumeSlider
@onready var settings_sfx_volume: HSlider = $PausePanel/SettingsPanel/SettingsVBox/SfxVolumeRow/SfxVolumeSlider
@onready var settings_fullscreen: CheckBox = $PausePanel/SettingsPanel/SettingsVBox/FullscreenRow/FullscreenCheck
@onready var settings_back_button: Button = $PausePanel/SettingsPanel/SettingsVBox/BackButton
## Muestra el idioma actual (su texto es la clave LANGUAGE_NAME); cada clic pasa
## al siguiente y todo el nivel se traduce al tiro.
@onready var settings_language: Button = $PausePanel/SettingsPanel/SettingsVBox/LanguageRow/LanguageButton

var _is_paused := false
var _settings: Node
var _board_y := 0.0
var _menu_buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_settings = get_node("/root/SettingsManager")
	continue_button.pressed.connect(_continue_game)
	restart_button.pressed.connect(_restart_level)
	settings_button.pressed.connect(_show_settings)
	main_menu_button.pressed.connect(_go_to_main_menu)
	settings_back_button.pressed.connect(_back_from_settings)
	settings_master_volume.value_changed.connect(_on_master_volume_changed)
	settings_music_volume.value_changed.connect(_on_music_volume_changed)
	settings_sfx_volume.value_changed.connect(_on_sfx_volume_changed)
	settings_fullscreen.toggled.connect(_on_fullscreen_toggled)
	settings_language.pressed.connect(_settings.cycle_language)
	settings_language.add_theme_constant_override("icon_max_width", 33)
	_show_language_flag()
	hud_pause.pressed.connect(_set_paused.bind(true))
	# El mouse mueve el foco: así brilla un solo botón a la vez.
	_menu_buttons = [continue_button, restart_button, settings_button, main_menu_button]
	for button: Button in _menu_buttons:
		button.mouse_entered.connect(button.grab_focus)
	_board_y = board.position.y
	pause_panel.visible = false
	_show_pause_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if not UiFx.is_transitioning():
			_toggle_pause()

## El borde dorado del botón con foco respira (en tiempo real: corre en la pausa).
func _process(_delta: float) -> void:
	if not _is_paused or not buttons.visible:
		return
	var focused := get_viewport().gui_get_focus_owner()
	var breath := 0.78 + 0.22 * sin(Time.get_ticks_msec() * 0.006)
	for button: Button in _menu_buttons:
		button.self_modulate.a = breath if button == focused else 1.0

func _toggle_pause() -> void:
	_set_paused(not _is_paused)

func _set_paused(paused: bool) -> void:
	if paused == _is_paused:
		return
	_is_paused = paused
	pause_panel.visible = paused
	hud_pause.visible = not paused
	get_tree().paused = paused
	Sfx.play(&"ui_open", 1.0 if paused else 0.8)
	if paused:
		_show_pause_menu()
		continue_button.grab_focus()
		_animate_open()

## Entrada del menú: el fondo aparece y el tablero baja un poco con rebote.
func _animate_open() -> void:
	pause_panel.modulate.a = 0.0
	board.position.y = _board_y - 36.0
	var tween := _ui_tween().set_parallel()
	tween.tween_property(pause_panel, "modulate:a", 1.0, 0.14)
	tween.tween_property(board, "position:y", _board_y, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Tween de la interfaz: corre en la pausa (este nodo es ALWAYS) y a velocidad
## real aunque el closeup tenga la cámara lenta.
func _ui_tween() -> Tween:
	return create_tween().set_ignore_time_scale(true)

func _continue_game() -> void:
	_set_paused(false)

func _restart_level() -> void:
	UiFx.reload()

func _show_pause_menu() -> void:
	buttons.visible = true
	settings_box.visible = false

func _back_from_settings() -> void:
	_show_pause_menu()
	settings_button.grab_focus()
	buttons.modulate.a = 0.0
	_ui_tween().tween_property(buttons, "modulate:a", 1.0, 0.15)

func _show_settings() -> void:
	buttons.visible = false
	settings_box.visible = true
	# Sin señal: mostrar los valores no debe volver a guardarlos ni sonar.
	settings_master_volume.set_value_no_signal(_settings.master_volume)
	settings_music_volume.set_value_no_signal(_settings.music_volume)
	settings_sfx_volume.set_value_no_signal(_settings.sfx_volume)
	settings_fullscreen.set_pressed_no_signal(_settings.fullscreen)
	settings_back_button.grab_focus()
	# El panel aparece con un pequeño rebote desde su centro.
	settings_box.pivot_offset = settings_box.size * 0.5
	settings_box.scale = Vector2.ONE * 0.9
	settings_box.modulate.a = 0.0
	var tween := _ui_tween().set_parallel()
	tween.tween_property(settings_box, "modulate:a", 1.0, 0.12)
	tween.tween_property(settings_box, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_master_volume_changed(value: float) -> void:
	_settings.set_master_volume(value)

func _on_music_volume_changed(value: float) -> void:
	_settings.set_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	_settings.set_sfx_volume(value)
	Sfx.preview()

func _on_fullscreen_toggled(enabled: bool) -> void:
	_settings.set_fullscreen(enabled)

func _go_to_main_menu() -> void:
	UiFx.go_to("res://scenes/ui/main_menu.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_show_language_flag()

## Bandera del idioma actual al lado de su nombre en el botón de idioma.
func _show_language_flag() -> void:
	settings_language.icon = Languages.flag_of(Languages.current())
