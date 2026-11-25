extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--no=wind --goal=480,488,1120,488", "--remove=Wind2Left,Wind2Right --start=480,440,1120,440 --goal=655,208,945,208", "--remove=GustLeft,GustRight --start=655,160,945,160", "--start=655,160,945,160 --goal=945,208,655,208"]
const SCENE := "res://scenes/levels/viento_4.tscn"
## Viento 4 "Remonte": el gancho está demasiado alto. Cada uno se para justo debajo, dentro de
## la corriente (al jugador no lo empuja), y suelta cuerda: el viento sube el extremo hasta el
## gancho. Trepa tirando de la cuerda, se columpia y salta a la repisa; ahí, otra vez. En la
## meta el hueco es demasiado ancho para balancearse solos: dos vientos soplan en ráfagas hacia
## adentro y hay que sumarles el balanceo, al ritmo.
static func lift(i: int, d: int, hook_x: float, land: float) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1600.0 - v
	var dir := "right" if d == 1 else "left"
	return [["walk_to", x.call(hook_x), 3], ["wait", 0.8], ["press", "release"], ["until", func(c): return c.hooked(i), 5.0], ["release", "release"],
		["rope", 60, 2], ["wait", 0.8], ["tap", "jump"], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(land)) * d > 0.0 or c.p(i).is_on_floor(), 3.0],
		["release", dir], ["wait_floor"], ["wait", 0.4]]

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1600.0 - v
	return [["wait_floor"], ["rope", 60]] + lift(i, d, 320, 460) \
		+ [["rope", 60]] + lift(i, d, 500, 640) \
		+ [["rope", 60, 2], ["hang", x.call(724)], ["rope", ctx.var_f("r", 190)], ["wait", 0.5], ["sync", "listos"], ["swing", x.call(724), ctx.var_f("m", 50) * d, 30]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
