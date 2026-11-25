extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--no=rope", "--remove=PlateA --goal=20,20,630,828", "--remove=PlateWire --goal=985,268,20,20", "--remove=PlateB --goal=20,20,1040,828", "--start=940,220,1200,200 --goal=1200,268,940,268"]
const SCENE := "res://scenes/levels/placa_3.tscn"
## Placa 3 "El titiritero": los dos van hacia la derecha. J1 camina arriba con la campana
## colgando por el pasillo del medio, como un títere: con ella esquiva la caca y pisa placas que abren
## las compuertas de J2, que va por abajo entre púas. J2 pisa la placa que abre la compuerta del
## pasillo de la campana. J1: placa A → J2 pasa y pisa la suya → J1 pasa la campana y pisa B → J2 pasa, cruza
## bajo la meta y sube en zigzag al otro lado del hueco. Ahí se balancean los dos a la vez.
const M := preload("res://tests/solutions/moves.gd")

static func plan(ctx) -> Dictionary:
	var m: float = ctx.var_f("m", 45)
	var r: float = ctx.var_f("r", 150)
	return {
		"p1": [["wait_floor"], ["rope", 175], ["walk_to", 330, 4], ["wait", 0.6], ["walk_to", 400, 3], ["wait", 2.0], ["rope", 312, 3], ["walk_to", 360, 3], ["wait", 0.5], ["walk_to", 400, 3], ["sync", "j2_placa"],
			["rope", 200], ["wait", 0.5]] + M.path(1, [["over", 462, 492]]) + [["walk_to", 520, 4], ["wait", 0.8], ["rope", 245, 3],
			["until", func(c): return c.level.get_node("GateWire").is_open, 10.0], ["wait", 0.8], ["walk_to", 640, 4], ["wait", 0.8], ["sync", "j1_paso"], ["walk_to", 700, 4], ["wait", 0.5], ["walk_to", 738, 4], ["wait", 0.8],
			["rope", 180, 3], ["wait", 0.5], ["walk_to", 925, 3], ["wait", 2.0], ["until", func(c): return c.end_pos(1).x > 915.0 and c.end_pos(1).x < 935.0, 5.0], ["rope", 312, 3], ["walk_to", 895, 3], ["wait", 0.5], ["walk_to", 925, 3], ["sync", "j2_paso"], ["rope", r], ["wait", 0.5], ["walk_to", 960, 3], ["sync", "arriba"], ["walk_to", 1012, 3],
			["wait", 0.8], ["sync", "listos"], ["swing", 1012, m, 24]],
		"p2": [["wait_floor"], ["rope", 60]] + M.path(2, [[92, 215], [245, 370], ["over", 410, 440]])
			+ [["walk_to", 485, 4], ["until", func(c): return c.level.get_node("Gate1").is_open, 25.0], ["walk_to", 630, 4], ["sync", "j2_placa"], ["sync", "j1_paso"]]
			+ M.path(2, [[700, 790], [820, 905]]) + [["walk_to", 925, 4], ["until", func(c): return c.level.get_node("Gate2").is_open, 25.0], ["walk_to", 1010, 4], ["sync", "j2_paso"]]
			+ M.path(2, [["over", 1060, 1115], ["over", 1245, 1280], [1342, 1435], [1460, 1560], [1545, 1435], [1460, 1560], [1545, 1425], [1400, 1225]])
			+ [["sync", "arriba"], ["hang", 1118], ["rope", r], ["wait", 0.8], ["sync", "listos"], ["swing", 1118, -m, 24]],
	}
