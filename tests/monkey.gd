extends SceneTree

## "Mono tramposo": busca atajos jugando al azar (caminar, saltar, balancearse, cuerda,
## lanzar) y reiniciando al morir. Sirve para comprobar que un nivel NO se gana sin su
## mecánica clave (--no). Ver tests/run_shortcuts.sh.
##
## Uso:
##   godot --headless --fixed-fps 120 --path . -s tests/monkey.gd -- \
##       res://scenes/levels/peligro_2.tscn --no=rope [opciones]
## Opciones:
##   --no=a,b      mecánicas prohibidas: rope (soltar/tirar), hook (sin ganchos), throw
##                 (lanzar), box (sin cajas), wind (sin viento), jump
##   --remove=A,B  borra esos nodos del nivel (p. ej. HookCenter)
##   --time=S      segundos de juego en total (default 300)
##   --life=S      segundos por intento antes de reiniciar (default 40)
##   --seed=N
##   --start=x1,y1,x2,y2  parte desde ahí (p. ej. ya en la meta) y con la cuerda al mínimo:
##                 el punto va ~100 px sobre el piso, para que el extremo nazca arriba
##   --goal=x1,y1,x2,y2   no mira si gana: avisa si P1 (o P2) llega a 40 px de su punto
## Imprime  MONKEY WIN|NO t=… lives=…  (y las últimas acciones si lo logró).

var _scene: PackedScene
var _level: Node
var _no: PackedStringArray = []
var _remove: PackedStringArray = []
var _total := 300.0
var _life := 40.0
var _time := 0.0
var _life_t := 0.0
var _lives := 0
var _rng := RandomNumberGenerator.new()
var _starts: PackedFloat64Array = []
var _goals: PackedFloat64Array = []
var _dead := false
var _busy := false
var _wm: Node
var _pl := {}
var _emb := {}
var _left := {}     # segundos que quedan de la acción de cada jugador
var _log: Array[String] = []
var _size := Vector2(1280, 720)
var _bias := 0.6
const KEYS := ["left", "right", "jump", "down", "release", "pull", "throw"]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_rng.seed = 1
	for a in args.slice(1):
		var v := a.get_slice("=", 1)
		if a.begins_with("--no="):
			_no = v.split(",")
		elif a.begins_with("--remove="):
			_remove = v.split(",")
		elif a.begins_with("--time="):
			_total = float(v)
		elif a.begins_with("--life="):
			_life = float(v)
		elif a.begins_with("--seed="):
			_rng.seed = int(v)
		elif a.begins_with("--start="):
			_starts = v.split_floats(",")
		elif a.begins_with("--goal="):
			_goals = v.split_floats(",")
	_scene = load(args[0])
	_spawn()
	physics_frame.connect(_tick)

func _spawn() -> void:
	Engine.time_scale = 1.0
	_level = _scene.instantiate()
	_dead = false
	_life_t = 0.0
	_lives += 1
	_bias = _rng.randf_range(0.45, 0.8)
	_prepare(_level)
	if _starts.size() == 4:
		_level.get_node("Player1").position = Vector2(_starts[0], _starts[1])
		_level.get_node("Player2").position = Vector2(_starts[2], _starts[3])
		for i in [1, 2]:
			_level.get_node("Emboque%d" % i).rope_length = 60.0
	root.add_child(_level)
	current_scene = _level
	var cm := _level.get_node_or_null("CloseupManager")
	if cm != null:
		_size = cm.level_size
	for i in [1, 2]:
		_pl[i] = _level.get_node("Player%d" % i)
		_emb[i] = _level.get_node("Emboque%d" % i)
		_left[i] = 0.6

func _prepare(node: Node) -> void:
	if "reload_on_death" in node:
		node.reload_on_death = false
		node.triggered.connect(func(_b: Node) -> void: _dead = true)
	if "restart_delay" in node:
		node.restart_delay = 99999.0
		_wm = node
	for c in node.get_children():
		var path := c.scene_file_path
		if c.name in _remove or ("hook" in _no and path.ends_with("hook_point.tscn")) \
				or ("wind" in _no and path.ends_with("wind_zone.tscn")) \
				or ("box" in _no and path.ends_with("push_box.tscn")):
			node.remove_child(c)
			c.free()
			continue
		_prepare(c)

func _keys(i: int, on: Array) -> void:
	for k: String in KEYS:
		var want: bool = k in on
		if (k in ["release", "pull"] and "rope" in _no) or k in _no:
			want = false
		var full := "p%d_%s" % [i, k]
		if want:
			Input.action_press(full)
		else:
			Input.action_release(full)

func _pick(i: int) -> void:
	var toward := "right" if _pl[i].global_position.x < _size.x * 0.5 else "left"
	var away := "left" if toward == "right" else "right"
	var dir := toward if _rng.randf() < _bias else away
	var r := _rng.randf()
	var d := 0.2
	var hold := []
	if r < 0.28:
		hold = [dir]
		d = _rng.randf_range(0.05, 0.9)
	elif r < 0.52:
		hold = [dir, "jump"]
		d = _rng.randf_range(0.05, 1.1)
	elif r < 0.57:
		hold = ["jump"]
		d = 0.3
	elif r < 0.70:
		# Un vaivén al ritmo del péndulo (o parte de él).
		hold = [dir]
		d = PI * sqrt(_emb[i].rope_length / 980.0) * _rng.randf_range(0.2, 1.0)
	elif r < 0.79:
		hold = ["pull"]
		d = _rng.randf_range(0.05, 1.0)
	elif r < 0.88:
		hold = ["release"]
		d = _rng.randf_range(0.05, 1.0)
	elif r < 0.93:
		hold = ["throw"]
		d = _rng.randf_range(0.05, 0.5)
	elif r < 0.95:
		hold = ["down"]
		d = 0.1
	else:
		d = _rng.randf_range(0.1, 0.8)
	_left[i] = d
	_keys(i, hold)
	_log.append("%.1f p%d %s %.2f (%.0f,%.0f)" % [_life_t, i, hold, d, _pl[i].global_position.x, _pl[i].global_position.y])
	if _log.size() > 40:
		_log.pop_front()

## Entre cuadros y con las teclas sueltas: creado dentro del paso de física, el extremo
## nacía en el origen y arrastraba al jugador.
func _respawn() -> void:
	_busy = true
	for i in [1, 2]:
		_keys(i, [])
	await process_frame
	root.remove_child(_level)
	_level.free()
	_level = null
	await process_frame
	await process_frame
	_spawn()
	_busy = false

func _tick() -> void:
	if _busy:
		return
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	_time += dt
	_life_t += dt
	var done: bool = _wm != null and _wm._won and _goals.is_empty()
	if _goals.size() == 4:
		for i in [1, 2]:
			if _pl[i].global_position.distance_to(Vector2(_goals[i * 2 - 2], _goals[i * 2 - 1])) < 40.0:
				done = true
	if done:
		print("\n".join(_log))
		print("MONKEY WIN t=%.1f life=%.1f lives=%d p1=%s p2=%s" % [_time, _life_t, _lives, _pl[1].global_position, _pl[2].global_position])
		quit(1)
		return
	if _time > _total:
		print("MONKEY NO t=%.0f lives=%d" % [_time, _lives])
		quit(0)
		return
	if _dead or _life_t > _life or (_wm != null and _wm._won):
		_respawn()
		return
	for i in [1, 2]:
		_left[i] -= dt
		if _left[i] <= 0.0:
			_pick(i)
