extends SceneTree
## Graba el mapa de niveles para el tráiler (con --write-movie): progreso de
## ejemplo, la animación de lo recién desbloqueado y un paseo con las flechas.
## Uso: godot --path . --write-movie mapa.avi --fixed-fps 30 -s tests/rec_map.gd -- [es|en]
## (no toca el progreso guardado: el ScoreBoard se cambia solo en memoria).

const DONE := ["tronco_1", "tronco_2", "tronco_3", "tronco_4", "peligro_1", "peligro_2", "peligro_3",
	"level_2", "caja_1", "caja_2", "lanzar_1", "lanzar_2", "viento_1", "movil_1"]

func _initialize() -> void:
	_run.call_deferred()

func _key(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := ev.duplicate()
	up.pressed = false
	Input.parse_input_event(up)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var sm := root.get_node("SettingsManager")
	sm.set_language(args[0] if args.size() > 0 else "es")
	sm.set_music_volume(0.0)
	var sb := root.get_node("ScoreBoard")
	sb._completed.clear()
	sb._highscores.clear()
	for id: String in DONE:
		sb._completed[id] = 3
		sb._highscores[id] = 300
		sb._totals[id] = 3
	sb.last_level_id = "caja_2"
	sb.last_first_clear = true
	change_scene_to_file("res://scenes/ui/level_selector.tscn")
	await create_timer(2.4).timeout
	for a in ["ui_up", "ui_up", "ui_left", "ui_up", "ui_right", "ui_right", "ui_right"]:
		_key(a)
		await create_timer(0.55).timeout
	await create_timer(0.6).timeout
	quit()
