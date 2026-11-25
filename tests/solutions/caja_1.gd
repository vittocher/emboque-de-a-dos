extends RefCounted
const CONTROLS := ["12", "1", "2"]
const SHORTCUTS := ["--no=box --goal=450,318,830,318", "--start=480,250,800,250 --goal=800,318,480,318"]
const SCENE := "res://scenes/levels/caja_1.tscn"
## Caja 1: la repisa mide 250, más que cualquier salto. Cada uno empuja su caja GRANDE (120)
## contra la repisa, se sube a ella y salta a la repisa (todo con la cuerda retraída). Los
## extremos cuelgan sobre el fuego, con un muro entre los jugadores.
static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var dir := "right" if d == 1 else "left"
	return [["wait_floor"], ["rope", 60], ["press", dir],
		["until", func(c): return absf(c.p(i).get_real_velocity().x) < 5.0 and c.time > 2.0, 6.0], ["release", dir],
		["wait", 0.3], ["walk_to", x.call(180)], ["wait", 0.4],
		["tap", "jump"], ["until", func(c): return c.p(i).global_position.y < 450.0, 1.0], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(235)) * d > 0.0, 1.0], ["release", dir],
		["wait_floor"], ["walk_to", x.call(295)], ["wait", 0.4], ["tap", "jump"],
		["until", func(c): return c.p(i).global_position.y < 318.0, 1.2], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(360)) * d > 0.0, 1.5], ["release", dir],
		["wait_floor"], ["hang", x.call(594)], ["rope", ctx.var_f("r", 170)], ["wait", 0.8], ["sync", "listos"],
		["swing", x.call(594), ctx.var_f("m", 50) * d, 24]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
