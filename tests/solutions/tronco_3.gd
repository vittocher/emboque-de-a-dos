extends RefCounted
## Controles (tests/run_controls.sh): quién puede quedarse quieto sin que se gane.
const CONTROLS := ["12"]
const SCENE := "res://scenes/levels/tronco_3.tscn"
## Tronco 3: cada uno corre, salta, su extremo se engancha en el gancho, bombea
## y se lanza por debajo de la cortina a su isla; desde los bordes de adentro cuelgan
## los extremos sobre el vacío y se balancean hasta juntarlos (S = 80: basta con uno).
const M := preload("res://tests/solutions/moves.gd")

static func plan(ctx) -> Dictionary:
	var pump: float = ctx.var_f("pump", 1.3)
	var goal := func(x: float, back: float) -> Array:
		return [["hang", x - signf(back) * 6.0], ["walk_to", x, 2], ["rope", ctx.var_f("r", 170)], ["wait", 0.8],
			["sync", "centro"], ["swing", x, back]]
	return {
		"p1": [["wait_floor"]] + M.run_jump(1, 1, 120) + M.swing_launch(1, 1, pump, 420, ctx.var_f("stop", 535))
			+ goal.call(ctx.var_f("e", 589), ctx.var_f("m", 50)),
		"p2": [["wait_floor"]] + M.run_jump(2, -1, 1160) + M.swing_launch(2, -1, pump, 860, 1280.0 - ctx.var_f("stop", 535))
			+ goal.call(1280.0 - ctx.var_f("e", 589), -ctx.var_f("m", 50)),
	}
