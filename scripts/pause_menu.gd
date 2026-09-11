extends CanvasLayer

@onready var pause_panel: Control = $PausePanel
@onready var continue_button: Button = $PausePanel/Panel/VBox/ContinueButton
@onready var restart_button: Button = $PausePanel/Panel/VBox/RestartButton
@onready var settings_button: Button = $PausePanel/Panel/VBox/SettingsButton
@onready var main_menu_button: Button = $PausePanel/Panel/VBox/MainMenuButton
@onready var settings_box: VBoxContainer = $PausePanel/Panel/SettingsVBox
@onready var settings_volume: HSlider = $PausePanel/Panel/SettingsVBox/VolumeRow/VolumeSlider
@onready var settings_fullscreen: CheckBox = $PausePanel/Panel/SettingsVBox/FullscreenRow/FullscreenCheck
@onready var settings_back_button: Button = $PausePanel/Panel/SettingsVBox/BackButton

var _is_paused := false
var _settings: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_settings = get_node("/root/SettingsManager")
	continue_button.pressed.connect(_continue_game)
	restart_button.pressed.connect(_restart_level)
	settings_button.pressed.connect(_show_settings)
	main_menu_button.pressed.connect(_go_to_main_menu)
	settings_back_button.pressed.connect(_show_pause_menu)
	settings_volume.value_changed.connect(_on_volume_changed)
	settings_fullscreen.toggled.connect(_on_fullscreen_toggled)
	pause_panel.visible = false
	_show_pause_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
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
	$PausePanel/Panel/VBox.visible = true
	settings_box.visible = false

func _show_settings() -> void:
	$PausePanel/Panel/VBox.visible = false
	settings_box.visible = true
	settings_volume.value = _settings.master_volume
	settings_fullscreen.button_pressed = _settings.fullscreen
	settings_back_button.grab_focus()

func _on_volume_changed(value: float) -> void:
	_settings.set_master_volume(value)

func _on_fullscreen_toggled(enabled: bool) -> void:
	_settings.set_fullscreen(enabled)

func _go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")