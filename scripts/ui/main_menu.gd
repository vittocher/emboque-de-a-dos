extends Control

## Menú principal: portada de fondo + Jugar (→ selector de niveles) y Ajustes.
## El título y los controles están dibujados en la portada (assets/ui/portada.png).
## Sin botón Salir: el juego es para web, donde quit() no cierra la pestaña.

func _ready() -> void:
	$Center/VBox/PlayButton.pressed.connect(_on_play_pressed)
	$Center/VBox/SettingsButton.pressed.connect(_on_settings_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/level_selector.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")
