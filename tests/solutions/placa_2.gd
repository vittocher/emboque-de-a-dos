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
	return [["hang", x.call(410)], ["rope", 318, 3],
		["wait", 0.3], ["jump_to", x.call(510)], ["wait_floor"], ["walk_to", x.call(560), 4],
		["until", func(c): return c.level.get_node(gate).is_open, 6.0], ["wait", 2.6], ["walk_to", x.call(705), 4], ["sync", "adentro"], ["wait", 0.3]] + reel + [["wait", 0.5], ["rope", 60, 2], ["sync", "colgar"], ["hang", x.call(ctx.var_f("h", 750))], ["rope", ctx.var_f("r", 170)], ["wait", 0.8], ["sync", "listos"],
		["swing", x.call(750), ctx.var_f("m", 55) * d, 24]]

static func plan(ctx) -> Dictionary:
	return {"p1": [["wait_floor"], ["rope", 60]] + M.path(1, [[115, 220], [200, 100], ["run", 118, 340]]) + side(1, 1, ctx),
		"p2": [["wait_floor"], ["rope", 60]] + M.path(2, [["over", 1460, 1420], ["go", 1257], ["over", 1330, 1370], ["go", 1555], ["over", 1405, 1370]]) + side(2, -1, ctx)}
