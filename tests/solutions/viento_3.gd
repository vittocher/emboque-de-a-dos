extends RefCounted
const SCENE := "res://scenes/levels/viento_3.tscn"
## Viento 3: la torre del encuentro mide 400 px; al lado, una corriente de aire
## sobre un foso de fuego. Cada uno se mete en la corriente (sube con ella), y
## arriba se mueve hacia la torre y aterriza; bajan los extremos por el pozo.
static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var dir := "right" if d == 1 else "left"
	return [["wait_floor"], ["rope", ctx.var_f("rope", 100)], ["walk_to", x.call(370), 6],
		["until", func(c): return c.p(i).global_position.y < ctx.var_f("top", 170.0), 6.0], ["press", dir],
		["until", func(c): return c.p(i).is_on_floor(), 4.0], ["release", dir],
		["walk_to", x.call(628), 3], ["wait", 0.5], ["rope", ctx.var_f("r", 140)],
		["sync", "listos"], ["jiggle", x.call(628), 8 * d, 10]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
