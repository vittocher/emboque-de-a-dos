extends Control

## Ajustes básicos: volumen maestro y pantalla completa (se aplican en vivo y
## son globales, así que persisten al cambiar de escena). Guardado a disco:
## pendiente (usar un ConfigFile cuando haya más opciones).

@onready var _volume: HSlider = $Center/VBox/VolumeRow/VolumeSlider
@onready var _fullscreen: CheckButton = $Center/VBox/FullscreenRow/FullscreenCheck

func _ready() -> void:
	var master := AudioServer.get_bus_index("Master")
	_volume.value = db_to_linear(AudioServer.get_bus_volume_db(master))
	_volume.value_changed.connect(_on_volume_changed)

	_fullscreen.button_pressed = (
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	_fullscreen.toggled.connect(_on_fullscreen_toggled)

	$Center/VBox/BackButton.pressed.connect(_on_back_pressed)

func _on_volume_changed(value: float) -> void:
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master, linear_to_db(maxf(value, 0.0001)))

func _on_fullscreen_toggled(pressed: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED
	)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
