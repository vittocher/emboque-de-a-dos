extends RefCounted
class_name LevelCatalog

## Catálogo de niveles del juego: qué escena es cada nivel, su nombre, dónde va en
## el mapa y de qué niveles depende. Es la ÚNICA lista de niveles: el mapa, el
## WinManager (id y nombre al ganar) y la pantalla de victoria la leen de acá.
##
## Desbloqueo (como en el concepto): un nivel se desbloquea al completar
## CUALQUIERA de los niveles de su "from" (o TODOS, si "all" es true). El primer
## nivel no tiene "from": siempre está abierto.
##
## Para agregar un nivel: crear la escena (heredando scenes/levels/level_base.tscn)
## y agregar una entrada acá. "pos" es su lugar en el mapa (1280×720).

const LEVELS: Array[Dictionary] = [
	# --- Tronco: lo básico (moverse, la cuerda, los ganchos) ---
	{"id": "tronco_1", "scene": "res://scenes/levels/tronco_1.tscn", "name": "Primer emboque",
		"pos": Vector2(640, 660), "from": []},
]

## Entrada del nivel con ese id (diccionario vacío si no existe).
static func get_level(id: String) -> Dictionary:
	for level in LEVELS:
		if level.id == id:
			return level
	return {}

## Entrada del nivel cuya escena es [param scene_path] (vacío si no está en el catálogo).
static func find_by_scene(scene_path: String) -> Dictionary:
	for level in LEVELS:
		if level.scene == scene_path:
			return level
	return {}

## Número del nivel (1, 2, 3…) según su orden en el catálogo.
static func number_of(id: String) -> int:
	for i in LEVELS.size():
		if LEVELS[i].id == id:
			return i + 1
	return 0

static func is_unlocked(id: String) -> bool:
	if ScoreBoard.unlock_all or ScoreBoard.is_completed(id):
		return true
	var level := get_level(id)
	if level.is_empty():
		return false
	var from: Array = level.get("from", [])
	if from.is_empty():
		return true
	if level.get("all", false):
		return from.all(func(f: String) -> bool: return ScoreBoard.is_completed(f))
	return from.any(func(f: String) -> bool: return ScoreBoard.is_completed(f))

## Niveles que dependen de [param id] (las conexiones que salen de él en el mapa).
static func next_of(id: String) -> Array[String]:
	var result: Array[String] = []
	for level in LEVELS:
		if id in level.get("from", []):
			result.append(level.id)
	return result

## Total de coleccionables de un nivel, contados en su escena sin instanciarla.
static func collectible_count(scene_path: String) -> int:
	var scene := load(scene_path) as PackedScene
	if scene == null:
		return 0
	return _count_collectibles(scene.get_state())

static func _count_collectibles(state: SceneState) -> int:
	var count := 0
	for i in state.get_node_count():
		var inst := state.get_node_instance(i)
		if inst != null and inst.resource_path == "res://scenes/collectible.tscn":
			count += 1
	# Escena heredada (p. ej. de level_base): sumar lo que traiga la base.
	var base := state.get_base_scene_state()
	if base != null:
		count += _count_collectibles(base)
	return count
