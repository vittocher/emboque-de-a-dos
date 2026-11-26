extends RefCounted
const CONTROLS := ["12", "1", "2"]
const SHORTCUTS := ["--no=wind --goal=480,488,1120,488", "--remove=Wind2Left,Wind2Right --start=480,440,1120,440 --goal=655,208,945,208", "--remove=GustLeft,GustRight --start=655,160,945,160", "--start=655,160,945,160 --goal=945,208,655,208"]
const SCENE := "res://scenes/levels/viento_4.tscn"
## Viento 4 "Remonte": primero, cada uno abre la compuerta del OTRO con un botón del techo: se para
## en la corriente y suelta cuerda para que el extremo suba justo hasta él. Después, el gancho está demasiado alto. Cada uno se para justo debajo, dentro de
## la corriente (al jugador no lo empuja), y suelta cuerda: el viento sube el extremo hasta el
## gancho. Trepa tirando de la cuerda, se columpia y salta a la repisa; ahí, otra vez. En la
## meta el hueco es demasiado ancho para balancearse solos: dos vientos soplan en ráfagas hacia
## adentro y hay que sumarles el balanceo, al ritmo.
const V := preload("res://tests/solutions/viento_3.gd")

static func lift(i: int, d: int, hook_x: float, land: float) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1600.0 - v
	var dir := "right" if d == 1 else "left"
	return [["walk_to", x.call(hook_x), 3], ["wait", 2.4], ["press", "release"], ["until", func(c): return c.hooked(i), 5.0], ["release", "release"],
		["rope", 60, 2], ["wait", 0.8], ["tap", "jump"], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(land)) * d > 0.0 or c.p(i).is_on_floor(), 3.0],
		["release", dir], ["wait_floor"], ["wait", 0.4]]

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1600.0 - v
	return [["walk_to", x.call(250), 4], ["rope", 60]] + lift(i, d, 320, 460) \
		+ [["rope", 60]] + lift(i, d, 500, 630) \
		+ [["rope", 60, 2], ["hang", x.call(708)], ["rope", ctx.var_f("r", 190)], ["wait", 0.5], ["sync", "listos"]] + V.gust_starts("GustLeft") + [["wait", ctx.var_f("ph", 1.6)], ["swing", x.call(708), ctx.var_f("m", 50) * d, 30]]

static func plan(ctx) -> Dictionary:
	return {
		"p1": [["wait_floor"], ["rope", 60], ["walk_to", ctx.var_f("b1", 290), 3], ["wait", 0.5], ["rope", ctx.var_f("k1", 215)], ["until", func(c): return c.level.get_node("GateJ2").is_open, 3.0], ["rope", 60, 2], ["wait", 0.3],
			["until", func(c): return c.level.get_node("GateJ1").is_open, 20.0], ["wait", 1.0], ["walk_to", 40, 4], ["wait_floor"]] + side(1, 1, ctx),
		"p2": [["wait_floor"], ["rope", 60], ["walk_to", 1420, 4], ["wait_floor"], ["walk_to", ctx.var_f("b2", 1485), 3], ["wait", 0.5], ["rope", ctx.var_f("k2", 185)], ["until", func(c): return c.level.get_node("GateJ1").is_open, 3.0], ["rope", 60, 2], ["wait", 0.3],
			["walk_to", 1575, 4], ["wait_floor"], ["walk_to", 1430, 4], ["until", func(c): return c.level.get_node("GateJ2").is_open, 20.0], ["wait", 1.0]] + side(2, -1, ctx)}
