extends RefCounted
const CONTROLS := ["12", "1", "2"]
const SHORTCUTS := ["--no=rope --goal=450,414,830,414", "--start=530,350,750,350 --goal=750,414,530,414"]
const SCENE := "res://scenes/levels/peligro_3.tscn"
## Peligro 3: brasas en el suelo y un escalón. El extremo va arrastrado
## detrás: si toca una brasa, se pierde. Hay que acortar para saltar cada brasa
## y subir el escalón (todo con la cuerda retraída). En la meta, los extremos cuelgan justo sobre el fuego: muy largos se
## queman; hay que balancearse los dos a la vez (S = 100).
static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var dir := "right" if d == 1 else "left"
	return [["wait_floor"], ["rope", 60], ["walk_to", x.call(70)], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(120)) * d > 0.0, 2.0], ["tap", "jump"],
		["until", func(c): return (c.p(i).global_position.x - x.call(345)) * d > 0.0, 2.0], ["release", dir], ["wait_floor"],
		["walk_to", x.call(348)], ["rope", 60], ["wait", 0.4], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(362)) * d > 0.0, 2.0], ["tap", "jump"],
		["until", func(c): return (c.p(i).global_position.x - x.call(515)) * d > 0.0, 2.0],
		["release", dir], ["wait_floor"], ["wait", 0.3], ["hang", x.call(583)], ["rope", ctx.var_f("r", 140)], ["wait", 0.6],
		["sync", "listos"], ["swing", x.call(583), ctx.var_f("m", 45) * d, 24]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
