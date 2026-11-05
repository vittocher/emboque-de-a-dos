extends RefCounted
const SCENE := "res://scenes/levels/caja_2.tscn"
## Caja 2: dos escalones de 200 px. Empujar la primera caja contra el primer
## escalón, subir; empujar la segunda caja (que está arriba) contra el segundo
## escalón, acortar la cuerda (el extremo colgando por el borde frena el salto)
## y subir. Los extremos bajan por el pozo del medio.
static func climb_box(i: int, d: int, x: Callable, stand: float, land: float, top_y: float) -> Array:
	var dir := "right" if d == 1 else "left"
	return [["walk_to", x.call(stand)], ["wait", 0.4], ["tap", "jump"],
		["until", func(c): return c.p(i).global_position.y < top_y, 1.0], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(land)) * d > 0.0, 1.5], ["release", dir],
		["wait_floor"]]

static func push_until_stuck(i: int, d: int) -> Array:
	var dir := "right" if d == 1 else "left"
	return [["press", dir], ["wait", 0.3],
		["until", func(c): return absf(c.p(i).get_real_velocity().x) < 5.0, 6.0], ["release", dir], ["wait", 0.3]]

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	return [["wait_floor"]] + push_until_stuck(i, d) + climb_box(i, d, x, 165, 262, 470) \
		+ climb_box(i, d, x, 220, 290, 360) + [["rope", 60]] + push_until_stuck(i, d) \
		+ climb_box(i, d, x, 330, 392, 340) + climb_box(i, d, x, 410, 458, 175) \
		+ [["walk_to", x.call(628), 3], ["wait", 0.5], ["rope", ctx.var_f("r", 200)],
		["sync", "listos"], ["jiggle", x.call(628), 10 * d, 10]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
