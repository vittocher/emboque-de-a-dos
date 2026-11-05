extends RefCounted
const SCENE := "res://scenes/levels/lanzar_2.tscn"
## Lanzar 2: dos lanzamientos. Desde el suelo, al gancho bajo; subir y saltar a
## la repisa del medio; desde ahí, al gancho alto; subir y saltar a la torre.
## Bajan los extremos por el pozo de la torre.
const M := preload("res://tests/solutions/moves.gd")

static func climb(i: int, d: int, x: Callable, land_x: float) -> Array:
	var dir := "right" if d == 1 else "left"
	return [["until", func(c): return c.hooked(i), 1.5], ["rope", 60, 2], ["wait", 0.4],
		["tap", "jump"], ["press", dir], ["until", func(c): return c.p(i).is_on_floor() \
			and (c.p(i).global_position.x - x.call(land_x)) * d > 0.0, 3.0], ["release", dir]]

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	return [["wait_floor"], ["walk_to", x.call(ctx.var_f("tx1", 130)), 3], ["wait", 0.5]] \
		+ M.throw_at(i, d, ctx.var_f("deg1", 48)) + climb(i, d, x, 340) \
		+ [["walk_to", x.call(ctx.var_f("tx2", 375)), 3], ["wait", 0.5]] \
		+ M.throw_at(i, d, ctx.var_f("deg2", 55)) + climb(i, d, x, 548) \
		+ [["walk_to", x.call(628), 3], ["wait", 0.5], ["rope", ctx.var_f("r", 120)],
		["sync", "listos"], ["jiggle", x.call(628), 8 * d, 10]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
