extends Control

## Pantalla de victoria: nombre del nivel, puntaje, sopaipillas juntadas y récord.
## Lee los datos de la victoria desde ScoreBoard (el WinManager del nivel los deja
## ahí antes de cambiar a esta escena). Continuar vuelve al mapa de niveles (que
## anima lo que se desbloqueó); Reintentar vuelve a jugar el mismo nivel.
##
## Entrada animada: aparece desde el azul, el título cae y rebota, el puntaje y
## las sopaipillas se cuentan con un "tic" que sube de tono, un récord nuevo
## suena y late en dorado, y los botones entran uno tras otro. Los botones
## funcionan desde el primer cuadro (la animación no hace esperar a nadie).

const MAP_SCENE := "res://scenes/ui/level_selector.tscn"
const RECORD_COLOR := Color(1, 0.86, 0.38)
## Estrellitas doradas detrás del título (las mismas del emboque).
const BURST_SCENE := preload("res://scenes/fx/emboque_burst.tscn")
const BURST_SCALE := 2.2

@onready var _title: Label = $Center/VBox/TitleBox/Title
@onready var _subtitle: Label = $Center/VBox/Subtitle
@onready var _score: Label = $Center/VBox/ScoreLabel
@onready var _collected: Label = $Center/VBox/Collected/Count
@onready var _collected_row: Control = $Center/VBox/Collected
@onready var _record: Label = $Center/VBox/HighscoreLabel
@onready var _continue: BotonMadera = $Center/VBox/Buttons/ContinueButton
@onready var _retry: BotonMadera = $Center/VBox/Buttons/RetryButton

var _new_record := false
var _last_tick_ms := 0

func _ready() -> void:
	get_tree().paused = false
	if ScoreBoard.last_level_name != "":
		# last_level_name es una clave de traducción (niveles del catálogo) o un
		# nombre literal (niveles de prueba): tr() sirve para los dos.
		var level_name := tr(ScoreBoard.last_level_name)
		var number := LevelCatalog.number_of(ScoreBoard.last_level_id)
		_subtitle.text = level_name if number == 0 else "%d · %s" % [number, level_name]
	_show_score(ScoreBoard.last_score)
	_collected_row.visible = ScoreBoard.last_total > 0
	_show_collected(ScoreBoard.last_collected)
	var best := ScoreBoard.get_highscore(ScoreBoard.last_level_id)
	_new_record = ScoreBoard.last_is_record and ScoreBoard.last_score > 0
	if _new_record:
		_record.text = tr("VICTORY_NEW_RECORD")
		# El color va en su LabelSettings (un theme override no le gana).
		var settings := _record.label_settings.duplicate() as LabelSettings
		settings.font_color = RECORD_COLOR
		_record.label_settings = settings
	else:
		_record.text = tr("VICTORY_BEST") % best
	_continue.pressed.connect(_on_continue)
	_retry.pressed.connect(_on_retry)
	_retry.visible = _level_scene() != ""
	_continue.button().grab_focus()
	UiFx.reveal(0.45)
	_animate_entrance()

func _show_score(value: int) -> void:
	_score.text = tr("VICTORY_SCORE") % value

func _show_collected(value: int) -> void:
	_collected.text = "%d / %d" % [value, ScoreBoard.last_total]

func _animate_entrance() -> void:
	for item: CanvasItem in [_title, _subtitle, _score, _collected_row, _record]:
		item.modulate.a = 0.0
	_retry.appear(0.25)
	_continue.appear(0.33)
	# El pivote del título necesita su tamaño real: tras el primer layout.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_title.pivot_offset = _title.size * 0.5
	_title.scale = Vector2.ONE * 0.4
	var tween := create_tween()
	tween.tween_interval(0.12)
	tween.tween_property(_title, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(_title, "scale", Vector2.ONE, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_callback(_title_burst).set_delay(0.08)
	tween.parallel().tween_property(_subtitle, "modulate:a", 1.0, 0.25).set_delay(0.2)
	# Puntaje: se cuenta desde 0.
	tween.tween_property(_score, "modulate:a", 1.0, 0.15)
	if ScoreBoard.last_score > 0:
		_show_score(0)
		var seconds := clampf(ScoreBoard.last_score / 1500.0, 0.35, 0.8)
		tween.tween_method(_count_score, 0.0, float(ScoreBoard.last_score), seconds) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Sopaipillas: una a una.
	if _collected_row.visible:
		tween.tween_property(_collected_row, "modulate:a", 1.0, 0.15)
		if ScoreBoard.last_collected > 0:
			_show_collected(0)
			tween.tween_method(_count_collected, 0.0, float(ScoreBoard.last_collected),
				0.12 * ScoreBoard.last_collected)
	tween.tween_property(_record, "modulate:a", 1.0, 0.2)
	if _new_record:
		tween.tween_callback(_celebrate_record)

## Estallido de estrellitas detrás del título, al caer.
func _title_burst() -> void:
	var burst := BURST_SCENE.instantiate() as Node2D
	burst.position = _title.get_global_rect().get_center()
	burst.scale = Vector2.ONE * BURST_SCALE
	add_child(burst)
	move_child(burst, $Center.get_index())  # detrás del texto
	Sfx.play(&"sparkle")

func _count_score(value: float) -> void:
	_show_score(int(value))
	_tick(value / maxf(ScoreBoard.last_score, 1.0))

func _count_collected(value: float) -> void:
	var count := int(round(value))
	if _collected.text != "%d / %d" % [count, ScoreBoard.last_total]:
		_show_collected(count)
		Sfx.play(&"ui_tick", 1.1 + 0.12 * count)

## "Tic" del conteo, como mucho cada 45 ms, más agudo mientras más sube.
func _tick(progress: float) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_tick_ms < 45:
		return
	_last_tick_ms = now
	Sfx.play(&"ui_tick", lerpf(0.85, 1.6, progress))

## Récord nuevo: arpegio y un latido dorado que sigue mientras esté la pantalla.
func _celebrate_record() -> void:
	Sfx.play(&"ui_unlock")
	var pulse := create_tween().set_loops()
	pulse.tween_property(_record, "modulate", Color(1.35, 1.25, 1.0), 0.45) \
		.set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_record, "modulate", Color.WHITE, 0.45).set_trans(Tween.TRANS_SINE)

func _level_scene() -> String:
	return LevelCatalog.get_level(ScoreBoard.last_level_id).get("scene", "")

func _on_continue() -> void:
	UiFx.go_to(MAP_SCENE)

func _on_retry() -> void:
	UiFx.go_to(_level_scene())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if not UiFx.is_transitioning():
			Sfx.play(&"ui_confirm")
		_on_continue()
