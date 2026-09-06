extends Control

## Menú principal: Jugar (→ selector de niveles), Ajustes, y los controles.

func _ready() -> void:
	$Center/VBox/PlayButton.pressed.connect(_on_play_pressed)
	$Center/VBox/SettingsButton.pressed.connect(_on_settings_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/level_selector.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")
