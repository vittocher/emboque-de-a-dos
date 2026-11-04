extends SceneTree

## Bot que juega un nivel siguiendo un plan, para verificar que se puede ganar.
##
## Uso (headless y más rápido que tiempo real con --fixed-fps):
##   godot --headless --fixed-fps 120 --path . -s tests/play_level.gd -- \
##       res://scenes/levels/tronco_1.tscn res://tests/solutions/tronco_1.gd [opciones]
## Opciones:
##   --timeout=S     segundos de juego antes de rendirse (default 90)
##   --trace=S       imprime posiciones cada S segundos
##   --shots=DIR     guarda una captura cada --shot-every s (sin --headless)
##   --shot-every=S  (default 1)
##   --var=NOMBRE=VALOR  variables para el plan (ctx.vars), útil para barridos
##
## Imprime al final una línea:  RESULT WIN|DEATH|TIMEOUT t=… collected=a/b ...
##
## El plan (tests/solutions/<nivel>.gd) tiene `static func plan(ctx) -> Dictionary`
## que devuelve {"p1": [pasos], "p2": [pasos]}. Pasos (arrays):
##   ["walk_to", x, tol=6]          camina hasta x (frena a tiempo)
##   ["hold", accion, s]            mantiene una acción (left/right/jump/down/release/pull/throw) s segundos
##   ["press", accion] / ["release", accion]
##   ["tap", accion]                la aprieta 3 ticks
##   ["wait", s]
##   ["wait_floor"]                 espera a estar en el piso
##   ["jump_to", x]                 salta hacia x manteniendo la dirección hasta llegar/aterrizar
##   ["rope", largo, tol=4]         tira/suelta hasta ese largo de cuerda
##   ["sync", "tag"]                espera a que el otro jugador llegue al mismo tag
##   ["until", Callable(ctx) -> bool, timeout_s=20]
##   ["do", Callable(ctx)]          ejecuta algo una vez
##   ["pump", s]                    colgando: empuja a favor del balanceo durante s
##   ["release_all"]
##   ["jiggle", home_x, back, veces=6]  va y vuelve (home_x-back ↔ home_x) para
##                                  balancear el extremo; termina antes si ya ganó
## Los nombres de clases del proyecto NO se usan acá (el script se compila antes
## que los autoloads, ver CLAUDE.md): todo se accede por nombre de propiedad.

var level: Node
var players := {}      # "p1"/"p2" → Player
var emboques := {}     # "p1"/"p2" → Emboque
var vars := {}
var time := 0.0
var deaths: Array[String] = []

var _plans := {}
var _idx := {"p1": 0, "p2": 0}
var _step_time := {"p1": 0.0, "p2": 0.0}
var _step_state := {"p1": {}, "p2": {}}
var _synced := {}      # tag → {"p1": bool, "p2": bool}
var _timeout := 90.0
var _trace := 0.0
var _trace_acc := 0.0
var _shots_dir := ""
var _shot_every := 1.0
var _shot_acc := 0.0
var _shot_n := 0
var _done := false
var _win_manager: Node

const FRICTION := 2600.0
const ACTIONS := ["left", "right", "jump", "down", "release", "pull", "throw"]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("uso: -- <escena> <solucion.gd> [opciones]")
		quit(2)
		return
	for a in args.slice(2):
		if a.begins_with("--timeout="):
			_timeout = float(a.get_slice("=", 1))
		elif a.begins_with("--trace="):
			_trace = float(a.get_slice("=", 1))
		elif a.begins_with("--shots="):
			_shots_dir = a.get_slice("=", 1)
		elif a.begins_with("--shot-every="):
			_shot_every = float(a.get_slice("=", 1))
		elif a.begins_with("--var="):
			var kv := a.trim_prefix("--var=")
			vars[kv.get_slice("=", 0)] = kv.get_slice("=", 1)
	var scene := load(args[0]) as PackedScene
	var solution := load(args[1]) as GDScript
	if scene == null or solution == null or not solution.can_instantiate():
		print("RESULT ERROR no se pudo cargar ", args)
		quit(2)
		return
	level = scene.instantiate()
	_disable_reloads(level)
	root.add_child(level)
	current_scene = level
	_bind_actors()
	_plans = solution.plan(self)
	physics_frame.connect(_tick)

## Las zonas de muerte no recargan: se anota la muerte y el bot termina.
func _disable_reloads(node: Node) -> void:
	if "reload_on_death" in node:
		node.reload_on_death = false
		node.triggered.connect(func(body: Node) -> void: deaths.append("%s@%s" % [body.name, node.get_parent().name if node.get_parent() != level else node.name]))
	if "restart_delay" in node:
		node.restart_delay = 9999.0
		_win_manager = node
	for c in node.get_children():
		_disable_reloads(c)

func _bind_actors() -> void:
	for n in level.get_children():
		if "input_prefix" in n:
			if n.has_method("attach_swing"):
				players[n.input_prefix] = n
			elif n.has_method("get_end"):
				emboques[n.input_prefix] = n

# --- Consultas para los planes ---

func p(i: int) -> Node2D:
	return players["p%d" % i]

func e(i: int) -> Node:
	return emboques["p%d" % i]

func end_pos(i: int) -> Vector2:
	return e(i).get_end_position()

func hooked(i: int) -> bool:
	return e(i)._hooked

func on_floor(i: int) -> bool:
	return p(i).is_on_floor()

func won() -> bool:
	return _win_manager != null and _win_manager._won

func var_f(name: String, default: float) -> float:
	return float(vars.get(name, default))

# --- Bucle ---

func _tick() -> void:
	if _done:
		return
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	time += dt * Engine.time_scale
	for who in ["p1", "p2"]:
		_run_player(who, dt)
	if _trace > 0.0:
		_trace_acc += dt
		if _trace_acc >= _trace:
			_trace_acc = 0.0
			print(_status_line())
	if _shots_dir != "":
		_shot_acc += dt
		if _shot_acc >= _shot_every:
			_shot_acc = 0.0
			var img := root.get_texture().get_image()
			if img != null:
				img.save_png("%s/f%03d.png" % [_shots_dir, _shot_n])
			_shot_n += 1
	if won():
		_finish("WIN")
	elif not deaths.is_empty():
		_finish("DEATH " + ",".join(deaths))
	elif time > _timeout:
		_finish("TIMEOUT")

func _status_line() -> String:
	var parts := ["t=%.2f" % time]
	for i in [1, 2]:
		var pl := p(i)
		parts.append("p%d=(%.0f,%.0f) v=(%.0f,%.0f) floor=%s end=(%.0f,%.0f) rope=%.0f hook=%s step=%d" % [
			i, pl.global_position.x, pl.global_position.y, pl.velocity.x, pl.velocity.y,
			pl.is_on_floor(), end_pos(i).x, end_pos(i).y, e(i).rope_length, hooked(i), _idx["p%d" % i]])
	parts.append("dist_ends=%.0f" % end_pos(1).distance_to(end_pos(2)))
	return " ".join(parts)

func _finish(result: String) -> void:
	_done = true
	var sm := level.get_node_or_null("ScoreManager")
	var collected := "%d/%d" % [sm.collected, sm.total] if sm != null and "collected" in sm else "?"
	print(_status_line())
	var missing: Array[String] = []
	for c in get_nodes_in_group(&"collectibles"):
		if not c.is_queued_for_deletion():
			missing.append("%s(%.0f,%.0f)" % [c.name, c.global_position.x, c.global_position.y])
	if not missing.is_empty():
		print("MISSING ", " ".join(missing))
	print("RESULT %s t=%.2f collected=%s steps=%d/%d,%d/%d" % [result, time, collected,
		_idx.p1, _plans.get("p1", []).size(), _idx.p2, _plans.get("p2", []).size()])
	for a in ACTIONS:
		for who in ["p1", "p2"]:
			Input.action_release(who + "_" + a)
	Engine.time_scale = 1.0
	quit(0 if result == "WIN" else 1)

# --- Ejecución de pasos ---

func _act(who: String, action: String, on: bool) -> void:
	var full := who + "_" + action
	if on:
		Input.action_press(full)
	else:
		Input.action_release(full)

func _next(who: String) -> void:
	_idx[who] += 1
	_step_time[who] = 0.0
	_step_state[who] = {}

func _run_player(who: String, dt: float) -> void:
	var plan: Array = _plans.get(who, [])
	# Varios pasos instantáneos pueden encadenarse en el mismo tick.
	for _guard in 8:
		if _idx[who] >= plan.size():
			return
		var step: Array = plan[_idx[who]]
		_step_time[who] += dt if _step_state[who].get("_started", false) else 0.0
		_step_state[who]["_started"] = true
		if not _do_step(who, step, dt):
			return
		_next(who)

## Devuelve true cuando el paso terminó.
func _do_step(who: String, step: Array, dt: float) -> bool:
	var pl: Node2D = players[who]
	var st: Dictionary = _step_state[who]
	var t: float = _step_time[who]
	match step[0]:
		"wait":
			return t >= float(step[1])
		"press":
			_act(who, step[1], true)
			return true
		"release":
			_act(who, step[1], false)
			return true
		"release_all":
			for a in ACTIONS:
				_act(who, a, false)
			return true
		"tap":
			_act(who, step[1], true)
			if t >= 3.0 / 120.0:
				_act(who, step[1], false)
				return true
			return false
		"hold":
			_act(who, step[1], true)
			if t >= float(step[2]):
				_act(who, step[1], false)
				return true
			return false
		"wait_floor":
			return pl.is_on_floor() and t > 0.02
		"walk_to":
			return _walk_to(who, pl, float(step[1]), float(step[2]) if step.size() > 2 else 6.0, t)
		"jump_to":
			return _jump_to(who, pl, float(step[1]), st, t)
		"rope":
			var target := float(step[1])
			var tol := float(step[2]) if step.size() > 2 else 4.0
			var cur: float = emboques[who].rope_length
			_act(who, "pull", cur > target + tol)
			_act(who, "release", cur < target - tol)
			if absf(cur - target) <= tol:
				_act(who, "pull", false)
				_act(who, "release", false)
				return true
			return t > 4.0
		"sync":
			var tag: String = step[1]
			if not _synced.has(tag):
				_synced[tag] = {}
			_synced[tag][who] = true
			return _synced[tag].size() >= 2
		"until":
			var cond: Callable = step[1]
			var limit := float(step[2]) if step.size() > 2 else 20.0
			return cond.call(self) or t > limit
		"do":
			(step[1] as Callable).call(self)
			return true
		"jiggle":
			var home := float(step[1])
			var back := float(step[2])
			var times := int(step[3]) if step.size() > 3 else 6
			if not st.has("n"):
				st["n"] = 0
				st["leg"] = 0
				st["leg_t"] = 0.0
			if won() or st["n"] >= times:
				_act(who, "left", false)
				_act(who, "right", false)
				return true
			var target := home - back if st["leg"] == 0 else home
			if _walk_to(who, pl, target, 6.0, t - st["leg_t"]):
				st["leg_t"] = t
				st["leg"] = 1 - st["leg"]
				if st["leg"] == 0:
					st["n"] += 1
					st["wait_until"] = t + 0.6
			return false
		"pump":
			var omega: float = pl._swing_omega
			_act(who, "right", omega > 0.0)
			_act(who, "left", omega <= 0.0)
			if t >= float(step[1]):
				_act(who, "right", false)
				_act(who, "left", false)
				return true
			return false
	push_error("paso desconocido: %s" % [step])
	return true

func _walk_to(who: String, pl: Node2D, target: float, tol: float, t: float) -> bool:
	var dx := target - pl.global_position.x
	var vx: float = pl.velocity.x
	var control := 1.0 if pl.is_on_floor() else 0.5
	var stop_dist := vx * vx / (2.0 * FRICTION * control)
	var moving_toward := signf(vx) == signf(dx) and absf(vx) > 5.0
	var want := 0
	if absf(dx) > tol and not (moving_toward and absf(dx) <= stop_dist + tol * 0.5):
		want = 1 if dx > 0.0 else -1
	_act(who, "right", want > 0)
	_act(who, "left", want < 0)
	if want == 0 and absf(vx) < 15.0 and absf(dx) <= tol * 2.0:
		return true
	return t > 12.0

func _jump_to(who: String, pl: Node2D, target: float, st: Dictionary, t: float) -> bool:
	var dir := 1 if target > pl.global_position.x else -1
	if not st.has("dir"):
		st["dir"] = dir
		_act(who, "jump", true)
	if t > 0.05:
		_act(who, "jump", false)
	var d: int = st["dir"]
	var reached := (pl.global_position.x - target) * d >= 0.0
	_act(who, "right", d > 0 and not reached)
	_act(who, "left", d < 0 and not reached)
	if t > 0.1 and pl.is_on_floor():
		_act(who, "right", false)
		_act(who, "left", false)
		return true
	return t > 6.0
