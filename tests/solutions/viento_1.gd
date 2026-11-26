extends RefCounted
const CONTROLS := ["12", "1"]  # con J2 quieto, J1 solo emboca tras ~6 s de balancearse
const SHORTCUTS := ["--no=wind --goal=150,528,20,20", "--remove=Jet2Left,Jet2Right --start=140,460,1500,600 --goal=690,488,910,488"]
const SCENE := "res://scenes/levels/viento_1.tscn"
## Viento 1 "Volantín". J1: el primer chorro lo lleva a una repisa que no se alcanza saltando (y hay
## que bajarse antes de las púas del techo); ahí salta otras púas con la cuerda larga, y toma
## el segundo chorro cuando sopla (ráfagas). J2 baja por la
## derecha: cruza la brasa contra el viento en una calma, pasa caminando bajo la caca y salta unas
## púas con la cuerda larga antes de su chorro. En la meta
## sube una corriente ancha con una columna que separa a los jugadores: el viento levanta los
## extremos como volantines (péndulos al revés) por encima de la columna; pegados a ella
## quedan a S ≈ 114, y hay que balancearse los dos a la vez para que se junten arriba.
const M := preload("res://tests/solutions/moves.gd")
const V := preload("res://tests/solutions/viento_3.gd")

static func goal(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1600.0 - v
	return [["rope", 60], ["walk_to", x.call(ctx.var_f("e", 753)), 3], ["wait", 0.5],
		["rope", ctx.var_f("r", 310)], ["wait", 1.0], ["sync", "listos"], ["swing", x.call(ctx.var_f("e", 753)), ctx.var_f("m", 60) * d, 40, ctx.var_f("g", 620)]]

static func jump_at(i: int, d: int, from: float, to: float) -> Array:
	return [["press", "right" if d > 0 else "left"], ["until", func(c): return (c.p(i).global_position.x - from) * d > 0.0, 2.0], ["leap_to", to], ["wait_floor"]]

static func fly_jet(i: int, d: int, from: float, to: float) -> Array:
	var dir := "right" if d > 0 else "left"
	return [["press", dir], ["until", func(c): return (c.p(i).global_position.x - from) * d > 0.0, 3.0], ["tap", "jump"],
		["until", func(c): return (c.p(i).global_position.x - to) * d > 0.0, 4.0], ["release", dir], ["wait_floor"]]

static func plan(ctx) -> Dictionary:
	var long: float = ctx.var_f("long", 220)
	return {
		"p1": [["wait_floor"], ["rope", 60], ["walk_to", 40.0, 4],
			["until", func(c): return c.p(1).global_position.y < ctx.var_f("top", 525), 4.0], ["press", "right"],
			["until", func(c): return c.p(1).global_position.x > 85.0, 4.0], ["release", "right"], ["wait_floor"],
			["walk_to", 106.0, 3], ["rope", long], ["wait", 0.3]] + jump_at(1, 1, ctx.var_f("sx1", 128), 300)
			+ [["rope", 60, 2], ["walk_to", 290.0, 4], ["wait", 0.4]] + V.gust_starts("Jet2Left") + fly_jet(1, 1, 325, 690) + goal(1, 1, ctx),
		"p2": [["wait_floor"], ["rope", 60], ["walk_to", 1505.0, 5]] + V.gust_ends("HeadwindR") + [["walk_to", 1478.0, 5], ["wait_floor"]] + M.path(2, [[1462, 1366]]) + [["walk_to", 1305, 4], ["wait_floor"], ["walk_to", 1560, 4], ["wait_floor"],
			["rope", long], ["wait", 0.3], ["walk_to", 1575.0, 3], ["wait", 0.3]] + jump_at(2, -1, ctx.var_f("sx2", 1540), 1350) + [["rope", 60, 2], ["walk_to", 1290.0, 4], ["wait", 0.3]] + fly_jet(2, -1, 1245, 910) + goal(2, -1, ctx),
	}
