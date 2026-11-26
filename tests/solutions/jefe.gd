extends RefCounted
const SCENE := "res://scenes/levels/jefe.tscn"
## El Tue Tue (jefe final), en sus tres fases:
## 1. Pelea: cada uno se para a tiro del Tue Tue (a ~220 px de él, de su lado) y,
##    mientras planea, recoge el emboque a la mano, apunta y lo lanza cuando la mira
##    pasa por el ángulo que lo apunta. Cuando avisa una PICADA suelta lo que
##    apuntaba y salta al pasar el pájaro; en una RÁFAGA camina en contra para no
##    terminar en el foso de púas.
## 2. Subida: con el emboque en la mano (sin cuerda que lo amarre a los escalones)
##    sube el zigzag de su lado.
## 3. Cima: cada uno espera en su repisa (lejos de la cortina, bajo la que cae en
##    picada) saltando las picadas y caminando contra las ráfagas, y le lanza el
##    emboque cuando el Tue Tue pasa por su lado (la cortina tapa el otro) hasta
##    marearlo; mareado, cada uno se pega a la cortina, deja colgar su extremo sobre
##    el vacío y lo balancea hasta embocar. Si se despierta antes, otro intento.
## --var=r1=…/r2=… largo de la cuerda al colgar el extremo (120); --var=swing=…
## cuánto va y vuelve para balancearlo (40).
## --var=start=climb|summit empieza directo en esa fase (para probarlas aparte).
## Controles: --var=idle=1 (nadie hace nada: el Tue Tue los tira al foso),
## --var=nostun=1 (en la cima no lo marean: los desparrama antes de embocar) y
## --var=nododge=1 (en la pelea no esquivan picadas ni ráfagas: terminan en el foso).
const C := preload("res://tests/solutions/caja_2.gd")

# Estados del Tue Tue (TueTue.State / Mode) y del lanzamiento (Emboque.ThrowState).
const B_MOVE := 1
const B_HOVER := 2
const B_TELEGRAPH := 3
const B_SWOOP := 4
const B_GUST := 5
const B_HURT := 6
const B_ORBIT := 7
const B_STUNNED := 9
const M_IDLE := 0
const M_FIGHT := 1
const T_NONE := 0
const T_HELD := 1
const T_AIMING := 2
const T_FLYING := 3
const T_REELING := 4

const RISE := 120.0
## Cortina de la cima (x de sus bordes): frena a cada uno junto al hueco.
const CURTAIN_L := 606.0
const CURTAIN_R := 674.0
const FIRST := 500.0
const STEPS := 14

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
			if b.state == B_SWOOP and ahead > 0.0 and ahead < 190.0 and pl.is_on_floor():
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

## La subida: del piso de la arena al primer escalón (afuera) y zigzag hasta la cima.
static func climb(i: int, ctx) -> Array:
	var s := 1 if i == 1 else -1
	var x := func(v: float) -> float: return v if i == 1 else 1280.0 - v
	var out: Array = hold_end(i) + [["walk_to", x.call(222), 2]]
	out += C.climb_box(i, -s, x, 222, 150, FIRST - 40.0)
	for k in range(1, STEPS):
		var top := FIRST - RISE * k
		if k % 2 == 1:
			out += C.climb_box(i, s, x, 185, 275, top - 40.0)   # afuera → adentro
		else:
			out += C.climb_box(i, -s, x, 255, 165, top - 40.0)  # adentro → afuera
	var summit := FIRST - RISE * STEPS
	out += C.climb_box(i, s, x, 385, 480, summit - 40.0)
	return out

## Cima, un tick: en su lugar ([param home], lejos de la cortina, bajo la que cae en
## picada), salta las picadas y camina contra las ráfagas; con [param throw] además
## le lanza el emboque cuando está a tiro y de su lado de la cortina (dando vueltas o
## avisando la caída). True cuando el Tue Tue queda mareado.
static func summit_tick(c, i: int, st: Dictionary, home: float, throw: bool) -> bool:
	var b := boss(c)
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
			if b.state == B_SWOOP and ahead > 0.0 and ahead < 190.0 and pl.is_on_floor():
				walk(c, i, 0)
				tap(c, i, st, "jump")
		else:
			walk_toward(c, i, home, 10.0)
		return false
	if em._throw_state != T_AIMING:
		walk_toward(c, i, home, 15.0)
	else:
		walk(c, i, 0)
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
	if ctx.vars.has("idle"):
		return {"p1": [["wait", 120.0]], "p2": [["wait", 120.0]]}
	var start: String = ctx.vars.get("start", "")
	var p1: Array = []
	var p2: Array = []
	if start == "":
		p1 += fight(1)
		p2 += fight(2)
	if start == "" or start == "climb":
		if start == "climb":
			p1 += [["do", func(c): c.level.get_node("BossFight").debug_start(3)]]
		p1 += [["wait", 0.5]] + climb(1, ctx)
		p2 += [["wait", 0.5]] + climb(2, ctx)
	else:
		p1 += [["do", func(c): c.level.get_node("BossFight").debug_start(4)], ["wait_floor"]]
		p2 += [["wait_floor"]]
	for n in 6:
		var a := attempt(n, ctx)
		p1 += a.p1
		p2 += a.p2
	return {"p1": p1, "p2": p2}
