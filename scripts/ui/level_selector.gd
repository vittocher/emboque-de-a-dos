extends Control

## Mapa de niveles (como la progresión del concepto): los niveles de
## LevelCatalog unidos con cuerdas. Un nivel se desbloquea al completar el
## anterior; desde el nivel 4 el camino se abre en ramas. Minimalista: el mapa no
## dice de qué trata cada rama, se descubre jugando.
## Mouse o flechas + Enter para elegir; Esc / Volver vuelve al menú.
## En builds de desarrollo, F9 desbloquea todo (ScoreBoard.unlock_all).

const NODE_SCENE := preload("res://scenes/ui/level_node.tscn")
const ROPE_TEXTURE := preload("res://assets/emboque/cuerda.png")
## Cuánto cuelga la cuerda entre dos niveles (px por cada 100 px de largo).
const ROPE_SAG := 7.0
const ROPE_WIDTH := 7.0
const ROPE_LOCKED_ALPHA := 0.16

@onready var _ropes: Node2D = $Ropes
@onready var _nodes: Control = $Nodes
@onready var _title: Label = $Info/Title
@onready var _details: Label = $Info/Details
@onready var _progress: Label = $Progress
@onready var _back: Control = $BackButton

var _by_id := {}        # id → LevelNode
var _rope_by_edge := {} # "from>to" → Line2D

func _ready() -> void:
	_back.pressed.connect(_go_back)
	_build()

func _build() -> void:
	for c in _nodes.get_children():
		c.queue_free()
	for c in _ropes.get_children():
		c.queue_free()
	_by_id.clear()
	_rope_by_edge.clear()
	var fresh := _freshly_unlocked()
	# Cuerdas primero (quedan debajo de los nodos).
	for level in LevelCatalog.LEVELS:
		if not level.get("rope", true):
			continue
		for from_id: String in level.get("from", []):
			var from := LevelCatalog.get_level(from_id)
			if from.is_empty():
				continue
			var open := ScoreBoard.is_completed(from_id) or ScoreBoard.unlock_all
			var rope := _make_rope(from.pos, level.pos, open)
			_ropes.add_child(rope)
			_rope_by_edge["%s>%s" % [from_id, level.id]] = rope
	for level in LevelCatalog.LEVELS:
		var node := NODE_SCENE.instantiate() as LevelNode
		_nodes.add_child(node)
		node.position = level.pos - Vector2(LevelNode.SIZE, LevelNode.SIZE) * 0.5
		var total := ScoreBoard.collectible_total(level.id)
		var got_all := total > 0 and ScoreBoard.best_collected(level.id) >= total
		node.setup(level.id, LevelCatalog.number_of(level.id), LevelCatalog.is_unlocked(level.id),
			ScoreBoard.is_completed(level.id), got_all, level.get("special", false))
		node.chosen.connect(_on_chosen)
		node.focused.connect(_on_focused)
		_by_id[level.id] = node
	_link_focus_neighbors()
	_update_progress()
	_animate_unlocks(fresh)
	var start := _initial_focus(fresh)
	if _by_id.has(start):
		(_by_id[start] as LevelNode).button().grab_focus()

## Una cuerda que cuelga un poco entre dos niveles (curva cuadrática).
func _make_rope(a: Vector2, b: Vector2, open: bool) -> Line2D:
	var line := Line2D.new()
	line.texture = ROPE_TEXTURE
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	line.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	line.width = ROPE_WIDTH
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.points = _rope_points(a, b, 1.0)
	line.modulate = Color(1, 1, 1, 1.0 if open else ROPE_LOCKED_ALPHA)
	line.set_meta("a", a)
	line.set_meta("b", b)
	return line

func _rope_points(a: Vector2, b: Vector2, amount: float) -> PackedVector2Array:
	var mid := (a + b) * 0.5 + Vector2(0, a.distance_to(b) * ROPE_SAG / 100.0)
	var pts := PackedVector2Array()
	var steps := 16
	for i in range(steps + 1):
		var t := float(i) / steps * amount
		pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
	return pts

## Niveles que se desbloquearon con la última victoria (para animarlos una vez).
func _freshly_unlocked() -> Array[String]:
	var result: Array[String] = []
	if not ScoreBoard.last_first_clear:
		return result
	var won := ScoreBoard.last_level_id
	for next_id in LevelCatalog.next_of(won):
		if ScoreBoard.is_completed(next_id):
			continue
		if LevelCatalog.is_unlocked(next_id) and not LevelCatalog.was_unlocked_without(next_id, won):
			result.append(next_id)
	ScoreBoard.last_first_clear = false  # se anima una sola vez
	return result

func _animate_unlocks(fresh: Array[String]) -> void:
	var won := ScoreBoard.last_level_id
	for i in fresh.size():
		var id := fresh[i]
		var rope := _rope_by_edge.get("%s>%s" % [won, id]) as Line2D
		if rope != null:
			var a: Vector2 = rope.get_meta("a")
			var b: Vector2 = rope.get_meta("b")
			var tween := create_tween()
			tween.tween_interval(0.25 + i * 0.2)
			tween.tween_method(func(v: float) -> void: rope.points = _rope_points(a, b, v), 0.0, 1.0, 0.55) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		(_by_id[id] as LevelNode).pop_in(0.7 + i * 0.2)

func _initial_focus(fresh: Array[String]) -> String:
	if not fresh.is_empty():
		return fresh[0]
	if _by_id.has(ScoreBoard.last_level_id):
		return ScoreBoard.last_level_id
	for level in LevelCatalog.LEVELS:
		if LevelCatalog.is_unlocked(level.id) and not ScoreBoard.is_completed(level.id):
			return level.id
	return LevelCatalog.LEVELS[0].id

## Vecinos para navegar con flechas: en cada dirección, el nivel más cercano que
## quede más o menos hacia ese lado.
func _link_focus_neighbors() -> void:
	var dirs := {
		"focus_neighbor_left": Vector2.LEFT, "focus_neighbor_right": Vector2.RIGHT,
		"focus_neighbor_top": Vector2.UP, "focus_neighbor_bottom": Vector2.DOWN,
	}
	for id: String in _by_id:
		var node := _by_id[id] as LevelNode
		var from: Vector2 = LevelCatalog.get_level(id).pos
		for prop: String in dirs:
			var dir: Vector2 = dirs[prop]
			var best: LevelNode = null
			var best_score := INF
			for other_id: String in _by_id:
				if other_id == id:
					continue
				var to: Vector2 = LevelCatalog.get_level(other_id).pos
				var d := to - from
				var along := d.dot(dir)
				if along <= 0.0:
					continue
				var across := absf(d.cross(dir))
				if across > along * 1.8:
					continue
				var score := along + across * 2.0
				if score < best_score:
					best_score = score
					best = _by_id[other_id]
			var btn := node.button()
			btn.set(prop, btn.get_path_to(best.button()) if best != null else btn.get_path_to(btn))

func _on_focused(id: String) -> void:
	var level := LevelCatalog.get_level(id)
	var number := LevelCatalog.number_of(id)
	if not LevelCatalog.is_unlocked(id):
		_title.text = tr("MAP_LEVEL") % number
		_details.text = tr(level.get("hint", "MAP_LOCKED"))
		return
	_title.text = "%d · %s" % [number, LevelCatalog.display_name(id)]
	if not _exists(id):
		_details.text = tr("MAP_SOON")
		return
	var total := ScoreBoard.collectible_total(id)
	var parts: Array[String] = []
	if ScoreBoard.is_completed(id):
		parts.append(tr("MAP_RECORD") % ScoreBoard.get_highscore(id))
		if total > 0:
			parts.append(tr("MAP_COLLECTED") % [ScoreBoard.best_collected(id), total])
	else:
		parts.append(tr("MAP_NOT_DONE"))
	_details.text = "   ·   ".join(parts)

func _on_chosen(id: String) -> void:
	if not LevelCatalog.is_unlocked(id) or not _exists(id):
		(_by_id[id] as LevelNode).shake()
		return
	get_tree().paused = false
	get_tree().change_scene_to_file(LevelCatalog.get_level(id).scene)

func _exists(id: String) -> bool:
	return ResourceLoader.exists(LevelCatalog.get_level(id).get("scene", ""))

func _update_progress() -> void:
	var done := 0
	for level in LevelCatalog.LEVELS:
		if ScoreBoard.is_completed(level.id):
			done += 1
	_progress.text = "%d / %d" % [done, LevelCatalog.LEVELS.size()]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_back()
	elif OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_F9:
		ScoreBoard.unlock_all = not ScoreBoard.unlock_all
		_build()

func _go_back() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
