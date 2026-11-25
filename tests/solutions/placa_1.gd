extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--remove=ButtonForRight,ButtonForLeft --goal=680,668,920,668", "--remove=PlateGoalLeft --start=680,600,920,600", "--start=680,600,920,600 --goal=920,668,680,668", "--no=rope --goal=680,668,20,20"]
const SCENE := "res://scenes/levels/placa_1.tscn"
## Placa 1: cada compuerta se abre con el botón (queda trabado) del lado del OTRO. El de J1 está
## arriba de una escalera de islas sobre púas; el de J2, al fondo de un foso de púas: él no puede
## bajar, pero su extremo sí (a las púas no les importa). En la meta otra compuerta separa los extremos: solo
## se abre mientras los DOS pisan la placa de su borde; se balancean sin bajarse de ella.
const M := preload("res://tests/solutions/moves.gd")

static func plan(ctx) -> Dictionary:
	var m: float = ctx.var_f("m", 45)
	var r: float = ctx.var_f("r", 150)
	return {
		"p1": [["wait_floor"], ["rope", 60]] + M.path(1, [[115, 240], [272, 390], [370, 250], [220, 110], ["go", 95]]) + [["wait", 0.3]]
			+ M.path(1, [["go", 245], ["go", 390], ["go", 520]])
			+ [["until", func(c): return c.level.get_node("GateLeft").is_open, 25.0], ["wait", 1.0], ["walk_to", 660], ["sync", "arriba"], ["hang", 763], ["rope", r],
			["wait", 0.8], ["sync", "listos"], ["swing", 754, m, 24]],
		"p2": [["wait_floor"], ["rope", 60]] + M.path(2, [["go", 1400], ["go", 1520], ["go", 1390]])
			+ [["walk_to", 1277, 3], ["wait", 2.5], ["rope", 225], ["wait", 1.2], ["rope", 60], ["wait", 0.4]] + M.path(2, [[1300, 1105]])
			+ [["walk_to", 1080, 4], ["until", func(c): return c.level.get_node("GateRight").is_open, 25.0], ["wait", 1.0], ["walk_to", 940], ["sync", "arriba"], ["hang", 837], ["rope", r],
			["wait", 0.8], ["sync", "listos"], ["swing", 846, -m, 24]],
	}
