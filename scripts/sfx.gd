extends Node

## AUTOLOAD (Sfx). Efectos de sonido del juego, todos registrados en un solo lugar.
## Para cambiar un sonido: reemplazar el archivo (mismo nombre, en audio/sfx/) o
## cambiar su ruta en SOUNDS. Los placeholders se generan con tools/generate_sfx.py.
## Vive fuera de los niveles para que un sonido no se corte cuando el nivel se
## recarga (p. ej. al morir).

## Se emite cada vez que suena un efecto (útil para tests y depuración).
signal played(sound: StringName)

## nombre → [ruta, volumen base en dB]
const SOUNDS := {
	&"step": ["res://audio/sfx/step.wav", -12.0],
	&"jump": ["res://audio/sfx/jump.wav", -8.0],
	&"die": ["res://audio/sfx/die.wav", -4.0],
	&"hook": ["res://audio/sfx/hook.wav", -6.0],
	&"swing": ["res://audio/sfx/swing.wav", -6.0],
	&"box_push": ["res://audio/sfx/box_push.wav", -8.0],
	&"grab": ["res://audio/sfx/grab.wav", -8.0],
	&"throw": ["res://audio/sfx/throw.wav", -6.0],
}
## Cuántos efectos pueden sonar a la vez.
const POOL_SIZE := 12

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _next_steal := 0
var _last_frame := {}  # sonido → tick de física en que sonó

func _ready() -> void:
	for sound: StringName in SOUNDS:
		var stream := load(SOUNDS[sound][0]) as AudioStream
		if stream == null:
			push_warning("No se pudo cargar el efecto '%s': %s" % [sound, SOUNDS[sound][0]])
			continue
		_streams[sound] = stream
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = SettingsManager.SFX_BUS
		add_child(player)
		_pool.append(player)

## Reproduce un efecto. pitch y volume_db se suman a los valores base.
func play(sound: StringName, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _streams.get(sound)
	if stream == null:
		return
	# El mismo sonido dos veces en el mismo tick (p. ej. las dos partes de una
	# zona de muerte "ambos") suena una sola vez.
	var frame := Engine.get_physics_frames()
	if _last_frame.get(sound, -1) == frame:
		return
	_last_frame[sound] = frame
	var player := _free_player()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = base_volume(sound) + volume_db
	player.play()
	played.emit(sound)

## El stream de un efecto (para loops que maneja su dueño, como la caja).
func get_stream(sound: StringName) -> AudioStream:
	return _streams.get(sound)

func base_volume(sound: StringName) -> float:
	return SOUNDS[sound][1] if SOUNDS.has(sound) else 0.0

## Activa el loop de un stream (sirve para WAV u OGG, por si se reemplaza el formato).
static func make_looping(stream: AudioStream) -> void:
	var wav := stream as AudioStreamWAV
	if wav != null:
		if wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			# En frames; se calcula por duración para que valga con cualquier compresión.
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = int(wav.get_length() * wav.mix_rate)
	elif stream is AudioStreamOggVorbis:
		stream.loop = true

func _free_player() -> AudioStreamPlayer:
	for player in _pool:
		if not player.playing:
			return player
	# Todos ocupados: se reutiliza el más antiguo.
	var stolen := _pool[_next_steal]
	_next_steal = (_next_steal + 1) % POOL_SIZE
	return stolen
