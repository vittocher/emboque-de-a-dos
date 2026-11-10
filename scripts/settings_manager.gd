extends Node

## AUTOLOAD (SettingsManager). Volumen (general/música/efectos), pantalla completa,
## idioma (ver Languages) y persistencia. Los buses "Music" y "SFX" vienen en res://default_bus_layout.tres
## (Godot lo carga al arrancar); _ensure_buses() solo es un respaldo.

const SETTINGS_PATH := "user://settings.cfg"
const MUSIC_PATH := "res://audio/cueca.ogg"
const DEFAULT_MASTER_VOLUME := 1.0
const DEFAULT_MUSIC_VOLUME := 1.0
const DEFAULT_SFX_VOLUME := 1.0
const DEFAULT_FULLSCREEN := false
## Nombres de los buses de audio (Master es el bus 0 del motor). Music y SFX
## envían a Master: así Master queda como fader general y Music/SFX se balancean
## aparte.
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

var master_volume: float = DEFAULT_MASTER_VOLUME
var music_volume: float = DEFAULT_MUSIC_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME
var fullscreen: bool = DEFAULT_FULLSCREEN
## Código del idioma (ver Languages). Vacío hasta cargar: la primera vez se usa
## el del sistema si el juego lo tiene.
var language: String = ""

var _music_player: AudioStreamPlayer
var _music_tween: Tween
## true mientras alguien (la intro) pidió silencio.
var _music_held := false
var _music_duck_db := 0.0  # bajada temporal de la música (subida de tensión del emboque)
var _sfx_duck_db := 0.0    # bajada temporal de los efectos (ídem)

func _ready() -> void:
	_ensure_buses()
	_load_settings()
	_apply_settings()
	_start_music()

func _exit_tree() -> void:
	if _music_player != null:
		_music_player.stop()

## Respaldo: crea los buses Music y SFX si faltaran (p. ej. si alguien borra
## default_bus_layout.tres). OJO: en web, un bus creado en runtime deja el audio
## mudo (el motor web los desordena), así que el layout tiene que existir; esto
## solo evita errores en escritorio.
func _ensure_buses() -> void:
	for bus_name in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume("Master", master_volume)
	_save_settings()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(MUSIC_BUS, music_volume)
	_save_settings()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(SFX_BUS, sfx_volume)
	_save_settings()

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_window_mode()
	_save_settings()

## Cambia el idioma de todo el juego (los textos en pantalla se actualizan solos).
func set_language(code: String) -> void:
	if not Languages.available().has(code):
		code = Languages.DEFAULT
	language = code
	TranslationServer.set_locale(language)
	_save_settings()

## Pasa al idioma siguiente de la lista (botón de idioma del menú principal).
func cycle_language() -> void:
	set_language(Languages.next_after(language))

## Restaura volúmenes y pantalla (el idioma se mantiene: no es un "valor").
func reset_to_defaults() -> void:
	master_volume = DEFAULT_MASTER_VOLUME
	music_volume = DEFAULT_MUSIC_VOLUME
	sfx_volume = DEFAULT_SFX_VOLUME
	fullscreen = DEFAULT_FULLSCREEN
	_apply_settings()
	_save_settings()

func _apply_settings() -> void:
	_apply_bus_volume("Master", master_volume)
	_apply_bus_volume(MUSIC_BUS, music_volume)
	_apply_bus_volume(SFX_BUS, sfx_volume)
	# En web el navegador solo deja entrar a pantalla completa tras un clic o
	# tecla: el juego arranca en ventana (se activa desde Ajustes).
	if OS.has_feature("web"):
		fullscreen = false
	else:
		_apply_window_mode()
	if language == "" or not Languages.available().has(language):
		language = Languages.system_default()
	TranslationServer.set_locale(language)

func _apply_bus_volume(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	# maxf evita -inf en linear_to_db(0), que silenciaría el bus para siempre.
	var db := linear_to_db(maxf(value, 0.0001))
	if bus_name == MUSIC_BUS:
		db += _music_duck_db
	elif bus_name == SFX_BUS:
		db += _sfx_duck_db
	AudioServer.set_bus_volume_db(idx, db)

func _apply_window_mode() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	get_window().mode = (
		Window.MODE_FULLSCREEN
		if fullscreen
		else Window.MODE_WINDOWED
	)

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = clampf(
		float(config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)),
		0.0,
		1.0
	)
	music_volume = clampf(
		float(config.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME)),
		0.0,
		1.0
	)
	sfx_volume = clampf(
		float(config.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME)),
		0.0,
		1.0
	)
	fullscreen = bool(config.get_value("display", "fullscreen", DEFAULT_FULLSCREEN))
	language = String(config.get_value("general", "language", ""))

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("general", "language", language)
	config.save(SETTINGS_PATH)

func _start_music() -> void:
	var stream := load(MUSIC_PATH) as AudioStream
	if stream == null:
		push_warning("No se pudo cargar la música: %s" % MUSIC_PATH)
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = stream
	_music_player.bus = MUSIC_BUS
	# Sigue sonando en la pausa (si no, el volumen de música no se oye al ajustarlo).
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)
	# Diferido: si la escena de arranque es la intro, alcanza a pedir silencio
	# (stop_music) antes de que suene el primer instante de la cueca.
	_play_initial_music.call_deferred()

func _play_initial_music() -> void:
	if not _music_held:
		_music_player.play()

## Detiene la música (la intro la apaga mientras corre el video).
func stop_music() -> void:
	_music_held = true
	if _music_player == null:
		return
	if _music_tween != null:
		_music_tween.kill()
	_music_player.stop()

## Tono/velocidad de la música (1 = normal; menos = más lenta y grave, como una
## cinta frenada). Lo usa el CloseupManager para que la cámara lenta del emboque
## también se escuche; al salir del nivel vuelve a 1.
func set_music_pitch(pitch: float) -> void:
	if _music_player != null:
		_music_player.pitch_scale = clampf(pitch, 0.05, 4.0)

## Baja temporalmente la música (dB, 0 = normal) sin tocar el volumen elegido en
## Ajustes: la usa la subida de tensión del emboque (TensionFx) para que el click
## suene en el silencio. Se aplica sobre el bus Music.
func set_music_duck(db: float) -> void:
	_music_duck_db = minf(db, 0.0)
	_apply_bus_volume(MUSIC_BUS, music_volume)

## Igual que set_music_duck, para el bus de efectos (SFX).
func set_sfx_duck(db: float) -> void:
	_sfx_duck_db = minf(db, 0.0)
	_apply_bus_volume(SFX_BUS, sfx_volume)

## Reinicia la música desde el principio, con fundido de entrada opcional.
## No hace nada si ya está sonando.
func play_music(fade_in_time: float = 0.0) -> void:
	_music_held = false
	if _music_player == null or _music_player.playing:
		return
	if _music_tween != null:
		_music_tween.kill()
	_music_player.volume_db = -40.0 if fade_in_time > 0.0 else 0.0
	_music_player.play()
	if fade_in_time > 0.0:
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", 0.0, fade_in_time)
