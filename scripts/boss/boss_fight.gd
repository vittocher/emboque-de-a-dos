extends Node
class_name BossFight

## El nivel del Tue Tue, en tres fases:
## 1. PELEA: el Tue Tue vuela por la arena. Hay que pegarle lanzándole el emboque
##    (max_hp veces) mientras con picadas y ráfagas los empuja a los fosos de púas.
## 2. SUBIDA: derrotado, escapa hacia arriba y la cámara empieza a subir sola: los
##    jugadores trepan los escalones (parkour) y quien quede abajo de la pantalla muere.
## 3. CIMA: la cámara se detiene arriba y recién ahí se puede embocar (WinManager y
##    closeup se encienden), pero el Tue Tue sigue molestando: da vueltas y se tira en
##    picada a desparramar los extremos. Pegarle lo deja mareado unos segundos.
##
## Checkpoints: morir en la subida o en la cima recarga el nivel y retoma desde el
## comienzo de esa fase (el Tue Tue no se vuelve a pelear). Entrar desde el mapa o
## "Reiniciar" en la pausa empiezan de cero. El puntaje y las sopaipillas juntadas
## antes del checkpoint se conservan.

## Quien cae bajo el borde de la pantalla durante la subida (para el bot de pruebas,
## igual que las zonas de muerte).
signal triggered(body: Node)
signal phase_changed(phase: Phase)

enum Phase { INTRO, FIGHT, ESCAPE, CLIMB, SUMMIT, WON }

@export var boss_path: NodePath = ^"../TueTue"
@export var camera_path: NodePath = ^"../Camera2D"
@export var background_path: NodePath = ^"../Background"
@export var win_manager_path: NodePath = ^"../WinManager"
@export var closeup_path: NodePath = ^"../CloseupManager"
@export var score_manager_path: NodePath = ^"../ScoreManager"
@export var player1_path: NodePath = ^"../Player1"
@export var player2_path: NodePath = ^"../Player2"
@export var emboque1_path: NodePath = ^"../Emboque1"
@export var emboque2_path: NodePath = ^"../Emboque2"
@export var bar_path: NodePath = ^"../UI/BossBar"
## false en los tests: caer bajo la pantalla no recarga (solo emite triggered).
@export var reload_on_death: bool = true

@export_group("Pelea")
## Segundos antes de que aparezca el Tue Tue.
@export var intro_time: float = 1.2

@export_group("Subida")
## Altura (centro de la cámara) al empezar a subir y en la cima.
@export var camera_start_y: float = 360.0
@export var camera_top_y: float = -1080.0
## Segundos entre la derrota del Tue Tue y que la cámara empiece a subir.
@export var climb_delay: float = 3.0
## Rapidez de la cámara (px/s). Si los dos van en la mitad de arriba de la
## pantalla, sube más rápido (no hay que esperarla).
@export var climb_speed: float = 30.0
@export var climb_speed_fast: float = 60.0
## Muere quien queda esta distancia por debajo del borde de abajo de la pantalla.
@export var abyss_margin: float = 10.0

@export_group("Checkpoints")
## Dónde reaparecen al retomar la subida (en el aire, sobre la arena) y la cima.
@export var climb_spawn_p1: Vector2 = Vector2(470, 400)
@export var climb_spawn_p2: Vector2 = Vector2(810, 400)
@export var summit_spawn_p1: Vector2 = Vector2(520, -1280)
@export var summit_spawn_p2: Vector2 = Vector2(760, -1280)
## Punto del emboque final (bajo la cortina de la cima, donde cuelgan los extremos):
## el Tue Tue acosa alrededor.
@export var summit_center: Vector2 = Vector2(640, -1120)

# Checkpoint alcanzado en esta escena (sobrevive a la recarga por muerte).
static var _checkpoint: Phase = Phase.FIGHT
static var _saved_score := 0
static var _saved_collected := 0
static var _saved_taken: Array[String] = []

var phase: Phase = Phase.INTRO

var _boss: TueTue
var _camera: Camera2D
var _background: Node2D
var _win: WinManager
var _closeup: CloseupManager
var _score: ScoreManager
var _players: Array[Player] = []
var _emboques: Array[Emboque] = []
var _bar: BossBar
var _banner: Label
var _banner_tween: Tween
var _ceiling: StaticBody2D
var _cam_y := 360.0
var _t := 0.0
var _shake := 0.0
var _fired := false
var _collectibles: Array[String] = []

func _ready() -> void:
	_boss = get_node(boss_path) as TueTue
	_camera = get_node(camera_path) as Camera2D
	_background = get_node_or_null(background_path) as Node2D
	_win = get_node_or_null(win_manager_path) as WinManager
	_closeup = get_node_or_null(closeup_path) as CloseupManager
	_score = get_node_or_null(score_manager_path) as ScoreManager
	_players = [get_node(player1_path) as Player, get_node(player2_path) as Player]
	_emboques = [get_node(emboque1_path) as Emboque, get_node(emboque2_path) as Emboque]
	_bar = get_node_or_null(bar_path) as BossBar
	for c in get_tree().get_nodes_in_group(Collectible.GROUP):
		_collectibles.append(String(owner.get_path_to(c)))
	_boss.hit_taken.connect(_on_boss_hit)
	_boss.defeated.connect(_on_boss_defeated)
	_boss.stunned.connect(_on_boss_stunned)
	if _bar != null:
		_bar.feather_texture = _boss.hp_icon()
		_bar.setup(_boss.max_hp)
	_make_ceiling()
	_make_banner()
	# Lo de la cima se enciende recién al llegar arriba.
	if _win != null:
		_win.active = false
	if _closeup != null:
		_closeup.enabled = false
	_cam_y = _camera.global_position.y

	var path := owner.scene_file_path if owner != null else ""
	if not LevelFlow.consume_death_reload(path):
		_checkpoint = Phase.FIGHT
	match _checkpoint:
		Phase.CLIMB:
			_restore(Phase.CLIMB)
		Phase.SUMMIT:
			_restore(Phase.SUMMIT)
		_:
			_set_phase(Phase.INTRO)

# --- Fases ---

func _set_phase(p: Phase) -> void:
	phase = p
	_t = 0.0
	match p:
		Phase.FIGHT:
			_boss.start_fight()
			if _bar != null:
				_bar.set_hp(_boss.hp)
				_bar.show_bar(true)
			_show_banner("BOSS_PHASE1")
		Phase.ESCAPE:
			# Ya le ganaron: morir de aquí en adelante no repite la pelea.
			_save_checkpoint(Phase.CLIMB)
			_boss.flee()
			if _bar != null:
				_bar.show_bar(false)
			_show_banner("BOSS_PHASE2")
		Phase.CLIMB:
			_boss.follow(_camera)
		Phase.SUMMIT:
			_save_checkpoint(Phase.SUMMIT)
			_enable_summit()
			_show_banner("BOSS_PHASE3")
		Phase.WON:
			_boss.beaten()
	phase_changed.emit(p)

func _physics_process(delta: float) -> void:
	_t += delta
	match phase:
		Phase.INTRO:
			if _t >= intro_time:
				_set_phase(Phase.FIGHT)
		Phase.ESCAPE:
			if _t >= climb_delay:
				_set_phase(Phase.CLIMB)
		Phase.CLIMB:
			var speed := climb_speed
			if _players.all(func(pl: Player) -> bool: return pl.global_position.y < _cam_y):
				speed = climb_speed_fast
			_cam_y = maxf(camera_top_y, _cam_y - speed * delta)
			_move_view()
			_check_abyss()
			if _cam_y <= camera_top_y:
				_set_phase(Phase.SUMMIT)
		Phase.SUMMIT:
			_check_abyss()
			if LevelFlow.is_won(get_tree()):
				_set_phase(Phase.WON)

func _process(delta: float) -> void:
	# Temblor de cámara al pegarle (offset: no se pelea con el closeup).
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		var k := _shake / 0.3
		_camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 7.0 * k
	elif _camera.offset != Vector2.ZERO:
		_camera.offset = Vector2.ZERO

## Durante la subida la cámara, el techo invisible y el fondo van juntos.
func _move_view() -> void:
	_camera.global_position.y = _cam_y
	_ceiling.global_position.y = _cam_y - 360.0
	if _background != null:
		_background.global_position.y = _cam_y

## Cae bajo la pantalla → muere (como una zona de muerte del jugador).
func _check_abyss() -> void:
	if _fired or LevelFlow.is_over(get_tree()):
		return
	var limit := _cam_y + 360.0 + abyss_margin
	for pl in _players:
		if pl.global_position.y > limit:
			_fired = true
			Sfx.play(&"die")
			triggered.emit(pl)
			if reload_on_death:
				LevelFlow.restart(get_tree())
			return

func _enable_summit() -> void:
	if _win != null:
		_win.active = true
	if _closeup != null:
		_closeup.set_home(Vector2(640, camera_top_y), Vector2(0, camera_top_y - 360.0))
		_closeup.enabled = true
	_boss.harass(summit_center)

# --- El Tue Tue ---

func _on_boss_hit(hp_left: int) -> void:
	_shake = 0.3
	if _bar != null:
		_bar.set_hp(hp_left)

func _on_boss_defeated() -> void:
	_shake = 0.45
	if phase == Phase.FIGHT:
		_set_phase(Phase.ESCAPE)

func _on_boss_stunned() -> void:
	_shake = 0.2
	_show_banner("BOSS_STUNNED", 1.4)

# --- Checkpoints ---

func _save_checkpoint(p: Phase) -> void:
	_checkpoint = p
	if _score != null:
		_saved_score = _score.score
		_saved_collected = _score.collected
	_saved_taken.clear()
	for path in _collectibles:
		var c := owner.get_node_or_null(path)
		if c == null or c.is_queued_for_deletion():
			_saved_taken.append(path)

## Retoma desde el comienzo de [param p] (tras morir; también para los tests).
func _restore(p: Phase) -> void:
	for path in _saved_taken:
		var c := owner.get_node_or_null(path)
		if c != null:
			c.queue_free()
	if _score != null:
		_score.restore(_saved_score, _saved_collected)
	if p == Phase.CLIMB:
		_place(0, climb_spawn_p1, 170.0)
		_place(1, climb_spawn_p2, 170.0)
		_cam_y = camera_start_y
		_move_view()
		# Un respiro antes de que la cámara empiece a subir (el Tue Tue ya escapó:
		# aparece arriba al empezar la subida).
		phase = Phase.ESCAPE
		_t = climb_delay * 0.3
		_save_checkpoint(Phase.CLIMB)
		_show_banner("BOSS_PHASE2")
	else:
		_place(0, summit_spawn_p1, 60.0)
		_place(1, summit_spawn_p2, 60.0)
		_cam_y = camera_top_y
		_move_view()
		_boss.position = summit_center + Vector2(0, -320)
		_set_phase(Phase.SUMMIT)

## Lleva al jugador [param i] (y su extremo, para que la cuerda no lo tire de
## vuelta) a [param pos], con la cuerda de [param rope] px.
func _place(i: int, pos: Vector2, rope: float) -> void:
	var pl := _players[i]
	var em := _emboques[i]
	pl.global_position = pos
	pl.velocity = Vector2.ZERO
	em.rope_length = rope
	var end := em.get_end()
	if end != null:
		# También el ancla: si el paso de física corre antes de que el Emboque se la
		# actualice, la cuerda vería el extremo lejísimos y lo lanzaría.
		var hand: Vector2 = pos + (pl.get_node(^"RopeAnchor") as Node2D).position
		end.anchor_position = hand
		end.rope_length = rope
		end.global_position = hand + Vector2(0, rope)
		end.linear_velocity = Vector2.ZERO
		end.angular_velocity = 0.0

## Para el bot de pruebas: empezar directo en la subida o en la cima. El techo se
## mueve ya y los jugadores recién en el cuadro siguiente: el motor actualiza dónde
## está un cuerpo estático al dar el paso de física, y si los jugadores llegaran
## antes quedarían "dentro" del techo viejo y los empujaría hacia abajo.
func debug_start(p: Phase) -> void:
	if _bar != null:
		_bar.hide()
	_saved_taken.clear()
	_saved_score = 0
	_saved_collected = 0
	_ceiling.global_position.y = (camera_start_y if p == Phase.CLIMB else camera_top_y) - 360.0
	_restore.call_deferred(p)

# --- Techo invisible y carteles ---

## Techo que sigue al borde de arriba de la cámara (no se sube más allá de la
## pantalla). WorldBoundaryShape2D: TerrainArt no lo dibuja.
func _make_ceiling() -> void:
	_ceiling = StaticBody2D.new()
	_ceiling.name = "Ceiling"
	var shape := CollisionShape2D.new()
	var line := WorldBoundaryShape2D.new()
	line.normal = Vector2(0, 1)
	shape.shape = line
	_ceiling.add_child(shape)
	add_child(_ceiling)
	_ceiling.global_position = Vector2(640, _camera.global_position.y - 360.0)

func _make_banner() -> void:
	var ui := get_node_or_null(^"../UI") as CanvasLayer
	if ui == null:
		return
	_banner = Label.new()
	_banner.name = "BossBanner"
	_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_banner.offset_top = 96.0
	_banner.offset_bottom = 170.0
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font := FontVariation.new()
	font.variation_embolden = 0.9
	var ls := LabelSettings.new()
	ls.font = font
	ls.font_size = 44
	ls.font_color = Color(1, 0.88, 0.5)
	ls.outline_size = 12
	ls.outline_color = Color(0.03, 0.04, 0.1)
	ls.shadow_size = 6
	ls.shadow_color = Color(0, 0, 0, 0.45)
	ls.shadow_offset = Vector2(0, 4)
	_banner.label_settings = ls
	_banner.modulate.a = 0.0
	ui.add_child(_banner)

## Cartel grande arriba al centro (clave de textos.csv), con fundido.
func _show_banner(key: String, hold: float = 2.2) -> void:
	if _banner == null:
		return
	_banner.text = key
	if _banner_tween != null:
		_banner_tween.kill()
	_banner.pivot_offset = Vector2(_banner.size.x * 0.5, 37)
	_banner.scale = Vector2.ONE * 1.25
	_banner_tween = create_tween().set_parallel()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.25)
	_banner_tween.tween_property(_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_property(_banner, "modulate:a", 0.0, 0.5).set_delay(hold)
