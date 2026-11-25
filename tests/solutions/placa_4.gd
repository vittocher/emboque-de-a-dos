extends RefCounted
const SHORTCUTS := ["--remove=HookCenter --start=510,470,1090,470", "--remove=HookLeft,HookRight --goal=480,538,1120,538"]
const SCENE := "res://scenes/levels/placa_4.tscn"
## Placa 4 "Relevo": la puerta que corta el columpio de cada uno la abre una
## placa del OTRO. J2 se para en la placa de su repisa → se abre la puerta de J1,
## que salta, engancha, se columpia por debajo de la cortina y cae en su isla; ahí se
## para en la placa azul → se abre la puerta de J2, que hace lo mismo. Al medio, en
## altura y sobre el fuego, hay UN gancho para los dos (trapecio): J1 salta, se engancha
## y espera colgando; J2 salta al mismo gancho y los extremos se embocan en el aire.
const M := preload("res://tests/solutions/moves.gd")

static func leap(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1600.0 - v
	return [["walk_to", x.call(568), 3], ["wait", 1.0], ["rope", 60, 1], ["wait", 0.6], ["walk_to", x.call(500), 3], ["wait", 0.3], ["rope", ctx.var_f("r", 90), 2], ["walk_to", x.call(ctx.var_f("run", 460)), 3], ["wait", 0.6]] 		+ M.run_jump(i, d, x.call(ctx.var_f("jx", 550))) + [["until", func(c): return c.hooked(i), 2.5], ["release_all"]]

static func plan(ctx) -> Dictionary:
	var pump: float = ctx.var_f("pump", 1.6)
	var stop: float = ctx.var_f("stop", 490)
	return {
		"p1": [["wait_floor"], ["walk_to", 85.0, 3], ["tap", "jump"], ["wait_floor"], ["walk_to", 50.0, 3],
			["sync", "abierta1"], ["wait", 1.6]] + M.run_jump(1, 1, ctx.var_f("j0", 80))
			+ M.swing_launch(1, 1, pump, ctx.var_f("rx", 385), stop)
			+ [["walk_to", 510.0, 3], ["sync", "en_placa"], ["sync", "llego2"]] + leap(1, 1, ctx) + [["wait", 2.0], ["sync", "colgado"]],
		"p2": [["wait_floor"], ["walk_to", 1515.0, 3], ["tap", "jump"], ["wait_floor"],
			["walk_to", 1552, 3], ["sync", "abierta1"], ["sync", "en_placa"],
			["wait", 1.6]] + M.run_jump(2, -1, 1600.0 - ctx.var_f("j0", 80)) + M.swing_launch(2, -1, pump, 1600.0 - ctx.var_f("rx", 385), 1600.0 - stop)
			+ [["sync", "llego2"], ["walk_to", 1104, 3], ["sync", "colgado"]] + leap(2, -1, ctx),
	}
