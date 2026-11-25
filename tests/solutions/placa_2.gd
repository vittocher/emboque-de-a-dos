extends RefCounted
const CONTROLS := ["12", "1", "2"]
const SHORTCUTS := ["--remove=PlateLeft,PlateRight --goal=555,488,725,488", "--start=545,420,735,420 --goal=735,488,545,488"]
const SCENE := "res://scenes/levels/placa_2.tscn"
## Placa 2 "Peso muerto": la placa está al fondo de un foso angosto (no cabe el jugador) y la compuerta, lejos: hay que dejar el extremo en la placa y cruzar con la
## cuerda casi al máximo. Del otro lado se recoge la cuerda: el extremo sale del foso y pasa
## por debajo mientras la compuerta baja (no aplasta: espera). Los extremos cuelgan en el
## hueco del medio y se balancean los dos a la vez.
static func side(i: int, d: int, ctx) -> Array:
	var x := func(v: float) -> float: return v if d == 1 else 1280.0 - v
	var gate := "GateLeft" if d == 1 else "GateRight"
	# Recoge de a poco (si se tira de golpe, el extremo trabado en el rebaje arrastra al jugador).
	var reel := []
	for k in 8:
		reel += [["rope", 290 - k * 30], ["wait", 0.25], ["walk_to", x.call(552), 4]]
	return [["wait_floor"], ["hang", x.call(250)], ["rope", 318, 3],
		["wait", 0.3], ["jump_to", x.call(350)], ["wait_floor"], ["walk_to", x.call(440), 4],
		["until", func(c): return c.level.get_node(gate).is_open, 6.0], ["wait", 2.6], ["walk_to", x.call(545), 4], ["sync", "adentro"], ["wait", 0.3]] + reel + [["wait", 0.5], ["rope", 60, 2], ["hang", x.call(590)], ["rope", ctx.var_f("r", 170)], ["wait", 0.8], ["sync", "listos"],
		["swing", x.call(590), ctx.var_f("m", 45) * d, 24]]

static func plan(ctx) -> Dictionary:
	return {"p1": side(1, 1, ctx), "p2": side(2, -1, ctx)}
