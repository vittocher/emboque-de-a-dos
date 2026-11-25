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
		"p1": [["wait_floor"], ["rope", 60]] + M.path(1, [[79, 205], [194, 60], [70, 200], [188, 55], [70, 205], [189, 55]]) + [["rope", ctx.var_f("long", 200)], ["wait", 0.4]] + M.path(1, [[72, 205]]) + [["walk_to", 176, 3], ["wait", 0.8], ["rope", 60], ["wait", 0.4]] + M.path(1, [[198, 45], [52, 268], ["go", 436], [434, 340], ["go", 450], ["go", 530]])
			+ [["until", func(c): return c.level.get_node("GateLeft").is_open, 40.0], ["wait", 1.0], ["walk_to", 660], ["sync", "arriba"], ["hang", 763], ["rope", r],
			["wait", 0.8], ["sync", "listos"], ["swing", 754, m, 24]],
		"p2": [["wait_floor"], ["rope", 60]] + M.path(2, [[1535, 1465], [1472, 1565], [1553, 1462], [1469, 1545], [1536, 1468], [1472, 1560], [1548, 1440]])
			+ [["walk_to", 1387, 3], ["wait", 0.6], ["rope", ctx.var_f("under", 125)], ["wait", 0.8], ["walk_to", 1105, 6], ["wait", 0.5], ["wait_floor"], ["rope", 60], ["wait", 0.5]] + M.path(2, [["run", 1125, 1310]])
			+ [["walk_to", 1277, 3], ["wait", 2.5], ["rope", 225], ["wait", 1.2], ["rope", 60], ["wait", 0.4]] + M.path(2, [[1300, 1105]])
			+ [["walk_to", 1080, 4], ["until", func(c): return c.level.get_node("GateRight").is_open, 40.0], ["wait", 1.0], ["walk_to", 940], ["sync", "arriba"], ["hang", 837], ["rope", r],
			["wait", 0.8], ["sync", "listos"], ["swing", 846, -m, 24]],
	}
