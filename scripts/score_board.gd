extends Node

## Tablero de puntajes y progreso. Cumple tres roles:
## 1) Lleva los datos de la última victoria (nivel, puntaje, si fue récord) entre
##    escenas, porque change_scene_to_file no permite pasar parámetros directos.
## 2) Guarda el HIGHSCORE por nivel de forma persistente en user://scores.cfg
##    (mismo patrón de ConfigFile que settings_manager.gd).
## 3) Guarda qué niveles se completaron (y el máximo de sopaipillas juntadas en
##    cada uno): de eso depende qué niveles están desbloqueados en el mapa
##    (ver LevelCatalog).
## Es un autoload (singleton), accesible globalmente como ScoreBoard.

const SCORES_PATH := "user://scores.cfg"

# Datos de la última victoria, para que la pantalla de victoria y el mapa los lean.
var last_level_id: String = ""
var last_level_name: String = ""
var last_score: int = 0
var last_is_record: bool = false
## true si la última victoria fue la primera vez que se completó ese nivel
## (el mapa anima los niveles que se desbloquearon).
var last_first_clear: bool = false
var last_collected: int = 0
var last_total: int = 0

## Solo para desarrollo: todos los niveles desbloqueados (no se guarda).
var unlock_all: bool = false

# level_id -> mejor puntaje (int). Persistido.
var _highscores: Dictionary = {}
# level_id -> máximo de coleccionables juntados en una victoria (int). Persistido.
# Que la clave exista = el nivel está completado.
var _completed: Dictionary = {}

func _ready() -> void:
	_load()

## Registra un nivel ganado. Marca el nivel como completado, actualiza el
## highscore si el puntaje lo supera y deja los datos listos para la pantalla de
## victoria. Devuelve true si fue récord nuevo.
func report_win(level_id: String, level_name: String, score: int,
		collected: int = 0, total: int = 0) -> bool:
	last_level_id = level_id
	last_level_name = level_name
	last_score = score
	last_collected = collected
	last_total = total
	last_first_clear = not is_completed(level_id)
	last_is_record = score > get_highscore(level_id)
	if last_is_record:
		_highscores[level_id] = score
	_completed[level_id] = maxi(collected, best_collected(level_id))
	_save()
	return last_is_record

## Mejor puntaje guardado para un nivel (0 si nunca se ganó).
func get_highscore(level_id: String) -> int:
	return int(_highscores.get(level_id, 0))

func is_completed(level_id: String) -> bool:
	return _completed.has(level_id)

## Máximo de coleccionables juntados en una victoria del nivel (0 si no se ganó).
func best_collected(level_id: String) -> int:
	return int(_completed.get(level_id, 0))

func completed_count() -> int:
	return _completed.size()

## Borra todo el progreso (récords y niveles completados).
func reset_progress() -> void:
	_highscores.clear()
	_completed.clear()
	_save()

func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SCORES_PATH) != OK:
		return
	if config.has_section("highscores"):
		for key in config.get_section_keys("highscores"):
			_highscores[key] = int(config.get_value("highscores", key, 0))
	if config.has_section("completed"):
		for key in config.get_section_keys("completed"):
			_completed[key] = int(config.get_value("completed", key, 0))
	# Partidas guardadas antes de que existiera "completed": un récord implica
	# que el nivel se ganó.
	for key in _highscores:
		if not _completed.has(key):
			_completed[key] = 0

func _save() -> void:
	var config := ConfigFile.new()
	for key in _highscores:
		config.set_value("highscores", key, _highscores[key])
	for key in _completed:
		config.set_value("completed", key, _completed[key])
	config.save(SCORES_PATH)
