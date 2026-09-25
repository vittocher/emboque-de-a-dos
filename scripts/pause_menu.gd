extends CanvasLayer

## Menú de pausa (acción "pause": Esc o P; en web con pantalla completa el
## navegador se queda con Esc para salir de ella, por eso existe P). Único para
## todos los niveles: se instancia desde ui/pause_menu.tscn. El diseño es una
## imagen (assets/ui/pause_menu.webp) y los botones son áreas invisibles encima
## de los botones pintados; el brillo dorado lo dibuja el botón con foco (o bajo
## el mouse).

@onready var pause_panel: Control = $PausePanel
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

var _is_paused := false
var _settings: Node

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
	# El mouse mueve el foco: así brilla un solo botón a la vez.
	for button: Button in [continue_button, restart_button, settings_button, main_menu_button]:
		button.mouse_entered.connect(button.grab_focus)
	pause_panel.visible = false
	_show_pause_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	_set_paused(not _is_paused)

func _set_paused(paused: bool) -> void:
	_is_paused = paused
	pause_panel.visible = paused
	get_tree().paused = paused
	if paused:
		_show_pause_menu()
		continue_button.grab_focus()

func _continue_game() -> void:
	_set_paused(false)

func _restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _show_pause_menu() -> void:
	buttons.visible = true
	settings_box.visible = false

func _back_from_settings() -> void:
	_show_pause_menu()
	settings_button.grab_focus()

func _show_settings() -> void:
	buttons.visible = false
	settings_box.visible = true
	settings_master_volume.value = _settings.master_volume
	settings_music_volume.value = _settings.music_volume
	settings_sfx_volume.value = _settings.sfx_volume
	settings_fullscreen.button_pressed = _settings.fullscreen
	settings_back_button.grab_focus()

func _on_master_volume_changed(value: float) -> void:
	_settings.set_master_volume(value)

func _on_music_volume_changed(value: float) -> void:
	_settings.set_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	_settings.set_sfx_volume(value)

func _on_fullscreen_toggled(enabled: bool) -> void:
	_settings.set_fullscreen(enabled)

func _go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
