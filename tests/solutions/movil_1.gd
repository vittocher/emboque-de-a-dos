extends RefCounted
const CONTROLS := ["12"]
const SHORTCUTS := ["--no=rope", "--remove=PlateF --goal=20,20,1050,600", "--remove=ElevatorLeft,ElevatorRight --goal=670,268,930,268", "--remove=ElevatorA --goal=430,538,20,20", "--remove=Ferry --goal=20,20,1150,658", "--start=670,200,930,200 --goal=930,268,670,268"]
const SCENE := "res://scenes/levels/movil_1.tscn"
## Movil 1 "Ascensor": el primer ascensor de J1 termina contra unas púas: hay que bajarse a tiempo en la isla, y de
## ahí tomar otro hasta media altura; salta a una isla con púas y de ahí a su repisa. J2 baja dos islas; desde el
## borde de la segunda baja el extremo (cuerda larga) a un botón en el fuego que abre la compuerta junto a la isla B.
## Recoge la cuerda (si no, el extremo se quema bajo la plataforma o choca con la caca), cruza en la plataforma
## (la isla B tiene techo: solo se llega desde ella) y sube en un ascensor con púas en las paredes, primero a la
## derecha y después a la izquierda.
## Los extremos cuelgan entre las repisas y basta con que uno se balancee.
const M := preload("res://tests/solutions/moves.gd")

static func at(c, n: String) -> Vector2:
	return c.level.get_node(n).position

static func plan(ctx) -> Dictionary:
	var m: float = ctx.var_f("m", 55)
	var r: float = ctx.var_f("r", 110)
	return {
		"p1": [["wait_floor"], ["rope", 60], ["walk_to", 100, 3], ["until", func(c): return at(c, "ElevatorA").y < 500.0, 12.0], ["until", func(c): return at(c, "ElevatorA").y > 809.0, 12.0],
			["walk_to", 240, 4], ["until", func(c): return at(c, "ElevatorA").y < 576.0, 12.0], ["walk_to", 340, 4], ["wait_floor"]] + M.path(1, [["over", 375, 405]])
			+ [["walk_to", 462, 3], ["until", func(c): return at(c, "ElevatorLeft").y < 440.0, 12.0], ["until", func(c): return at(c, "ElevatorLeft").y > 579.0, 12.0], ["walk_to", 550, 4],
			["until", func(c): return at(c, "ElevatorLeft").y < 434.0, 12.0]] + M.path(1, [[510, 452], [468, 665]]) + [["sync", "arriba"], ["hang", 754], ["rope", r], ["wait", 0.8], ["sync", "listos"], ["swing", 754, m, 24]],
		"p2": [["wait_floor"], ["rope", 60]] + M.path(2, [["go", 1415], ["go", 1490]]) + [["hang", 1468.0], ["rope", ctx.var_f("btn", 215), 2],
			["until", func(c): return c.level.get_node("GateF").is_open, 8.0], ["rope", ctx.var_f("after", 60), 2], ["wait", 0.5]] + M.path(2, [["go", 1568]]) + [["walk_to", 1568, 3], ["until", func(c): return at(c, "Ferry").x < 1260.0, 12.0], ["until", func(c): return at(c, "Ferry").x > 1478.5, 12.0],
			["walk_to", 1480, 6], ["until", func(c): return at(c, "Ferry").x < 1241.0, 12.0], ["walk_to", 1150, 4], ["wait_floor"],
			["until", func(c): return at(c, "ElevatorRight").y < 400.0, 14.0], ["until", func(c): return at(c, "ElevatorRight").y > 711.0, 14.0], ["walk_to", 1018, 3],
			["until", func(c): return at(c, "ElevatorRight").y < 512.0, 12.0], ["walk_to", 1080, 3], ["until", func(c): return at(c, "ElevatorRight").y < 310.0, 12.0], ["walk_to", 940, 3],
			["sync", "arriba"], ["hang", 846], ["rope", r], ["wait", 0.8], ["sync", "listos"], ["swing", 846, -m, 24]],
	}
