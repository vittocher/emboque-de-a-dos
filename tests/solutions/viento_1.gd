extends RefCounted
const CONTROLS := ["12", "1", "2"]
const SHORTCUTS := ["--no=wind --goal=150,528,1450,528", "--remove=Jet2Left,Jet2Right --start=140,460,1460,460 --goal=690,488,910,488"]
const SCENE := "res://scenes/levels/viento_1.tscn"
## Viento 1: dos saltos con viento por lado. El primer chorro (sin peligro) lleva al jugador
## a una repisa que no se alcanza saltando; el segundo está en medio de un foso de fuego
## demasiado ancho: se salta hacia él y empuja hacia arriba para llegar a la meta. Ahí sube
## una corriente ancha con una columna que separa a los jugadores: el viento levanta los
## extremos como volantines (péndulos al revés) por encima de la columna; pegados a ella
## quedan a S = 100, y hay que balancearse los dos a la vez para que se junten arriba.
static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1600.0 - v
	var dir := "right" if d == 1 else "left"
	var r: float = ctx.var_f("r", 310)
	return [["wait_floor"], ["rope", ctx.var_f("r0", 90)], ["walk_to", x.call(40), 4],
		["until", func(c): return c.p(i).global_position.y < 515.0, 4.0], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(112)) * d > 0.0, 4.0], ["release", dir], ["wait_floor"],
		["walk_to", x.call(105), 4], ["wait", 0.5], ["press", dir],
		["until", func(c): return (c.p(i).global_position.x - x.call(ctx.var_f("jx", 180))) * d > 0.0, 3.0], ["tap", "jump"],
		["until", func(c): return (c.p(i).global_position.x - x.call(690)) * d > 0.0, 4.0], ["release", dir], ["wait_floor"],
		["rope", 60], ["walk_to", x.call(ctx.var_f("e", 748)), 3], ["wait", 0.5],
		["rope", r], ["wait", 1.0], ["sync", "listos"], ["swing", x.call(ctx.var_f("e", 748)), ctx.var_f("m", 60) * d, 40, ctx.var_f("g", 620)]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
