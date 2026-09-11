extends Control

## Ajustes globales que se aplican en vivo y se guardan en user://settings.cfg.

@onready var _volume: HSlider = $Center/VBox/VolumeRow/VolumeSlider
@onready var _fullscreen: CheckBox = $Center/VBox/FullscreenRow/FullscreenCheck
@onready var _reset_button: Button = $Center/VBox/ResetButton

var _settings: Node

func _ready() -> void:
	_settings = get_node("/root/SettingsManager")
	_volume.value = _settings.master_volume
	_volume.value_changed.connect(_on_volume_changed)

	_fullscreen.button_pressed = _settings.fullscreen
	_fullscreen.toggled.connect(_on_fullscreen_toggled)
	_reset_button.pressed.connect(_on_reset_pressed)

	$Center/VBox/BackButton.pressed.connect(_on_back_pressed)

func _on_volume_changed(value: float) -> void:
	_settings.set_master_volume(value)

func _on_fullscreen_toggled(pressed: bool) -> void:
	_settings.set_fullscreen(pressed)

func _on_reset_pressed() -> void:
	_settings.reset_to_defaults()
	_volume.value = _settings.master_volume
	_fullscreen.button_pressed = _settings.fullscreen

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
