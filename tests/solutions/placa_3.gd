extends RefCounted
const CONTROLS := ["12", "1"]
const SHORTCUTS := ["--no=box", "--remove=PlateRock --start=600,500,980,500", "--start=600,500,980,500 --goal=980,568,600,568"]
const SCENE := "res://scenes/levels/placa_3.tscn"
## Placa 3 "La mecedora": J1 deja su caja sobre la placa que abre la compuerta de J2 y J2
## deja su extremo en la placa que abre la de J1 (y cruza con la cuerda larga). En la meta, J2
## se para en una plataforma que se mueve mientras J1 pisa la placa de su borde: J1 pisa y
## suelta la placa al ritmo del péndulo, y así MECE el extremo de J2 mientras balancea el suyo.
static func plan(ctx) -> Dictionary:
	var m: float = ctx.var_f("m", 80)
	var r: float = ctx.var_f("r", 200)
	return {
		"p1": [["wait_floor"], ["rope", 60], ["press", "right"], ["until", func(c): return c.level.get_node("Box").position.x > 255.0, 8.0], ["release", "right"], ["wait", 0.3],
			["sync", "caja"], ["walk_to", 195, 4], ["wait", 0.3], ["jump_to", 262], ["wait_floor"], ["walk_to", 360, 4], ["wait_floor"],
			["until", func(c): return c.level.get_node("GateLeft").is_open, 15.0], ["wait", 0.8], ["walk_to", 600, 4], ["sync", "adentro"], ["sync", "arriba"], ["sync", "colgado"],
			["hang", 714], ["rope", r], ["wait", 0.5], ["sync", "listos"], ["swing", 712, m, 60]],
		"p2": [["wait_floor"], ["rope", 60], ["walk_to", 1400, 3], ["wait", 0.4], ["walk_to", 1360, 3], ["wait", 0.6], ["rope", 280], ["sync", "caja"],
			["until", func(c): return c.level.get_node("GateRight").is_open, 10.0], ["wait", 0.8], ["jump_to", 1290], ["wait_floor"], ["walk_to", 1140, 4], ["sync", "adentro"],
			["rope", 60, 2], ["wait", 1.0], ["walk_to", 1000, 4], ["sync", "arriba"], ["until", func(c): return c.level.get_node("Rocker").position.x > 978.0, 5.0], ["walk_to", 930, 4], ["hang", 887], ["sync", "colgado"], ["rope", r], ["wait", 0.5], ["sync", "listos"]],
	}
