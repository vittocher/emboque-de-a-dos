extends Node
class_name LevelRules

## Mecánicas que tiene un nivel. Se agrega como nodo en el nivel (Add Child Node →
## LevelRules) y se marcan las casillas en el Inspector. Un nivel SIN este nodo
## tiene todo lo opcional apagado.

## Color que identifica la mecánica de lanzar en los menús (botones del selector
## de niveles y la línea de controles del menú principal).
const THROW_COLOR := Color(0.55, 0.9, 0.35)

## Tomar el emboque en la mano (cuerda al mínimo + tirar otra vez) y lanzarlo
## apuntando (tecla lanzar: G / L).
@export var throw_enabled: bool = false

func _enter_tree() -> void:
	# En _enter_tree (no _ready): así ya está en el grupo cuando cualquier otro
	# nodo del nivel lo busca en su _ready, sin importar el orden del árbol.
	add_to_group("level_rules")

## Las reglas del nivel actual, o null si el nivel no tiene el nodo.
static func of(tree: SceneTree) -> LevelRules:
	return tree.get_first_node_in_group("level_rules") as LevelRules

## True si la escena de un nivel tiene la mecánica de lanzar activada. Sigue
## sola a la casilla del Inspector. El nodo LevelRules tiene que estar directo en
## la escena del nivel.
static func scene_throw_enabled(scene: PackedScene) -> bool:
	return scene_value(scene, &"throw_enabled", false) == true

## Valor guardado de una propiedad en la escena de un nivel (el primer nodo que
## la tenga, p. ej. level_name del WinManager), sin instanciarla. Solo ve lo que
## está guardado directo en esa escena (no dentro de sub-escenas instanciadas);
## si no está guardada (vale su default), devuelve `default`.
static func scene_value(scene: PackedScene, property: StringName, default: Variant) -> Variant:
	if scene == null:
		return default
	var state := scene.get_state()
	for i in state.get_node_count():
		for j in state.get_node_property_count(i):
			if state.get_node_property_name(i, j) == property:
				return state.get_node_property_value(i, j)
	return default
