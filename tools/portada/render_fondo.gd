extends SceneTree
## Arma el ambiente de la portada con el arte real de los niveles (fondo con su
## shader, bloques vestidos por TerrainArt con sombras, sopaipillas, ganchos y una
## placa de madera para los controles) y lo captura. Coordenadas de nivel (1280×720);
## la ventana es de 1920×1080, así que la captura sale a 1,5×.
## Uso (desde la raíz del proyecto; lo llama tools/portada/hacer_portada.sh):
##   godot --path . --resolution 1920x1080 -s tools/portada/render_fondo.gd -- <carpeta_salida>
## Sin --headless (necesita dibujar; en Linux sin pantalla, con xvfb-run). Escribe fondo.png.
const S := 1.5   # escala portada / nivel

func _initialize() -> void:
	_run.call_deferred()

func block(root: Node, name: String, x0: float, y0: float, x1: float, y1: float) -> void:
	var b = load("res://scenes/block.tscn").instantiate()
	b.name = name
	b.position = Vector2((x0 + x1) * 0.5, (y0 + y1) * 0.5)
	b.size = Vector2(x1 - x0, y1 - y0)
	root.add_child(b)

func prop(root: Node, scene: String, pos: Vector2, scale := 1.0) -> Node2D:
	var n = load(scene).instantiate()
	n.position = pos
	n.scale = Vector2.ONE * scale
	root.add_child(n)
	return n

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "."
	var root := Node2D.new()
	root.name = "Portada"
	root.add_child(load("res://scenes/background.tscn").instantiate())
	var cam := Camera2D.new()
	cam.position = Vector2(640, 360)
	root.add_child(cam)
	# Coordenadas de la portada (1920×1080) pasadas a nivel.
	var top_ledge := 698.0 / S        # donde pisan los personajes
	var top_pit := 786.0 / S          # donde descansan el palito y la campana
	block(root, "LedgeLeft", -40, top_ledge, 368, 780)
	block(root, "LedgeRight", 912, top_ledge, 1320, 780)
	block(root, "Pit", 368, top_pit, 912, 780)
	# Vigas que cuelgan del techo a los costados del título, como las de los niveles.
	block(root, "BeamLeft", 234, -40, 258, 120)
	block(root, "BeamRight", 1022, -40, 1046, 120)
	# Repisitas flotantes con sopaipillas (lo que se ve en los niveles).
	block(root, "ShelfLeft", 30, 168, 150, 192)
	block(root, "ShelfRight", 1130, 168, 1250, 192)
	root.add_child(load("res://scenes/terrain_art.tscn").instantiate())
	for p in [Vector2(70, 140), Vector2(112, 140), Vector2(1168, 140), Vector2(1210, 140)]:
		prop(root, "res://scenes/collectible.tscn", p)
	# Placa de madera para los controles (mismo shader que los botones y el HUD).
	var plaque := ColorRect.new()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/madera_boton.gdshader")
	var rect := Rect2(Vector2(162, 826) / S, Vector2(1596, 236) / S)
	plaque.position = rect.position
	plaque.size = rect.size
	mat.set_shader_parameter("rect_size", rect.size)
	mat.set_shader_parameter("corner", 14.0)
	# Madera más oscura que la de los botones: el texto de los controles se lee mejor.
	mat.set_shader_parameter("wood_dark", Color(0.11, 0.06, 0.035))
	mat.set_shader_parameter("wood_light", Color(0.25, 0.15, 0.08))
	plaque.material = mat
	plaque.z_index = 20
	root.add_child(plaque)
	get_root().add_child(root)
	current_scene = root
	for i in 20:
		await process_frame
	await create_timer(0.6).timeout
	get_root().get_texture().get_image().save_png(out_dir.path_join("fondo.png"))
	quit()
