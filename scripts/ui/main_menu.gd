extends Control

## Menú principal: portada de fondo + Jugar (→ selector de niveles), Ajustes, Salir.
## El título y los controles están dibujados en la portada (art/portada.png).

func _ready() -> void:
	$Center/VBox/PlayButton.pressed.connect(_on_play_pressed)
	$Center/VBox/SettingsButton.pressed.connect(_on_settings_pressed)
	$Center/VBox/QuitButton.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/level_selector.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
