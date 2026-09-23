extends Control

## Menú principal: Jugar (→ selector de niveles), Ajustes, y los controles.

func _ready() -> void:
	$Center/VBox/PlayButton.pressed.connect(_on_play_pressed)
	$Center/VBox/SettingsButton.pressed.connect(_on_settings_pressed)
	# La línea de lanzar va del mismo color que los niveles que lo tienen en el selector.
	$Center/VBox/ThrowControls.add_theme_color_override(&"font_color", LevelRules.THROW_COLOR)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/level_selector.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")
