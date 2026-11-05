extends RefCounted
const SCENE := "res://scenes/levels/lanzar_3.tscn"
## Lanzar 3: el gancho cuelga bajo un techo macizo, sobre un foso de fuego; no
## se alcanza saltando (el techo corta el salto). Cada uno lanza su extremo al
## gancho, se baja del borde, se columpia sobre el fuego, acorta la cuerda (si
## no, al soltarse el extremo cuelga hasta el fuego) y salta a su isla.
## Bajan los extremos al cuenco entre las islas.
const M := preload("res://tests/solutions/moves.gd")

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var dir := "right" if d == 1 else "left"
	return [["wait_floor"], ["walk_to", x.call(ctx.var_f("tx", 150)), 3], ["wait", 0.5]] \
		+ M.throw_at(i, d, ctx.var_f("deg", 38)) \
		+ [["until", func(c): return c.hooked(i), 1.5], ["rope", ctx.var_f("swing_len", 230), 3],
		["press", dir], ["until", func(c): return not c.p(i).is_on_floor(), 3.0], ["release", dir],
		["pump", ctx.var_f("pump", 1.2)], ["rope", ctx.var_f("short", 150), 4],
		["until", func(c): return c.p(i)._swing_omega * d < -0.3, 4.0],
		["until", func(c): return c.p(i)._swing_omega * d > 0.0 and (c.p(i).global_position.x - x.call(ctx.var_f("rx", 400))) * d > 0.0, 6.0],
		["tap", "jump"], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(545)) * d >= 0.0 or c.p(i).is_on_floor(), 3.0],
		["release", dir], ["wait_floor"], ["walk_to", x.call(ctx.var_f("stand", 606)), 3], ["wait", 0.5],
		["rope", ctx.var_f("r", 120)], ["sync", "listos"], ["jiggle", x.call(ctx.var_f("stand", 606)), 8 * d, 10]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
