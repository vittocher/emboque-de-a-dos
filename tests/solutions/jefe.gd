extends RefCounted
const SCENE := "res://scenes/levels/jefe.tscn"
## Segundos de juego para tests/run_all.sh (el nivel completo dura ~90 s).
const TIMEOUT := 150
## El Tue Tue (jefe final), en sus tres fases:
## 1. Pelea: cada uno se para a tiro del Tue Tue (a ~220 px de él, de su lado) y,
##    mientras planea, recoge el emboque a la mano, apunta y lo lanza cuando la mira
##    pasa por el ángulo que lo apunta. Cuando avisa una PICADA suelta lo que
##    apuntaba y salta al pasar el pájaro; en una RÁFAGA camina en contra para no
##    terminar en el foso de púas.
## 2. Subida: con el emboque en la mano (sin cuerda que lo amarre a las islas) salta
##    de isla en isla por su lado (lee el trazado del nivel: siempre salta a la isla
##    siguiente a la que está parado, así se recupera si un golpe lo bota). En las
##    torres lanza el emboque al gancho, trepa la cuerda y salta arriba, pero solo
##    cuando el Tue Tue no le va a caer encima ni soplar mientras apunta. Contra las
##    RÁFAGAS se queda en su lugar caminando en contra; si la PICADA va a él, salta
##    ya a la isla siguiente (o se corre por la repisa).
## 3. Cima: cada uno espera en su repisa (lejos de la cortina, bajo la que cae en
##    picada) saltando las picadas y caminando contra las ráfagas, y le lanza el
##    emboque cuando el Tue Tue pasa por su lado (la cortina tapa el otro) hasta
##    marearlo; mareado, cada uno se pega a la cortina, deja colgar su extremo sobre
##    el vacío y lo balancea hasta embocar. Si se despierta antes, otro intento.
## --var=r1=…/r2=… largo de la cuerda al colgar el extremo (120); --var=swing=…
## cuánto va y vuelve para balancearlo (40).
## --var=start=climb|summit empieza directo en esa fase (para probarlas aparte).
## Controles: --var=idle=1 (nadie hace nada: el Tue Tue los tira al foso; con
## start=climb, la cámara los deja abajo),
## --var=nostun=1 (en la cima no lo marean: los desparrama antes de embocar) y
## --var=nododge=1 (en la pelea no esquivan picadas ni ráfagas: terminan en el foso).

# Estados del Tue Tue (TueTue.State / Mode) y del lanzamiento (Emboque.ThrowState).
const B_MOVE := 1
const B_HOVER := 2
const B_TELEGRAPH := 3
const B_SWOOP := 4
const B_GUST := 5
const B_HURT := 6
const B_ORBIT := 7
const B_STUNNED := 9
const B_PECK := 11
const M_IDLE := 0
const M_FIGHT := 1
const M_FOLLOW := 3
const M_HARASS := 4
const T_NONE := 0
const T_HELD := 1
const T_AIMING := 2
const T_FLYING := 3
const T_REELING := 4

## Cortina de la cima (x de sus bordes): frena a cada uno junto al hueco.
const CURTAIN_L := 606.0
const CURTAIN_R := 674.0
## Altura de las torres con gancho (desde la isla en que se lanza hasta arriba).
const TOWER := 246.0
## A cuántos px del gancho (en x) se para para lanzar.
const THROW_DX := 178.0

static func boss(c) -> Node2D:
	return c.level.get_node("TueTue")

static func who(i: int) -> String:
	return "p%d" % i

## Aprieta una acción 3 ticks (para que el juego la vea "recién apretada").
static func tap(c, i: int, st: Dictionary, action: String) -> void:
	c._act(who(i), action, true)
	st["tap"] = action
	st["tap_n"] = 0

## Sigue con un tap en curso. True mientras no termina.
static func tapping(c, i: int, st: Dictionary) -> bool:
	if st.get("tap", "") == "":
		return false
	st["tap_n"] += 1
	if st["tap_n"] >= 3:
		c._act(who(i), st["tap"], false)
		st["tap"] = ""
	else:
		# Se sigue apretando (el salto, si la tecla venía apretada del anterior, recién
		# se aprieta de nuevo en el tick siguiente).
		c._act(who(i), st["tap"], true)
	return true

static func walk(c, i: int, want: int) -> void:
	c._act(who(i), "right", want > 0)
	c._act(who(i), "left", want < 0)

## Camina hacia x (sin frenar fino: alcanza con quedar a ±tol).
static func walk_toward(c, i: int, x: float, tol: float) -> bool:
	var dx: float = x - c.p(i).global_position.x
	walk(c, i, 0 if absf(dx) <= tol else (1 if dx > 0.0 else -1))
	return absf(dx) <= tol

## Ángulo de la mira (grados sobre la horizontal) desde la mano hasta [param to].
static func aim_angle(c, i: int, to: Vector2) -> float:
	var hand: Vector2 = c.p(i).get_node("RopeAnchor").global_position
	var d := to - hand
	return rad_to_deg(atan2(-d.y, absf(d.x)))

static func reach(c, i: int, to: Vector2) -> float:
	return c.p(i).get_node("RopeAnchor").global_position.distance_to(to)

## Ciclo de lanzamiento contra [param target] (o lo prepara si target es null):
## recoger → apuntar → lanzar al pasar la mira por el ángulo. Devuelve si lanzó.
static func throw_cycle(c, i: int, st: Dictionary, target, can_fire: bool) -> bool:
	var em = c.e(i)
	var pl = c.p(i)
	match em._throw_state:
		T_NONE:
			tap(c, i, st, "throw")  # lo recoge a la mano
		T_FLYING:
			if em.get_end().linear_velocity.length() < 400.0:
				tap(c, i, st, "throw")
		T_HELD:
			if target != null and can_fire and pl.is_on_floor():
				var dir := 1 if target.x > pl.global_position.x else -1
				if pl.facing != dir:
					tap(c, i, st, "right" if dir > 0 else "left")
				else:
					tap(c, i, st, "throw")  # a apuntar
		T_AIMING:
			if target == null or not can_fire:
				return false
			var dir := 1 if target.x > pl.global_position.x else -1
			if pl.facing != dir:
				tap(c, i, st, "right" if dir > 0 else "left")
				return false
			var want := aim_angle(c, i, target)
			var a: float = pingpong(em._aim_time * em.aim_sweep_speed_deg, em.aim_max_angle_deg)
			if want > 2.0 and want < em.aim_max_angle_deg - 1.0 and absf(a - want) < 1.2:
				tap(c, i, st, "throw")
				st["throws"] = st.get("throws", 0) + 1
				return true
	return false

## Fase 1, un tick. Termina (true) cuando el Tue Tue deja de pelear.
static func fight_tick(c, i: int, st: Dictionary) -> bool:
	var b := boss(c)
	if b.mode != M_FIGHT and b.mode != M_IDLE:
		walk(c, i, 0)
		c._act(who(i), "release", false)
		return true
	if tapping(c, i, st):
		return false
	var pl = c.p(i)
	var em = c.e(i)
	var side := -1 if i == 1 else 1        # de qué lado del pájaro se para
	var safe := 380.0 if i == 1 else 900.0  # lejos del foso
	var step: Dictionary = b.step
	var kind: String = step.get("do", "")
	var px: float = pl.global_position.x
	var attack: bool = (kind == "swoop" or kind == "gust") and b.state in [B_TELEGRAPH, B_SWOOP, B_GUST]
	if attack and not c.vars.has("nododge"):
		if em._throw_state == T_AIMING:
			tap(c, i, st, "release")  # apuntando no se puede saltar ni caminar
			return false
		if kind == "swoop":
			walk_toward(c, i, safe, 20.0)
			var dir: int = b._swoop_dir
			var ahead: float = (px - b.position.x) * dir
			if b.state == B_SWOOP and ahead > 0.0 and ahead < 330.0 and pl.is_on_floor():
				walk(c, i, 0)
				tap(c, i, st, "jump")
		else:
			walk_toward(c, i, safe, 12.0)
		return false
	# Planea (o va a planear): a tiro y a lanzar.
	var hover: bool = b.state == B_HOVER or (b.state == B_MOVE and kind == "hover") or b.state == B_HURT
	if not hover:
		walk_toward(c, i, safe, 20.0)
		throw_cycle(c, i, st, null, false)
		return false
	var spot: float = clampf(b.position.x + side * 220.0, 280.0, 520.0) if i == 1 \
		else clampf(b.position.x + side * 220.0, 760.0, 1000.0)
	var there := true
	if em._throw_state != T_AIMING:
		there = walk_toward(c, i, spot, 25.0)
	else:
		walk(c, i, 0)
	var target: Vector2 = b.position + Vector2(0, -6)
	var ok: bool = b.state == B_HOVER and there and reach(c, i, target) < 300.0
	throw_cycle(c, i, st, target, ok)
	return false

## Toma el emboque en la mano (sea como sea que esté). Termina al tenerlo.
static func hold_tick(c, i: int, st: Dictionary) -> bool:
	if tapping(c, i, st):
		return false
	var em = c.e(i)
	match em._throw_state:
		T_HELD:
			return true
		T_AIMING:
			tap(c, i, st, "release")
		T_NONE, T_FLYING:
			tap(c, i, st, "throw")
	return false

static func hold_end(i: int) -> Array:
	var st := {}
	return [["until", func(c): return hold_tick(c, i, st), 4.0]]

# --- Subida ---

## Rectángulo de un bloque del nivel (Rect2 en el mundo).
static func rect_of(c, name: String) -> Rect2:
	var n = c.level.get_node(name)
	var sz: Vector2 = n.size
	return Rect2(n.global_position - sz * 0.5, sz)

## El recorrido de [param i] en orden: islas, torres (con su gancho) y la repisa de la
## cima. Cada elemento: {rect, safe_x0, safe_x1, tower (gancho o null)}.
static func route(c, i: int) -> Array:
	var p := "L" if i == 1 else "R"
	var out: Array = []
	var k := 1
	while c.level.has_node("%s%d" % [p, k]):
		var r := rect_of(c, "%s%d" % [p, k])
		var item := {"rect": r, "x0": r.position.x, "x1": r.end.x, "tower": null, "name": "%s%d" % [p, k], "spikes": 0}
		var sp = c.level.get_node_or_null("Spikes%s%d" % [p, k])
		if sp != null:
			var w: float = 100.0 * sp.scale.x
			if sp.global_position.x < r.get_center().x:
				item.x0 = sp.global_position.x + w * 0.5
				item.spikes = -1
			else:
				item.x1 = sp.global_position.x - w * 0.5
				item.spikes = 1
		out.append(item)
		k += 1
	# Cada torre va después de la isla desde la que se lanza (TOWER px más abajo).
	for t in [2, 1]:
		var tn := "%sT%d" % [p, t]
		var tr := rect_of(c, tn)
		for j in out.size():
			if out[j].tower == null and absf(out[j].rect.position.y - (tr.position.y + TOWER)) < 2.0:
				out[j]["throw"] = c.level.get_node(tn + "Hook").global_position
				out.insert(j + 1, {"rect": tr, "x0": tr.position.x, "x1": tr.end.x, "tower": true, "name": tn, "spikes": 0})
				break
	var sr := rect_of(c, "SummitLeft" if i == 1 else "SummitRight")
	out.append({"rect": sr, "x0": sr.position.x, "x1": sr.end.x, "tower": null, "name": "Summit", "spikes": 0})
	return out

## Índice de la plataforma en la que está parado (-1 = el piso de la arena u otra).
static func standing_on(c, i: int, rt: Array) -> int:
	var pl = c.p(i)
	var feet: float = pl.global_position.y + 32.0
	for k in rt.size():
		var r: Rect2 = rt[k].rect
		if absf(feet - r.position.y) < 4.0 and pl.global_position.x > r.position.x - 18.0 and pl.global_position.x < r.end.x + 18.0:
			return k
	return -1

## El Tue Tue va a caer (o está cayendo) en picada sobre [param i].
static func peck_on_me(c, i: int) -> bool:
	var b := boss(c)
	if b.mode != M_FOLLOW or b.step.get("do", "") != "peck" or b._peck_target != c.p(i):
		return false
	return b.state == B_TELEGRAPH or (b.state == B_PECK and b.position.y < c.p(i).global_position.y)

static func gust_now(c) -> bool:
	var b := boss(c)
	return b.mode == M_FOLLOW and b.step.get("do", "") == "gust" and b.state in [B_TELEGRAPH, B_GUST]

## Dónde puede quedar parado (el centro) en [param it] sin tocar púas, como Rect2.
static func safe_rect(it: Dictionary) -> Rect2:
	var lo: float = float(it.x0) + (21.0 if int(it.get("spikes", 0)) < 0 else 0.0)
	var hi: float = float(it.x1) - (21.0 if int(it.get("spikes", 0)) > 0 else 0.0)
	return Rect2(lo, it.rect.position.y, hi - lo, it.rect.size.y)

## Al medio de donde puede quedar parado en [param it] sin tocar púas.
static func safe_mid(it: Dictionary) -> float:
	var lo: float = float(it.x0) + (21.0 if int(it.get("spikes", 0)) < 0 else 0.0)
	var hi: float = float(it.x1) - (21.0 if int(it.get("spikes", 0)) > 0 else 0.0)
	return (lo + hi) * 0.5

## Isla con púas en el borde de llegada: hasta qué x no frena en el aire.
static func set_clear(st: Dictionary, to: Dictionary, d: int) -> void:
	st.dir = d
	if int(to.spikes) == -d:
		st.clear = float(to.x0) + 22.0 if d > 0 else float(to.x1) - 22.0
	else:
		st.erase("clear")

## Esperando en una isla angosta con la picada encima: mientras lo sigue se para en
## un borde (ahí fija la línea) y después corre al otro. True si se encargó.
static func dodge_on_island(c, i: int, cur: Dictionary) -> bool:
	if not peck_on_me(c, i) or not cur.has("rect"):
		return false
	var b := boss(c)
	var pl = c.p(i)
	var r := safe_rect(cur)
	var locked: bool = b.state == B_PECK or b._t >= b.peck_track_time
	var x: float = r.position.x + 4.0 if not locked else escape_x(pl.global_position.x, b._peck_x, r)
	c._walk_to(who(i), pl, x, 3.0, 0.0)
	return true

## Adónde correrse en la repisa [param r] para que no le caiga la picada en [param line]:
## al borde de su lado de la línea si alcanza a quedar a 70 px; si no, al otro.
static func escape_x(px: float, line: float, r: Rect2) -> float:
	var right := r.end.x - 4.0
	var left := r.position.x + 4.0
	if px >= line:
		return right if right - line >= 70.0 else left
	return left if line - left >= 70.0 else right

## ¿Se puede lanzar al gancho ahora? (nada le cae encima ni sopla mientras apunta y sube)
static func tower_safe(c, i: int) -> bool:
	var b := boss(c)
	if b.mode != M_FOLLOW or b.state == B_STUNNED:
		return true
	var pat: Array = b.CLIMB_PATTERN
	var nxt: Dictionary = pat[(b._climb_i + 1) % pat.size()]
	var mine := func(s: Dictionary) -> bool: return s.do == "peck" and int(s.who) == i - 1
	if b.state == 7:  # ORBIT: descansando (el próximo ataque tarda ~3 s en llegar)
		return not mine.call(nxt)
	if b.step.get("do", "") == "gust" or mine.call(b.step):
		return false
	return true

## La subida, un tick. Termina cuando empieza la cima (el Tue Tue acosa) y él está
## en su repisa.
static func climb_tick(c, i: int, st: Dictionary) -> bool:
	var b := boss(c)
	var pl = c.p(i)
	var em = c.e(i)
	var who_s := who(i)
	if not st.has("rt"):
		st.rt = route(c, i)
		st.mode = "idle"
	var rt: Array = st.rt
	var on: int = standing_on(c, i, rt) if pl.is_on_floor() else -2
	if c.vars.has("dbg") and (fmod(c.time, 0.5) < 0.009 or c.vars.get("dbg") == "all" or (c.vars.get("dbg") == "win" and c.time > float(c.vars.get("from", 0)) and c.time < float(c.vars.get("to", 0)))):
		print("p%d t=%.2f v=(%.0f,%.0f) jumpkey=%s pos=(%.0f,%.0f) on=%d mode=%s throw=%d hook=%s stun=%s | boss m=%d s=%d t=%.2f step=%s | cam=%.0f safe=%s" % [i, c.time,
			pl.velocity.x, pl.velocity.y, Input.is_action_pressed(who_s + "_jump"), pl.global_position.x, pl.global_position.y, on, st.mode, em._throw_state, c.hooked(i), pl.is_stunned(),
			b.mode, b.state, b._t, b.step, c.level.get_node("Camera2D").global_position.y, tower_safe(c, i)])
	if b.mode == M_HARASS and on == rt.size() - 1:
		walk(c, i, 0)
		return true
	if tapping(c, i, st):
		return false
	if pl.is_stunned():
		st.mode = "idle"
		return false
	# En el aire: sigue el salto (o la cuerda).
	if st.mode == "air":
		var tgt_air: float = st.target
		if peck_on_me(c, i) and (b.state == B_PECK or b._t >= b.peck_track_time) and st.has("land"):
			# Ya fijó dónde cae: aterrizar lejos de la línea.
			var lr: Rect2 = st.land
			tgt_air = clampf(escape_x(tgt_air, b._peck_x, lr), lr.position.x + 4.0, lr.end.x - 4.0)
		if st.has("clear") and (pl.global_position.x - float(st.clear)) * int(st.dir) < 0.0:
			# Púas en el borde de llegada: sin frenar hasta pasarlas.
			walk(c, i, int(st.dir))
		else:
			c._walk_to(who_s, pl, tgt_air, 4.0, 0.0)
		if pl.is_on_floor() and c.time - st.since > 0.1:
			walk(c, i, 0)
			st.mode = "idle"
			st.run = false
		return false
	if st.mode.begins_with("t_") and st.mode != "t_walk" and st.mode != "t_wait":
		return tower_tick(c, i, st)
	if on == -2:
		return false
	# Ráfaga: se queda donde está caminando en contra.
	if gust_now(c):
		if not st.has("hold_x"):
			# Al medio de donde se puede parar (lejos de las púas y de los bordes).
			st.hold_x = safe_mid(rt[on]) if on >= 0 and not rt[on].has("throw") else pl.global_position.x
		if em._throw_state == T_AIMING:
			tap(c, i, st, "release")
			return false
		c._walk_to(who_s, pl, st.hold_x, 3.0, 0.0)
		st.mode = "idle"
		st.run = false
		return false
	st.erase("hold_x")
	# El emboque en la mano (sin cuerda colgando que se trabe en las islas).
	if em._throw_state != T_HELD and not st.mode.begins_with("t_"):
		walk(c, i, 0)
		hold_tick(c, i, st)
		return false
	var nxt := on + 1
	if nxt >= rt.size():
		# En la cima antes que la cámara: esquiva la picada corriéndose por la repisa.
		var r: Rect2 = rt[on].rect
		var home: float = r.get_center().x
		if peck_on_me(c, i):
			home = r.position.x + 30.0 if b._peck_x > r.get_center().x else r.end.x - 30.0
		walk_toward(c, i, home, 8.0)
		return false
	var cur: Dictionary = rt[on] if on >= 0 else {"x0": 140.0, "x1": 1140.0}
	if cur.has("throw"):
		return tower_tick(c, i, st)
	var to: Dictionary = rt[nxt]
	var tgt: float = safe_mid(to)
	var px: float = pl.global_position.x
	var d := 1 if tgt > px else -1
	var take: float = float(cur.x1) - 30.0 if d > 0 else float(cur.x0) + 30.0
	var spikes_ahead: bool = int(cur.get("spikes", 0)) == d
	if spikes_ahead:
		# Sale por encima de las púas de su propia isla: despega más atrás.
		take = float(cur.x0) + 54.0 if d < 0 else float(cur.x1) - 54.0
	elif int(to.spikes) == -d:
		# Púas en el borde de llegada: despega antes (pasa sobre ellas en lo alto del salto).
		take = clampf(float(cur.x1) - 62.0 if d > 0 else float(cur.x0) + 62.0, float(cur.x0) + 27.0, float(cur.x1) - 27.0)
	if on < 0:
		take = tgt - d * 150.0
	# Sin pisar las púas de su isla (el cuerpo mide 40 px).
	var lo: float = float(cur.x0) + (26.0 if int(cur.get("spikes", 0)) < 0 else 2.0)
	var hi: float = float(cur.x1) - (26.0 if int(cur.get("spikes", 0)) > 0 else 2.0)
	var start := clampf(take - 25.0 * d, lo, hi)
	if (take - start) * d < 15.0:
		# Isla angosta (o con púas atrás): la carrera parte del borde seguro.
		take = start + 15.0 * d
	# Llegó tarde a la cima (ya empezó el acoso): salta solo mientras da una vuelta;
	# espera donde empieza la carrera.
	if b.mode == M_HARASS and not (b.state == 7 and b._t < 0.9) and not st.get("run", false):
		c._walk_to(who_s, pl, start, 3.0, 0.0)
		return false
	# No subir pegado al borde de arriba de la pantalla (ahí hay techo y vuela el Tue
	# Tue): espera a que suba la cámara.
	var top: float = c.level.get_node("Camera2D").global_position.y - 360.0
	if b.mode == M_FOLLOW and to.rect.position.y < top + 200.0 and not st.get("run", false):
		if not dodge_on_island(c, i, cur):
			c._walk_to(who_s, pl, safe_mid(cur) if on >= 0 else pl.global_position.x, 3.0, 0.0)
		return false
	if peck_on_me(c, i) and not st.get("run", false):
		var locked: bool = b.state == B_PECK or b._t >= b.peck_track_time
		if not locked or absf(px - b._peck_x) >= 75.0:
			# Lo sigue: espera listo para correr (que fije la línea ahí y salir).
			c._walk_to(who_s, pl, start, 3.0, 0.0)
			return false
		st.run = true  # ya fijó la línea: carrera y salto a la isla siguiente
	# Carrera corta: se para en start (25 px antes del despegue), corre y salta al pasar.
	if st.get("run", false):
		walk(c, i, d)
		if (px - take) * d >= 0.0 and pl.velocity.x * d < 50.0:
			st.run = false  # pasó el despegue sin carrera: otra vez desde el comienzo
		elif (px - take) * d >= 0.0:
			st.run = false
			tap(c, i, st, "jump")
			st.mode = "air"
			st.target = tgt
			st.land = safe_rect(to)
			set_clear(st, to, d)
			st.since = c.time
	elif c._walk_to(who_s, pl, start, 3.0, 0.0):
		st.run = true
	return false

## Torre: se para a THROW_DX del gancho, espera un momento seguro, lanza el emboque al
## gancho, trepa la cuerda al mínimo y salta arriba de la torre.
static func tower_tick(c, i: int, st: Dictionary) -> bool:
	var pl = c.p(i)
	var em = c.e(i)
	var rt: Array = st.rt
	if not st.mode.begins_with("t_"):
		st.mode = "t_walk"
		var k: int = standing_on(c, i, rt)
		st.hook = rt[k].throw
		st.tdir = 1 if st.hook.x > pl.global_position.x else -1
	var hook: Vector2 = st.hook
	var d: int = st.tdir
	match st.mode:
		"t_walk":
			var b := boss(c)
			# Tras la picada sube por la misma línea: no volver hasta que pase.
			var rising: bool = b.mode == M_FOLLOW and absf(b.position.x - st.get("peck_x", -999.0)) < 2.0 \
				and b.position.y > pl.global_position.y - 170.0
			if peck_on_me(c, i):
				st.peck_x = b._peck_x
			var k: int = standing_on(c, i, rt)
			var r: Rect2 = rt[k].rect if k >= 0 else Rect2(pl.global_position, Vector2.ZERO)
			var locked: bool = peck_on_me(c, i) and (b.state == B_PECK or b._t >= b.peck_track_time)
			if peck_on_me(c, i) and not locked:
				# Lo está siguiendo: se para cerca de un borde (que fije la línea ahí)…
				walk_toward(c, i, r.position.x + 22.0, 3.0)
				return false
			if locked or rising:
				# …y después corre al otro extremo de la repisa.
				walk_toward(c, i, escape_x(pl.global_position.x, st.get("peck_x", b._peck_x), r), 3.0)
				return false
			var there: bool = c._walk_to(who(i), pl, hook.x - d * THROW_DX, 3.0, 0.0)
			if em._throw_state != T_HELD:
				hold_tick(c, i, st)
			elif there and absf(pl.velocity.x) < 10.0 and tower_safe(c, i):
				st.mode = "t_aim"
				st.since = c.time
		"t_aim":
			walk(c, i, 0)
			match em._throw_state:
				T_HELD:
					if pl.facing != d:
						tap(c, i, st, "right" if d > 0 else "left")
					else:
						tap(c, i, st, "throw")
				T_AIMING:
					var want := aim_angle(c, i, hook)
					var a: float = pingpong(em._aim_time * em.aim_sweep_speed_deg, em.aim_max_angle_deg)
					if absf(a - want) < 1.0:
						tap(c, i, st, "throw")
						st.mode = "t_fly"
						st.since = c.time
				_:
					st.mode = "t_walk"
		"t_fly":
			if c.hooked(i):
				st.mode = "t_pull"
				st.since = c.time
			elif c.time - st.since > 1.5:
				st.mode = "t_walk"  # erró: lo recoge y otra vez
		"t_pull":
			c._act(who(i), "pull", em.rope_length > 61.0)
			if em.rope_length <= 61.0:
				c._act(who(i), "pull", false)
				if c.time - st.since > 0.4:
					st.mode = "t_jump"
			else:
				st.since = c.time
			if not c.hooked(i):
				c._act(who(i), "pull", false)
				st.mode = "idle"
		"t_jump":
			walk(c, i, d)
			tap(c, i, st, "jump")
			st.mode = "air"
			st.target = hook.x + d * 60.0
			st.erase("land")
			st.erase("clear")
			st.since = c.time
	return false

static func climb(i: int) -> Array:
	var st := {}
	return [["until", func(c): return climb_tick(c, i, st), 120.0]]

## Cima, un tick: en su lugar ([param home], lejos de la cortina, bajo la que cae en
## picada), salta las picadas y camina contra las ráfagas; con [param throw] además
## le lanza el emboque cuando está a tiro y de su lado de la cortina (dando vueltas o
## avisando la caída). True cuando el Tue Tue queda mareado.
static func summit_tick(c, i: int, st: Dictionary, home: float, throw: bool) -> bool:
	var b := boss(c)
	if c.vars.has("dbg") and (c.vars.get("dbg") == "all" or (c.vars.get("dbg") == "win" and c.time > float(c.vars.get("from", 0)) and c.time < float(c.vars.get("to", 0)))):
		print("s%d t=%.2f pos=(%.0f,%.0f) v=(%.0f,%.0f) stun=%s | boss s=%d t=%.2f pos=(%.0f,%.0f) step=%s" % [i, c.time, c.p(i).global_position.x, c.p(i).global_position.y,
			c.p(i).velocity.x, c.p(i).velocity.y, c.p(i).is_stunned(), b.state, b._t, b.position.x, b.position.y, b.step])
	if b.state == B_STUNNED or c.won():
		walk(c, i, 0)
		return true
	if tapping(c, i, st):
		return false
	var pl = c.p(i)
	var em = c.e(i)
	var kind: String = b.step.get("do", "")
	var attack: bool = (kind == "swoop" or kind == "gust") and b.state in [B_TELEGRAPH, B_SWOOP, B_GUST]
	if attack and not c.vars.has("nododge"):
		if em._throw_state == T_AIMING:
			tap(c, i, st, "release")
			return false
		if kind == "swoop":
			walk_toward(c, i, home, 15.0)
			var ahead: float = (pl.global_position.x - b.position.x) * b._swoop_dir
			if b.state == B_SWOOP and ahead > 0.0 and ahead < 330.0 and pl.is_on_floor():
				walk(c, i, 0)
				tap(c, i, st, "jump")
		else:
			walk_toward(c, i, home, 10.0)
		return false
	if em._throw_state != T_AIMING:
		walk_toward(c, i, home, 15.0)
	else:
		walk(c, i, 0)
	if throw and em._throw_state == T_NONE and em.get_end_position().y > pl.global_position.y + 60.0:
		# El extremo quedó colgando bajo la repisa (lanzamiento errado): al borde del
		# hueco para recogerlo sin que se trabe contra la repisa.
		var edge: float = CURTAIN_L - 21.0 if i == 1 else CURTAIN_R + 21.0
		if not walk_toward(c, i, edge, 5.0):
			return false
	if throw:
		var target: Vector2 = b.position + Vector2(0, -6)
		var own_side: bool = target.x < CURTAIN_L - 10.0 if i == 1 else target.x > CURTAIN_R + 10.0
		var ok: bool = (b.state == B_ORBIT or (kind == "dive" and b.state in [B_MOVE, B_TELEGRAPH])) \
			and own_side and pl.is_on_floor() and reach(c, i, target) < 300.0
		throw_cycle(c, i, st, target, ok)
	return false

static func guard(i: int, home: float, throw: bool) -> Array:
	var st := {}
	return [["until", func(c): return summit_tick(c, i, st, home, throw), 40.0]]

## Balancea el extremo mientras el Tue Tue sigue mareado: va y vuelve entre home y
## home - back al RITMO del péndulo (un tramo por medio período, según el largo de
## la cuerda; como el paso "swing" del bot del equipo). Con los dos sincronizados
## (sync antes) los extremos se juntan bajo la cortina. Si el Tue Tue se despierta
## antes de embocar, deja de hacerlo (el siguiente intento lo esquiva).
static func jiggle_stunned(i: int, home: float, back: float) -> Array:
	var st := {}
	return [["until", func(c):
		if c.won() or boss(c).state != B_STUNNED:
			walk(c, i, 0)
			return true
		if not st.has("leg"):
			st.leg = 0
			st.start = c.time
		walk_toward(c, i, home - back if st.leg % 2 == 0 else home, 4.0)
		var half: float = PI * sqrt(c.e(i).rope_length / 980.0)
		if c.time - st.start >= half:
			st.start += half
			st.leg += 1
		return false, 10.0]]

## Recoge el extremo a la mano, camina hasta la cortina (que lo frena con la mano
## más allá del borde de su repisa), lo suelta (cuelga libre sobre el vacío) y le da
## el largo para que quede a la altura del otro.
static func drop(i: int, ctx) -> Array:
	var d := 1 if i == 1 else -1
	return hold_end(i) + [["press", "right" if d > 0 else "left"], ["wait", 0.35],
		["until", func(c): return absf(c.p(i).get_real_velocity().x) < 5.0, 1.5],
		["release", "right" if d > 0 else "left"], ["tap", "release"], ["wait", 0.3],
		["rope", ctx.var_f("r%d" % i, 120)], ["wait", 0.3]]

## Un intento en la cima: esperan cada uno en su repisa esquivando y pegándole
## cuando pasa por su lado (queda mareado), cuelgan los extremos junto a la cortina y
## los balancean mientras dura el mareo. Si se despierta antes, otro intento.
static func attempt(n: int, ctx) -> Dictionary:
	var t := "_%d" % n
	var sw: float = ctx.var_f("swing", 40)
	if ctx.vars.has("nostun"):
		# Control: sin marearlo, cuelgan los extremos apenas termina un ataque.
		var calm := func(c): return boss(c).state == B_ORBIT
		return {"p1": [["until", calm, 10.0]] + drop(1, ctx) + [["sync", "uno" + t], ["jiggle", CURTAIN_L - 20.0, sw, 6], ["sync", "fin" + t]],
			"p2": [["until", calm, 10.0]] + drop(2, ctx) + [["sync", "uno" + t], ["jiggle", CURTAIN_R + 20.0, -sw, 6], ["sync", "fin" + t]]}
	return {"p1": guard(1, 540.0, true) + [["sync", "mareado" + t]] + drop(1, ctx) \
			+ [["sync", "uno" + t]] + jiggle_stunned(1, CURTAIN_L - 20.0, sw) + [["sync", "fin" + t]],
		"p2": guard(2, 740.0, true) + [["sync", "mareado" + t]] + drop(2, ctx) \
			+ [["sync", "uno" + t]] + jiggle_stunned(2, CURTAIN_R + 20.0, -sw) + [["sync", "fin" + t]]}

static func fight(i: int) -> Array:
	var st := {}
	return [["until", func(c): return fight_tick(c, i, st), 150.0]]

static func plan(ctx) -> Dictionary:
	var start: String = ctx.vars.get("start", "")
	if ctx.vars.has("idle"):
		var go: Array = [] if start == "" else [["do", func(c): c.level.get_node("BossFight").debug_start(3 if start == "climb" else 4)]]
		return {"p1": go + [["wait", 120.0]], "p2": [["wait", 120.0]]}
	var p1: Array = []
	var p2: Array = []
	if start == "":
		p1 += fight(1)
		p2 += fight(2)
	if start == "" or start == "climb":
		if start == "climb":
			p1 += [["do", func(c): c.level.get_node("BossFight").debug_start(3)]]
		p1 += [["wait", 0.5]] + climb(1)
		p2 += [["wait", 0.5]] + climb(2)
	else:
		p1 += [["do", func(c): c.level.get_node("BossFight").debug_start(4)], ["wait_floor"]]
		p2 += [["wait_floor"]]
	if ctx.vars.has("guardonly"):
		# Prueba: solo esquivar en la cima (sin marearlo) durante 40 s.
		return {"p1": p1 + guard(1, 540.0, false), "p2": p2 + guard(2, 740.0, false)}
	for n in 6:
		var a := attempt(n, ctx)
		p1 += a.p1
		p2 += a.p2
	return {"p1": p1, "p2": p2}
