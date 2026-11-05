extends RefCounted
const SCENE := "res://scenes/levels/movil_3.tscn"
## Movil 3: los ascensores se mueven solo mientras se pisa la placa de su color.
## La placa del ascensor de J2 está del lado de J1; la del ascensor de J1, arriba
## en la torre de J2. J2 se sube a su ascensor, J1 pisa su placa y lo sube; J2
## se baja en su torre y pisa la otra placa; J1 se sube a su ascensor y sube.
## Los dos bajan el extremo al cuenco entre las torres.
static func plan(ctx) -> Dictionary:
	return {
		"p1": [["wait_floor"], ["rope", 80], ["walk_to", 90, 3], ["sync", "j2_en_ascensor"], ["walk_to", 150, 3],
			["until", func(c): return c.p(2).global_position.y < 280.0 and c.p(2).is_on_floor() \
				and c.p(2).global_position.x < 845.0, 15.0],
			["walk_to", 370, 4], ["wait", 0.5], ["sync", "j1_en_ascensor"],
			["until", func(c): return c.level.get_node("ElevatorLeft").position.y < 316.0, 15.0],
			["walk_to", 596, 3], ["sync", "j1_arriba"], ["wait", 0.5], ["rope", ctx.var_f("r", 200)],
			["sync", "listos"], ["jiggle", 596, 8, 10]],
		"p2": [["wait_floor"], ["rope", 80], ["walk_to", 910, 4], ["wait", 0.5], ["sync", "j2_en_ascensor"],
			["until", func(c): return c.level.get_node("ElevatorRight").position.y < 316.0, 15.0],
			["rope", 60], ["walk_to", 712, 3], ["sync", "j1_en_ascensor"], ["walk_to", 810, 3], ["sync", "j1_arriba"],
			["walk_to", 684, 3], ["wait", 0.5], ["rope", ctx.var_f("r", 200)],
			["sync", "listos"], ["jiggle", 684, -8, 10]],
	}
