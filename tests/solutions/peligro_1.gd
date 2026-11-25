extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--goal=930,268,670,268", "--no=hook --goal=670,268,930,268"]
const SCENE := "res://scenes/levels/peligro_1.tscn"
## Peligro 1 "Espinas": las púas matan al jugador, no al emboque. Los ganchos están adentro de un
## erizo de púas: el extremo entra y se engancha, pero el jugador se pincha si recoge toda la cuerda o se
## acerca balanceándose. J1 baja por un pozo, cruza con su gancho y sube; J2 sube primero y cruza con el suyo hasta su
## repisa. En la meta los extremos cuelgan y basta con que uno se balancee.
const M := preload("res://tests/solutions/moves.gd")

static func plan(ctx) -> Dictionary:
	var m: float = ctx.var_f("m", 50)
	var r: float = ctx.var_f("r", 120)
	var pump: float = ctx.var_f("pump", 1.3)
	return {
		"p1": [["wait_floor"], ["rope", 60]] + M.path(1, [[95, 285], [275, 100]]) + [["walk_to", 165, 3], ["press", "right"], ["until", func(c): return not c.on_floor(1), 2.0], ["release", "right"], ["walk_to", 60, 5], ["wait_floor"]]
			+ [["rope", ctx.var_f("h1", 130)], ["wait", 0.6], ["walk_to", 50, 3], ["wait", 0.6]] + M.run_jump(1, 1, ctx.var_f("j1", 110)) + M.swing_launch(1, 1, pump, ctx.var_f("rx1", 420), ctx.var_f("stop1", 568))
			+ [["rope", 60]] + M.path(1, [[543, 618], [615, 505], [495, 408], [411, 531], [538, 640]])
			+ [["hang", 748], ["rope", r], ["wait", 0.8], ["sync", "listos"], ["swing", 748, m, 24]],
		"p2": [["wait_floor"], ["rope", 60]] + M.path(2, [[1488, 1397], [1423, 1515], [1488, 1400], [1422, 1520], [1488, 1409], [1412, 1510]])
			+ [["walk_to", 1570, 4], ["rope", ctx.var_f("h2", 130)], ["wait", 0.6], ["walk_to", 1575, 3], ["wait", 0.6]] + M.run_jump(2, -1, ctx.var_f("j2", 1505)) + M.swing_launch(2, -1, pump, ctx.var_f("rx2", 1185), ctx.var_f("stop2", 945))
			+ [["hang", 852], ["rope", r], ["wait", 0.8], ["sync", "listos"], ["swing", 852, -m, 24]],
	}
