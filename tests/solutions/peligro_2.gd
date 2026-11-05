extends RefCounted
const SCENE := "res://scenes/levels/peligro_2.tscn"
## Peligro 2: la caca mata al emboque. Quedarse quieto en un borde con la cuerda
## normal hunde el extremo en la caca. Cada uno, desde el borde de la repisa A,
## baja el extremo con precisión por la sopaipilla del foso, ACORTA, salta el
## foso, va al borde junto al muro y baja el extremo al cuenco sobre la caca.
const M := preload("res://tests/solutions/moves.gd")

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var dir := "right" if d == 1 else "left"
	return [["wait_floor"], ["rope", 80], ["walk_to", x.call(278), 3], ["wait", 0.6], ["rope", ctx.var_f("deep", 120)],
		["wait", 0.8], ["rope", ctx.var_f("short", 80)], ["walk_to", x.call(150)], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(240)) * d > 0.0, 2.0], ["tap", "jump"],
		["until", func(c): return c.p(i).is_on_floor() and (c.p(i).global_position.x - x.call(420)) * d > 0.0, 3.0],
		["release", dir], ["walk_to", x.call(606)], ["wait", 0.6], ["rope", ctx.var_f("r", 160)],
		["sync", "listos"]] + M.nudge(i, x.call(606), 12 * d, 12)

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
