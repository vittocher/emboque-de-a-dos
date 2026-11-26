extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--remove=BargeRight --goal=20,20,1280,168", "--remove=BargeLeft --goal=400,598,20,20", "--remove=ElevatorLeft,ElevatorRight --start=390,530,1162,530 --goal=640,298,960,298", "--start=640,230,960,230 --goal=960,298,640,298"]
const SCENE := "res://scenes/levels/movil_3.tscn"
## Movil 3 "Andén": todo se mueve con las placas del otro, en tres relevos. 1) J1 pisa la amarilla
## y lleva a J2 sobre las púas (el techo bajo no deja saltarlas); 2) J2 pisa la celeste y sube a J1; J1 pasa caminando bajo una caca
## baja y J2 salta con la cuerda larga unas púas (a través de la caca que cuelga); 3) J1 pisa la rosada y
## sube a J2, que pisa la morada en su torre y sube a J1. En la meta, los extremos cuelgan entre
## las torres y se balancean los dos a la vez; una cortina sube y baja entre ellos y solo los
## deja juntarse cuando está arriba.
const M := preload("res://tests/solutions/moves.gd")

static func y(c, n: String) -> float:
	return c.level.get_node(n).position.y

static func plan(ctx) -> Dictionary:
	var long: float = ctx.var_f("long", 200)
	return {
		"p1": [["wait_floor"], ["rope", 60], ["walk_to", 140, 3], ["sync", "j2_listo"], ["walk_to", 55, 3], ["sync", "j2_abajo"], ["walk_to", 255, 4], ["wait", 0.4], ["sync", "j1_en_barca"],
			["until", func(c): return y(c, "BargeLeft") < 692.0, 10.0], ["wait", 0.3]] + M.path(1, [[222, 40], [68, 195]])
			+ [["sync", "j1_subio"], ["wait", 0.6], ["walk_to", 365, 4], ["wait_floor"],
			["sync", "j2_en_ascensor"], ["walk_to", 400, 3],
			["until", func(c): return c.p(2).global_position.y < 310.0 and c.p(2).is_on_floor() and c.p(2).global_position.x < 1000.0, 20.0],
			["walk_to", 530, 4], ["wait", 0.5], ["sync", "j1_en_ascensor"],
			["until", func(c): return y(c, "ElevatorLeft") < 341.0, 15.0],
			["rope", 60, 1], ["walk_to", 735, 3], ["sync", "j1_arriba"], ["wait", 0.5], ["rope", ctx.var_f("r", 180)],
			["wait", 0.8], ["sync", "listos"], ["swing", 745, ctx.var_f("m", 60)]],
		"p2": [["wait_floor"], ["rope", 60], ["walk_to", 1468, 4], ["wait", 0.2], ["sync", "j2_listo"],
			["until", func(c): return c.level.get_node("BargeRight").position.x < 1375.0, 12.0], ["walk_to", 1303, 3], ["wait", 0.3], ["sync", "j2_abajo"], ["sync", "j1_en_barca"], ["jump_to", 1248], ["wait_floor"], ["walk_to", 1248, 3], ["sync", "j1_subio"],
			["jump_to", 1316], ["wait_floor"], ["walk_to", 1348, 5], ["wait_floor"], ["walk_to", 1545, 5], ["wait_floor"], ["walk_to", 1578, 3], ["wait", 0.5], ["rope", long], ["wait", 0.5], ["press", "left"],
			["until", func(c): return c.p(2).global_position.x < ctx.var_f("sx2", 1542), 2.0], ["leap_to", 1375], ["wait_floor"], ["rope", 60, 2]]
			+ M.path(2, [["go", 1300], [1288, 1225], [1208, 1162]]) + [
			["until", func(c): return y(c, "ElevatorRight") > 641.0, 15.0], ["walk_to", 1070, 4], ["wait", 0.5], ["sync", "j2_en_ascensor"],
			["until", func(c): return y(c, "ElevatorRight") < 341.0, 15.0],
			["rope", 60], ["walk_to", 872, 3], ["sync", "j1_en_ascensor"], ["walk_to", 970, 3], ["sync", "j1_arriba"],
			["rope", 60, 1], ["walk_to", 855, 3], ["wait", 0.5], ["rope", ctx.var_f("r", 180)],
			["wait", 0.8], ["sync", "listos"], ["swing", 855, -ctx.var_f("m", 60)]],
	}
