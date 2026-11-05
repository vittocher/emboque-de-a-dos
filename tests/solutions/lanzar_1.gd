extends RefCounted
const SCENE := "res://scenes/levels/lanzar_1.tscn"
## Lanzar 1: la torre no se alcanza saltando. Cada uno toma su extremo, lo lanza
## al gancho de su lado, sube tirando de la cuerda y salta arriba de la torre;
## bajan los extremos por el pozo de la torre.
const M := preload("res://tests/solutions/moves.gd")

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var dir := "right" if d == 1 else "left"
	return [["wait_floor"], ["walk_to", x.call(ctx.var_f("tx", 320)), 3], ["wait", 0.5]] \
		+ M.throw_at(i, d, ctx.var_f("deg", 55)) \
		+ [["until", func(c): return c.hooked(i), 1.5], ["rope", 60, 2], ["wait", 0.4],
		["tap", "jump"], ["press", dir], ["until", func(c): return c.p(i).is_on_floor() \
			and (c.p(i).global_position.x - x.call(530)) * d > 0.0, 3.0], ["release", dir],
		["walk_to", x.call(628), 3], ["wait", 0.5], ["rope", ctx.var_f("r", 120)],
		["sync", "listos"], ["jiggle", x.call(628), 8 * d, 10]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
