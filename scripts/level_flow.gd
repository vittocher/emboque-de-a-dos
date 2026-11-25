extends RefCounted
class_name LevelFlow

## Estado del nivel en curso, guardado en la escena actual (así se borra solo al
## recargar o cambiar de nivel):
## - ganado: desde que se emboca hasta la pantalla de victoria ya no se muere
##   ni se juntan más coleccionables (el resultado ya quedó anotado);
## - reiniciándose: varias zonas de muerte tocadas a la vez recargan una sola vez.

const WON := &"level_won"
const RESTARTING := &"level_restarting"

static func is_won(tree: SceneTree) -> bool:
	return tree.current_scene != null and tree.current_scene.has_meta(WON)

static func mark_won(tree: SceneTree) -> void:
	if tree.current_scene != null:
		tree.current_scene.set_meta(WON, true)

## Tamaño del mundo del nivel (px): 1280×720, o más en los niveles con la cámara
## alejada (level_base_large). Sale del CloseupManager del nivel.
static func level_size(tree: SceneTree) -> Vector2:
	var closeup := tree.get_first_node_in_group(&"closeup_manager")
	if closeup != null and "level_size" in closeup:
		return closeup.level_size
	return Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 720)))

## True si el nivel ya terminó (ganado o reiniciándose): no hay más muertes.
static func is_over(tree: SceneTree) -> bool:
	var scene := tree.current_scene
	return scene != null and (scene.has_meta(WON) or scene.has_meta(RESTARTING))

## Reinicia el nivel (diferido: puede venir de un callback de física, donde
## Godot prohíbe liberar cuerpos). Una sola vez aunque lo pidan varias zonas.
static func restart(tree: SceneTree) -> void:
	var scene := tree.current_scene
	if scene == null or scene.has_meta(RESTARTING):
		return
	scene.set_meta(RESTARTING, true)
	tree.call_deferred(&"reload_current_scene")
