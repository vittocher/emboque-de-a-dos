extends RefCounted
const SCENE := "res://scenes/levels/final.tscn"
## Final: cada uno lanza su extremo al gancho bajo el techo, se columpia sobre el
## fuego (acortando para que el extremo no cuelgue al fuego) y salta a su isla
## frenando en el aire (no hay muro: el salto se pasa de largo al fuego).
## Desde el borde de la isla deja caer el extremo en la corriente del medio y
## suelta cuerda: el viento sube los dos extremos hasta el embudo de arriba.
const M := preload("res://tests/solutions/moves.gd")

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var dir := "right" if d == 1 else "left"
	return [["wait_floor"], ["walk_to", x.call(150), 3], ["wait", 0.5]] \
		+ M.throw_at(i, d, 38) \
		+ [["until", func(c): return c.hooked(i), 1.5], ["rope", 230, 3],
		["press", dir], ["until", func(c): return not c.p(i).is_on_floor(), 3.0], ["release", dir],
		["pump", 1.2], ["rope", 150, 4],
		["until", func(c): return c.p(i)._swing_omega * d < -0.3, 4.0],
		["until", func(c): return c.p(i)._swing_omega * d > 0.0 and (c.p(i).global_position.x - x.call(400)) * d > 0.0, 6.0],
		["tap", "jump"], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(ctx.var_f("brake", 470))) * d >= 0.0 or c.p(i).is_on_floor(), 3.0],
		["release", dir], ["press", "left" if d == 1 else "right"],
		["until", func(c): return c.p(i).is_on_floor() or c.p(i).velocity.x * d <= 0.0, 3.0],
		["release", "left" if d == 1 else "right"], ["wait_floor"], ["rope", 60], ["walk_to", x.call(ctx.var_f("stand", 616)), 3], ["wait", 0.6],
		["rope", ctx.var_f("r", 300)], ["sync", "listos"],
		["until", func(c): return c.won(), 8.0], ["jiggle", x.call(ctx.var_f("stand", 616)), 10 * d, 6]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
