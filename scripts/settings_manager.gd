extends Node

const SETTINGS_PATH := "user://settings.cfg"
const MUSIC_PATH := "res://audio/cueca.ogg"
const DEFAULT_MASTER_VOLUME := 1.0
const DEFAULT_FULLSCREEN := false

var master_volume: float = DEFAULT_MASTER_VOLUME
var fullscreen: bool = DEFAULT_FULLSCREEN

var _music_player: AudioStreamPlayer

func _ready() -> void:
	_load_settings()
	_apply_settings()
	_start_music()

func _exit_tree() -> void:
	if _music_player != null:
		_music_player.stop()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master, linear_to_db(maxf(master_volume, 0.0001)))
	_save_settings()

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_window_mode()
	_save_settings()

func reset_to_defaults() -> void:
	master_volume = DEFAULT_MASTER_VOLUME
	fullscreen = DEFAULT_FULLSCREEN
	_apply_settings()
	_save_settings()

func _apply_settings() -> void:
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master, linear_to_db(maxf(master_volume, 0.0001)))
	_apply_window_mode()

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
	fullscreen = bool(config.get_value("display", "fullscreen", DEFAULT_FULLSCREEN))

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
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
	add_child(_music_player)
	_music_player.play()