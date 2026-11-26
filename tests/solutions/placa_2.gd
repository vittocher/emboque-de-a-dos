extends RefCounted
const CONTROLS := ["12", "1", "2"]
const SHORTCUTS := ["--remove=PlateLeft,PlateRight --goal=715,588,885,588", "--start=705,520,895,520 --goal=895,588,705,588"]
const SCENE := "res://scenes/levels/placa_2.tscn"
## Placa 2 "Peso muerto": J1 sube unas islas sobre el fuego; J2 baja por pasillos con púas, caca y una
## brasa. La placa está al fondo de un foso angosto (no cabe el jugador) y la compuerta, lejos: hay
## que dejar el extremo en la placa y cruzar con la cuerda casi al máximo. Del otro lado se recoge la cuerda: el
## extremo sale del foso y pasa por debajo mientras la compuerta baja (no aplasta: espera). Los
## extremos cuelgan en el hueco del medio y se balancean los dos a la vez.
const M := preload("res://tests/solutions/moves.gd")

static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1600.0 - v
	var gate := "GateLeft" if d == 1 else "GateRight"
	# Recoge de a poco (si se tira de golpe, el extremo trabado en el rebaje arrastra al jugador).
	var reel := []
	for k in 8:
		reel += [["rope", 290 - k * 30], ["wait", 0.25], ["walk_to", x.call(712), 4]]
	return [["walk_to", x.call(345), 3], ["rope", ctx.var_f("rr", 100), 3], ["wait", 0.5], ["walk_to", x.call(ctx.var_f("d1", 440)), 3], ["wait", 1.2], ["walk_to", x.call(410), 3], ["rope", 318, 3],
		["wait", 0.3], ["jump_to", x.call(510)], ["wait_floor"], ["walk_to", x.call(560), 4],
		["until", func(c): return c.level.get_node(gate).is_open, 6.0], ["wait", 2.6], ["walk_to", x.call(705), 4], ["sync", "adentro"], ["wait", 0.3]] + reel + [["wait", 0.5], ["rope", 60, 2], ["sync", "colgar"], ["hang", x.call(ctx.var_f("h", 750))], ["rope", ctx.var_f("r", 170)], ["wait", 0.8], ["sync", "listos"],
		["swing", x.call(750), ctx.var_f("m", 55) * d, 24]]

static func plan(ctx) -> Dictionary:
	return {"p1": [["wait_floor"], ["rope", 60]] + M.path(1, [[105, 210], [210, 85], [104, 222], [212, 98], [100, 224], [212, 70], [72, 210], [238, 350]]) + [["rope", ctx.var_f("long", 220)], ["wait", 0.5]] + [["hold_jump", ctx.var_f("h", 0.5)]] + M.path(1, [[338, 515]]) + [["hold_jump", 0.5], ["rope", 60], ["wait", 0.6]] + M.path(1, [["go", 575], ["go", 345]]) + side(1, 1, ctx),
		"p2": [["wait_floor"], ["rope", 60]] + [["walk_to", 1484, 3], ["wait", 0.6], ["rope", ctx.var_f("under", 130)], ["wait", 0.8], ["walk_to", 1258, 5], ["wait_floor"], ["wait", 0.3]] + M.path(2, [[1270, 1445], ["go", 1550]]) + [["rope", 60], ["wait", 0.5], ["walk_to", 1330, 4]] + side(2, -1, ctx)}
