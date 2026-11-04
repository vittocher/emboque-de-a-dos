class_name IntroScreen
extends Control

## Intro del juego: reproduce el video de introducción (la historia) cada vez que
## arranca el juego y luego pasa al menú principal. Se salta con cualquier tecla
## (también clic o botón de control). Es la escena de arranque (run/main_scene).
##
## Formato: Godot solo reproduce video Ogg Theora (.ogv). Ver video/README.md.
## Si el archivo no existe, pasa directo al menú (el juego nunca se queda trabado).
##
## Web: el navegador no deja sonar audio hasta el primer gesto del usuario, así que
## en web se muestra primero "Presiona cualquier tecla para comenzar" (ese gesto
## desbloquea el audio) y recién ahí parte el video, con sonido.

## Se pone en true al salir de la intro; el menú principal lo usa para aparecer
## desde negro (continuidad con el fundido de salida) y luego lo apaga.
static var fade_menu_in := false

@export_file("*.ogv") var video_path := "res://video/intro.ogv"
@export_file("*.tscn") var next_scene := "res://scenes/ui/main_menu.tscn"
## Bus de audio del video (narración + música propia del video).
@export var video_bus := &"Master"
## Ignora teclas durante este tiempo al empezar (evita saltarla con una tecla
## que venía apretada desde antes de abrir el juego).
@export var skip_guard_time := 0.35
## Segundos antes de que aparezca el mensaje para saltar.
@export var hint_delay := 0.6
@export var fade_in_time := 0.6
@export var fade_out_time := 0.5
## Fade-in de la música del menú tras la intro.
@export var music_fade_in_time := 1.5

enum State { WAITING_GESTURE, PLAYING, LEAVING }

var _state := State.PLAYING
var _elapsed := 0.0
var _hint_time := 0.0
var _video_ratio_set := false

@onready var _frame: AspectRatioContainer = $Frame
@onready var _video: VideoStreamPlayer = $Frame/Video
@onready var _hint: Label = $Hint
@onready var _start_prompt: Label = $StartPrompt
@onready var _fade: ColorRect = $Fade

func _ready() -> void:
	# La música del juego no suena encima de la intro (el video trae su audio).
	SettingsManager.stop_music()
	_hint.modulate.a = 0.0
	_start_prompt.visible = false
	_fade.color.a = 1.0

	var stream := _load_video()
	if stream == null:
		_leave(true)
		return
	_video.stream = stream
	_video.bus = video_bus

	if OS.has_feature("web"):
		_state = State.WAITING_GESTURE
		_start_prompt.visible = true
		_fade.color.a = 0.0
	else:
		_start_video()

func _load_video() -> VideoStream:
	if video_path.is_empty() or not ResourceLoader.exists(video_path):
		push_warning("Intro: no está el video %s; se pasa directo al menú." % video_path)
		return null
	var stream := load(video_path) as VideoStream
	if stream == null:
		push_warning("Intro: no se pudo cargar %s (¿es Ogg Theora .ogv?)." % video_path)
	return stream

func _start_video() -> void:
	_state = State.PLAYING
	_elapsed = 0.0
	_hint_time = 0.0
	_start_prompt.visible = false
	_video.finished.connect(_on_video_finished)
	_video.play()
	create_tween().tween_property(_fade, "color:a", 0.0, fade_in_time)

func _process(delta: float) -> void:
	if _state == State.WAITING_GESTURE:
		_start_prompt.modulate.a = _pulse(_elapsed)
		_elapsed += delta
		return
	if _state != State.PLAYING:
		return
	_elapsed += delta
	_fit_video_aspect()
	# Mensaje para saltar: aparece suave y luego "respira" sin distraer.
	if _elapsed >= hint_delay:
		_hint_time += delta
		var appear := clampf(_hint_time / 0.5, 0.0, 1.0)
		_hint.modulate.a = appear * _pulse(_hint_time)

## Alfa entre 0.7 y 1 en un ciclo de ~2,4 s (siempre legible).
func _pulse(t: float) -> float:
	return 0.85 + 0.15 * cos(t * TAU / 2.4)

## Ajusta el marco a la proporción real del video (franjas negras si no es 16:9).
func _fit_video_aspect() -> void:
	if _video_ratio_set:
		return
	var tex := _video.get_video_texture()
	if tex == null:
		return
	var size := tex.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_frame.ratio = size.x / size.y
	_video_ratio_set = true

func _input(event: InputEvent) -> void:
	if not _is_skip_event(event):
		return
	match _state:
		State.WAITING_GESTURE:
			get_viewport().set_input_as_handled()
			_start_video()
		State.PLAYING:
			if _elapsed < skip_guard_time:
				return
			get_viewport().set_input_as_handled()
			_leave()
		State.LEAVING:
			# Que la tecla no llegue al menú mientras se funde a negro.
			get_viewport().set_input_as_handled()

## Cualquier tecla, clic o botón de control, solo al apretar (no al soltar ni
## repetición por mantenerla).
func _is_skip_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton or event is InputEventJoypadButton:
		return event.pressed
	return false

func _on_video_finished() -> void:
	if _state == State.PLAYING:
		_leave()

func _leave(immediate := false) -> void:
	if _state == State.LEAVING:
		return
	_state = State.LEAVING
	fade_menu_in = true
	if immediate:
		_go_next.call_deferred()
		return
	var tween := create_tween().set_parallel()
	tween.tween_property(_fade, "color:a", 1.0, fade_out_time)
	tween.tween_property(_hint, "modulate:a", 0.0, fade_out_time * 0.6)
	# El audio del video también se funde (sin corte seco).
	tween.tween_property(_video, "volume_db", -40.0, fade_out_time)
	tween.chain().tween_callback(_go_next)

func _go_next() -> void:
	_video.stop()
	SettingsManager.play_music(music_fade_in_time)
	get_tree().change_scene_to_file(next_scene)
