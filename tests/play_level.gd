extends SceneTree

## Bot que juega un nivel siguiendo un plan, para verificar que se puede ganar.
##
## Uso (headless y más rápido que tiempo real con --fixed-fps):
##   godot --headless --fixed-fps 120 --path . -s tests/play_level.gd -- \
##       res://tests/solutions/tronco_1.gd [opciones]
## (la escena sale de la const SCENE de la solución; también se puede pasar antes).
## Todas las soluciones de una vez: tests/run_all.sh
## Opciones:
##   --timeout=S     segundos de juego antes de rendirse (default 90)
##   --trace=S       imprime posiciones cada S segundos
##   --shots=DIR     guarda una captura cada --shot-every s (sin --headless)
##   --shot-every=S  (default 1)
##   --var=NOMBRE=VALOR  variables para el plan (ctx.vars), útil para barridos
## Para grabar (tráiler, con --write-movie de Godot; ver trailer/README.md):
##   --linger=S      al terminar sigue S s más (el closeup y el cartel de victoria)
##   --lang=CÓDIGO   idioma del juego ("es", "en")
##   --music=V       volumen de la música (0 = muda, para montarla aparte)
##   --still=1|2|12  control: esos jugadores llegan a la meta pero NO se balancean
##                   (se saltan sus pasos swing / jiggle); ver tests/run_controls.sh
##   --start=x1,y1,x2,y2  para probar un tramo: parten desde ahí, con la cuerda al mínimo
##                   (el punto va ~100 px sobre el piso, para que el extremo nazca arriba)
##   --jump=V        otra velocidad de salto (px/s), para ver con cuánto margen se gana
##   --hazards       auditoría de peligros: imprime las púas que ningún EXTREMO tocó y las
##                   cacas que ningún JUGADOR tocó (ahí, un fuego daría lo mismo)
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
##   ["leap_to", x]                 igual, pero frena en el aire para caer en x
##   ["fly_to", x]                  en el aire (p. ej. tras soltarse de un gancho): se frena para caer en x
##   ["rope", largo, tol=4]         tira/suelta hasta ese largo de cuerda
##   ["sync", "tag"]                espera a que el otro jugador llegue al mismo tag
##   ["until", Callable(ctx) -> bool, timeout_s=20]
##   ["do", Callable(ctx)]          ejecuta algo una vez
##   ["pump", s]                    colgando: empuja a favor del balanceo durante s
##   ["pump_until", Callable(ctx) -> bool, timeout_s]  igual, hasta que se cumpla la condición
##   ["pump_end", s, centro_x, margen]  en el suelo: camina hacia donde se mueve su
##                                  extremo (como empujar un columpio) sin alejarse
##                                  más de margen de centro_x; agranda el balanceo
##   ["release_all"]
##   ["jiggle", home_x, back, veces=6]  va y vuelve (home_x-back ↔ home_x) para
##                                  balancear el extremo; termina antes si ya ganó
##   ["hang", x]                en el borde x: acorta la cuerda y salta en el lugar hasta
##                                  que el extremo quede colgando afuera (apoyado en la
##                                  repisa, al mínimo, no cae solo)
##   ["swing", home_x, back, veces=14, g=980]  balanceo al RITMO del péndulo: va y vuelve
##                                  entre home_x y home_x-back, un tramo por cada medio
##                                  período (según el largo de su cuerda). Con los dos
##                                  sincronizados (sync antes), se balancean a la vez
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
var _linger := 0.0
var _still := ""
var _starts: PackedFloat64Array = []
var _win_manager: Node
var _jump := 0.0
var _hazards := {}     # zona → la tocó alguien a quien no daña (solo con --hazards)

const FRICTION := 2600.0
const ACTIONS := ["left", "right", "jump", "down", "release", "pull", "throw"]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	# Con un solo argumento posicional (la solución), la escena sale de su const SCENE.
	if args.size() >= 1 and args[0].ends_with(".gd"):
		var sol := load(args[0]) as GDScript
		var scene_path: String = sol.get_script_constant_map().get("SCENE", "") if sol != null else ""
		args.insert(0, scene_path)
	if args.size() < 2:
		print("uso: -- [escena] <solucion.gd> [opciones]")
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
		elif a.begins_with("--still="):
			_still = a.get_slice("=", 1)
		elif a.begins_with("--jump="):
			_jump = float(a.get_slice("=", 1))
		elif a == "--hazards":
			_hazards["_on"] = true
		elif a.begins_with("--linger="):
			_linger = float(a.get_slice("=", 1))
		elif a.begins_with("--lang="):
			root.get_node("SettingsManager").set_language(a.get_slice("=", 1))
		elif a.begins_with("--music="):
			root.get_node("SettingsManager").set_music_volume(float(a.get_slice("=", 1)))
		elif a.begins_with("--start="):
			_starts = a.get_slice("=", 1).split_floats(",")
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
	if _starts.size() == 4:
		for i in [1, 2]:
			level.get_node("Player%d" % i).position = Vector2(_starts[i * 2 - 2], _starts[i * 2 - 1])
			level.get_node("Emboque%d" % i).rope_length = 60.0
	root.add_child(level)
	current_scene = level
	_bind_actors()
	if _jump > 0.0:
		for who: String in players:
			players[who].jump_velocity = -_jump
	if _hazards.erase("_on"):
		_audit_hazards(level)
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

## Pone sobre cada púa / caca un sensor igual que detecta a quien NO mata.
func _audit_hazards(node: Node) -> void:
	for c in node.get_children():
		_audit_hazards(c)
	if not node is Area2D or not "reload_on_death" in node or node.get_parent() != level 			or (node as Area2D).collision_mask not in [2, 12] or node.scene_file_path.contains("fall_zone"):
		return
	var sensor := Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 14 - (node as Area2D).collision_mask
	for c in node.get_children():
		if c is CollisionShape2D:
			sensor.add_child(c.duplicate())
	node.add_child(sensor)
	_hazards[node.name] = false
	sensor.body_entered.connect(func(_b: Node) -> void: _hazards[node.name] = true)

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
	if not _hazards.is_empty():
		print("HAZARDS sin aprovechar: ", " ".join(_hazards.keys().filter(func(k: StringName) -> bool: return not _hazards[k])))
	print("RESULT %s t=%.2f collected=%s steps=%d/%d,%d/%d" % [result, time, collected,
		_idx.p1, _plans.get("p1", []).size(), _idx.p2, _plans.get("p2", []).size()])
	for a in ACTIONS:
		for who in ["p1", "p2"]:
			Input.action_release(who + "_" + a)
	if _linger > 0.0:
		# Grabando: se deja correr el final (closeup en cámara lenta + cartel).
		await create_timer(_linger, true, false, true).timeout
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
	if step[0] in ["swing", "jiggle"] and _still.contains(who.right(1)):
		return true
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
		"leap_to":
			_act(who, "jump", t < 0.05)
			_walk_to(who, pl, float(step[1]), 4.0, 0.0)
			if t > 0.1 and pl.is_on_floor():
				_act(who, "right", false)
				_act(who, "left", false)
				return true
			return t > 6.0
		"fly_to":
			# En el aire: corrige la velocidad (también frenando en contra) para caer en x.
			var want_v := clampf((float(step[1]) - pl.global_position.x) * 4.0, -420.0, 420.0)
			var fly_v: float = pl.velocity.x
			_act(who, "right", fly_v < want_v - 25.0)
			_act(who, "left", fly_v > want_v + 25.0)
			if t > 0.1 and pl.is_on_floor():
				_act(who, "right", false)
				_act(who, "left", false)
				return true
			return t > 5.0
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
		"hang":
			# Solo mira (y salta) tras estar quieto en el borde un momento.
			var at_edge: bool = _walk_to(who, pl, float(step[1]), 2.0, 0.0) and pl.is_on_floor()
			# Si el extremo quedó bajo la repisa, se recoge recién en el borde y colgando
			# derecho (antes se trabaría, y con balanceo tiraría al jugador).
			var below: bool = emboques[who].get_end_position().y > pl.global_position.y + 36.0
			var end_body: RigidBody2D = emboques[who].get_end()
			var calm: bool = absf(end_body.global_position.x - pl.global_position.x) < 30.0 or end_body.linear_velocity.length() < 30.0
			_act(who, "pull", emboques[who].rope_length > 61.0 and (not below or at_edge and calm))
			st["still"] = float(st.get("still", 0.0)) + dt if at_edge else 0.0
			var ready: bool = st["still"] > 0.5 and emboques[who].rope_length <= 61.0
			if ready and below:
				_act(who, "pull", false)
				return true
			_act(who, "jump", ready)
			return t > 10.0
		"swing":
			# Medio período = pi * raíz(L / g); en tiempo de juego (la cámara lenta no
			# cambia el ritmo del péndulo).
			if not st.has("leg"):
				st["leg"] = 0
				st["start"] = time
			var legs := 2 * (int(step[3]) if step.size() > 3 else 14)
			if won() or st["leg"] >= legs:
				_act(who, "left", false)
				_act(who, "right", false)
				return true
			_walk_to(who, pl, float(step[1]) - (float(step[2]) if st["leg"] % 2 == 0 else 0.0), 4.0, 0.0)
			var half: float = PI * sqrt(emboques[who].rope_length / (float(step[4]) if step.size() > 4 else 980.0))
			if time - st["start"] >= half:
				st["start"] += half
				st["leg"] += 1
			return false
		"pump_end":
			var center := float(step[2])
			var margin := float(step[3])
			var evx: float = emboques[who].get_end().linear_velocity.x
			var dx := pl.global_position.x - center
			var want := 0
			if absf(evx) > 20.0:
				want = 1 if evx > 0.0 else -1
			if dx > margin and want > 0 or dx < -margin and want < 0:
				want = 0
			_act(who, "right", want > 0)
			_act(who, "left", want < 0)
			if t >= float(step[1]) or won():
				_act(who, "right", false)
				_act(who, "left", false)
				return true
			return false
		"pump", "pump_until":
			var omega: float = pl._swing_omega
			_act(who, "right", omega > 0.0)
			_act(who, "left", omega <= 0.0)
			var done: bool = t >= float(step[1]) if step[0] == "pump" 				else (step[1] as Callable).call(self) or t > float(step[2])
			if done:
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
