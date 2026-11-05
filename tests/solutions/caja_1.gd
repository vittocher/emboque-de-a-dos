extends RefCounted
const SCENE := "res://scenes/levels/caja_1.tscn"
## Caja 1: la repisa es más alta que el salto. Cada uno empuja su caja contra
## la repisa, se sube a la caja y salta a la repisa; los dos bajan el extremo
## por el pozo angosto del medio, donde quedan encajonados juntos.
static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var dir := "right" if d == 1 else "left"
	return [["wait_floor"], ["press", dir],
		["until", func(c): return absf(c.p(i).get_real_velocity().x) < 5.0 and c.time > 2.0, 6.0], ["release", dir],
		["wait", 0.3], ["walk_to", x.call(225)], ["wait", 0.4],
		["tap", "jump"], ["until", func(c): return c.p(i).global_position.y < 470.0, 1.0], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(262)) * d > 0.0, 1.0], ["release", dir],
		["wait_floor"], ["wait", 0.4], ["tap", "jump"],
		["until", func(c): return c.p(i).global_position.y < 360.0, 1.2], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(360)) * d > 0.0, 1.5], ["release", dir],
		["wait_floor"], ["walk_to", x.call(ctx.var_f("stand", 628)), 3], ["wait", 0.5], ["rope", ctx.var_f("r", 200)],
		["sync", "listos"], ["jiggle", x.call(ctx.var_f("stand", 628)), 10 * d, 10]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
