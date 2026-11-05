extends RefCounted
class_name LevelCatalog

## Catálogo de niveles del juego: qué escena es cada nivel, su nombre, dónde va en
## el mapa y de qué niveles depende. Es la ÚNICA lista de niveles: el mapa, el
## WinManager (id y nombre al ganar) y la pantalla de victoria la leen de acá.
##
## Desbloqueo (como en el concepto): un nivel se desbloquea al completar
## CUALQUIERA de los niveles de su "from" (o al menos "need" de ellos, si la
## entrada lo trae). El primer nivel no tiene "from": siempre está abierto.
##
## Opcionales: "special": true (nodo más grande y dorado), "rope": false (sin cuerdas en el mapa, p. ej. el final, que depende
## de niveles lejanos) y "hint" (texto del mapa mientras está bloqueado).
##
## Para agregar un nivel: crear la escena (heredando scenes/levels/level_base.tscn)
## y agregar una entrada acá. "pos" es su lugar en el mapa (1280×720).

const LEVELS: Array[Dictionary] = [
	# --- Tronco: lo básico (moverse, la cuerda, los ganchos) ---
	{"id": "tronco_1", "scene": "res://scenes/levels/tronco_1.tscn", "name": "Primer emboque",
		"pos": Vector2(640, 606), "from": []},
	{"id": "tronco_2", "scene": "res://scenes/levels/tronco_2.tscn", "name": "Cuerda larga",
		"pos": Vector2(640, 531), "from": ["tronco_1"]},
	{"id": "tronco_3", "scene": "res://scenes/levels/tronco_3.tscn", "name": "Colgados",
		"pos": Vector2(640, 456), "from": ["tronco_2"]},
	{"id": "tronco_4", "scene": "res://scenes/levels/tronco_4.tscn", "name": "El cuenco",
		"pos": Vector2(640, 376), "from": ["tronco_3"]},
	# --- Rama: peligros (púas, caca, fuego) ---
	{"id": "peligro_1", "scene": "res://scenes/levels/peligro_1.tscn", "name": "Púas",
		"pos": Vector2(560, 324), "from": ["tronco_4"]},
	{"id": "peligro_2", "scene": "res://scenes/levels/peligro_2.tscn", "name": "Cuidado abajo",
		"pos": Vector2(478, 274), "from": ["peligro_1"]},
	{"id": "peligro_3", "scene": "res://scenes/levels/peligro_3.tscn", "name": "Brasas",
		"pos": Vector2(396, 226), "from": ["peligro_2"]},
	{"id": "level_2", "scene": "res://scenes/level_2.tscn", "name": "La T",
		"pos": Vector2(314, 180), "from": ["peligro_3"]},
	# --- Rama: cajas ---
	{"id": "caja_1", "scene": "res://scenes/levels/caja_1.tscn", "name": "Una caja",
		"pos": Vector2(550, 408), "from": ["tronco_4"]},
	{"id": "caja_2", "scene": "res://scenes/levels/caja_2.tscn", "name": "Escalera",
		"pos": Vector2(458, 434), "from": ["caja_1"]},
	{"id": "caja_3", "scene": "res://scenes/levels/caja_3.tscn", "name": "Encomienda",
		"pos": Vector2(366, 460), "from": ["caja_2"]},
	{"id": "level_4", "scene": "res://scenes/level_4.tscn", "name": "Escalones",
		"pos": Vector2(274, 486), "from": ["caja_3"]},
	# --- Rama: lanzar ---
	{"id": "lanzar_1", "scene": "res://scenes/levels/lanzar_1.tscn", "name": "Al aire",
		"pos": Vector2(722, 324), "from": ["tronco_4"]},
	{"id": "lanzar_2", "scene": "res://scenes/levels/lanzar_2.tscn", "name": "Puntería",
		"pos": Vector2(804, 274), "from": ["lanzar_1"]},
	{"id": "lanzar_3", "scene": "res://scenes/levels/lanzar_3.tscn", "name": "Lazo",
		"pos": Vector2(886, 226), "from": ["lanzar_2"]},
	# --- Rama: placas y compuertas (sale de las cajas) ---
	{"id": "placa_1", "scene": "res://scenes/levels/placa_1.tscn", "name": "La placa",
		"pos": Vector2(424, 520), "from": ["caja_2"]},
	{"id": "placa_2", "scene": "res://scenes/levels/placa_2.tscn", "name": "Peso muerto",
		"pos": Vector2(336, 558), "from": ["placa_1"]},
	{"id": "placa_3", "scene": "res://scenes/levels/placa_3.tscn", "name": "Turnos",
		"pos": Vector2(246, 580), "from": ["placa_2"]},
	# --- Rama: plataformas que se mueven (sale de los peligros) ---
	{"id": "movil_1", "scene": "res://scenes/levels/movil_1.tscn", "name": "Ascensor",
		"pos": Vector2(500, 188), "from": ["peligro_2"]},
	{"id": "movil_2", "scene": "res://scenes/levels/movil_2.tscn", "name": "Vaivén",
		"pos": Vector2(530, 108), "from": ["movil_1"]},
	{"id": "movil_3", "scene": "res://scenes/levels/movil_3.tscn", "name": "Andén",
		"pos": Vector2(450, 66), "from": ["movil_2"]},
	# --- Rama: viento (sale de lanzar) ---
	{"id": "viento_1", "scene": "res://scenes/levels/viento_1.tscn", "name": "Volantín",
		"pos": Vector2(888, 336), "from": ["lanzar_2"]},
	{"id": "viento_2", "scene": "res://scenes/levels/viento_2.tscn", "name": "Ventolera",
		"pos": Vector2(976, 374), "from": ["viento_1"]},
	{"id": "viento_3", "scene": "res://scenes/levels/viento_3.tscn", "name": "Remolino",
		"pos": Vector2(1064, 406), "from": ["viento_2"]},
	# --- Final: se abre con 4 de los 6 finales de rama ---
	{"id": "final", "scene": "res://scenes/levels/final.tscn", "name": "Emboque de a dos",
		"pos": Vector2(700, 112), "need": 4, "special": true, "rope": false,
		"hint": "Completa 4 caminos para abrirlo",
		"from": ["level_2", "level_4", "lanzar_3", "placa_3", "movil_3", "viento_3"]},
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

## Abierto si se completaron los niveles de los que depende (no basta con haberlo
## completado: así una partida vieja o un cambio del árbol no deja niveles
## abiertos fuera de orden).
static func is_unlocked(id: String) -> bool:
	if ScoreBoard.unlock_all:
		return true
	return _requirements_met(id, "")

## True si [param id] estaría desbloqueado aunque [param excluded] no estuviera
## completado (el mapa lo usa para saber qué desbloqueó la última victoria).
static func was_unlocked_without(id: String, excluded: String) -> bool:
	return _requirements_met(id, excluded)

static func _requirements_met(id: String, excluded: String) -> bool:
	var level := get_level(id)
	if level.is_empty():
		return false
	var from: Array = level.get("from", [])
	if from.is_empty():
		return true
	var done := from.filter(func(f: String) -> bool:
		return f != excluded and ScoreBoard.is_completed(f)).size()
	return done >= int(level.get("need", 1))

## Niveles que dependen de [param id] (las conexiones que salen de él en el mapa).
static func next_of(id: String) -> Array[String]:
	var result: Array[String] = []
	for level in LEVELS:
		if id in level.get("from", []):
			result.append(level.id)
	return result

## Total de coleccionables de un nivel, contados en su escena sin instanciarla.
## Carga la escena entera (lento): el mapa usa ScoreBoard.collectible_total.
static func collectible_count(scene_path: String) -> int:
	if not ResourceLoader.exists(scene_path):
		return 0
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
