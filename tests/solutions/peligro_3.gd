extends RefCounted
const SCENE := "res://scenes/levels/peligro_3.tscn"
## Peligro 3: brasas en el suelo y un escalón alto. El extremo va arrastrado
## detrás: si toca una brasa, se pierde. Hay que acortar para saltar cada brasa
## (el extremo salta pegado), pero el escalón de 175 px solo se sube con la
## cuerda larga: alargar quieto antes del escalón, subir, acortar otra vez antes
## de la segunda brasa; desde el borde, bajar el extremo al cuenco.
const M := preload("res://tests/solutions/moves.gd")

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var dir := "right" if d == 1 else "left"
	return [["wait_floor"], ["rope", 60], ["walk_to", x.call(70)], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(120)) * d > 0.0, 2.0], ["tap", "jump"],
		["until", func(c): return c.p(i).is_on_floor() and (c.p(i).global_position.x - x.call(250)) * d > 0.0, 2.0],
		["release", dir], ["walk_to", x.call(290)], ["wait", 0.4], ["rope", ctx.var_f("tall", 170)],
		["tap", "jump"], ["until", func(c): return c.p(i).global_position.y < 350.0, 1.0], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(350)) * d > 0.0, 1.5],
		["release", dir], ["wait_floor"], ["walk_to", x.call(365)], ["rope", 60], ["wait", 0.4], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(395)) * d > 0.0, 2.0], ["tap", "jump"],
		["until", func(c): return c.p(i).is_on_floor() and (c.p(i).global_position.x - x.call(510)) * d > 0.0, 2.0],
		["release", dir], ["walk_to", x.call(578)], ["wait", 0.6], ["rope", ctx.var_f("r", 180)],
		["sync", "listos"]] + M.nudge(i, x.call(578), 12 * d, 12)

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
