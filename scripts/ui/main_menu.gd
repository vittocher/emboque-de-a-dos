extends Control

## Menú principal: portada de fondo + Jugar (→ selector de niveles) y Ajustes, y
## arriba a la derecha el botón de idioma (muestra el idioma actual; cada clic
## pasa al siguiente). El título y los controles están dibujados en la portada
## (assets/ui/portada.png; la versión de cada idioma en assets/ui/<código>/).
## Sin botón Salir: el juego es para web, donde quit() no cierra la pestaña.

func _ready() -> void:
	$Center/VBox/PlayButton.pressed.connect(_on_play_pressed)
	$Center/VBox/SettingsButton.pressed.connect(_on_settings_pressed)
	$LanguageButton.pressed.connect(SettingsManager.cycle_language)
	_fade_in_after_intro()

## Al venir de la intro (que se funde a negro), el menú aparece desde negro.
func _fade_in_after_intro() -> void:
	if not IntroScreen.fade_menu_in:
		return
	IntroScreen.fade_menu_in = false
	var overlay := ColorRect.new()
	overlay.color = Color.BLACK
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 0.0, 0.6)
	tween.tween_callback(overlay.queue_free)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/level_selector.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")
