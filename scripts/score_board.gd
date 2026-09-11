extends Node

## Tablero de puntajes. Cumple dos roles:
## 1) Lleva los datos de la última victoria (nivel, puntaje, si fue récord) entre
##    escenas, porque change_scene_to_file no permite pasar parámetros directos.
## 2) Guarda el HIGHSCORE por nivel de forma persistente en user://scores.cfg
##    (mismo patrón de ConfigFile que settings_manager.gd).
## Es un autoload (singleton), accesible globalmente como ScoreBoard.

const SCORES_PATH := "user://scores.cfg"

# Datos de la última victoria, para que la pantalla de victoria los lea.
var last_level_id: String = ""
var last_level_name: String = ""
var last_score: int = 0
var last_is_record: bool = false

# level_id -> mejor puntaje (int). Persistido.
var _highscores: Dictionary = {}

func _ready() -> void:
	_load()

## Registra un nivel ganado. Actualiza el highscore si el puntaje lo supera y deja
## los datos listos para la pantalla de victoria. Devuelve true si fue récord nuevo.
func report_win(level_id: String, level_name: String, score: int) -> bool:
	last_level_id = level_id
	last_level_name = level_name
	last_score = score
	last_is_record = score > get_highscore(level_id)
	if last_is_record:
		_highscores[level_id] = score
		_save()
	return last_is_record

## Mejor puntaje guardado para un nivel (0 si nunca se ganó).
func get_highscore(level_id: String) -> int:
	return int(_highscores.get(level_id, 0))

func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SCORES_PATH) != OK:
		return
	if not config.has_section("highscores"):
		return
	for key in config.get_section_keys("highscores"):
		_highscores[key] = int(config.get_value("highscores", key, 0))

func _save() -> void:
	var config := ConfigFile.new()
	for key in _highscores:
		config.set_value("highscores", key, _highscores[key])
	config.save(SCORES_PATH)
