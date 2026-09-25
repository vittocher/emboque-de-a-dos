extends Node

## AUTOLOAD (SettingsManager). Volumen (general/música/efectos), pantalla completa
## y persistencia. Los buses "Music" y "SFX" vienen en res://default_bus_layout.tres
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

var _music_player: AudioStreamPlayer

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
	_apply_window_mode()

func _apply_bus_volume(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	# maxf evita -inf en linear_to_db(0), que silenciaría el bus para siempre.
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.0001)))

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

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "fullscreen", fullscreen)
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
	add_child(_music_player)
	_music_player.play()
