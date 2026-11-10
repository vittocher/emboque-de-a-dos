extends Node
class_name TensionFx

## Subida de tensión mientras los extremos se acercan. La crea y la alimenta el
## CloseupManager con su cercanía (0..1, la misma del zoom: parte con el zoom-in):
## - Silencio antes del golpe: la música suena normal todo el acercamiento y cae de
##   golpe al silencio (y los demás efectos bajan) justo antes del click: lo dispara
##   el WinManager (silence_lead) con set_silent(). Un "bajón" rápido que enfatiza
##   el impacto; el click suena en el silencio.
## - Viñeta: los bordes de la pantalla se oscurecen.
## - Halo dorado que late (cada vez más rápido) en el palito y la campana.
## Al embocar (release()) los efectos vuelven al instante (el click suena pleno),
## la viñeta y el halo se apagan y la música vuelve con un fundido, un poco después.
## Para ajustar el efecto, editar scenes/fx/tension_fx.tscn.

@export_group("Silencio")
## Volumen de la música en el silencio (dB; −60 = muda).
@export var music_duck_db: float = -60.0
## Segundos (reales) del bajón (rápido) y de la vuelta si el palito se sale sin
## embocar. Cuándo cae lo decide el WinManager (silence_lead).
@export var silence_drop_time: float = 0.06
@export var silence_recover_time: float = 0.3
## Cuánto bajan los demás efectos (pasos, viento...) en el silencio (dB).
@export var sfx_duck_db: float = -14.0
## Tras embocar, la música espera esto (s reales) y vuelve en music_return_time
## (0 = de golpe).
@export var music_return_delay: float = 0.4
@export var music_return_time: float = 0.3

@export_group("Viñeta")
## Fuerza de la viñeta pegados (0..1).
@export var vignette_strength: float = 0.7

@export_group("Halo")
## Color y opacidad máxima del halo en cada extremo.
@export var halo_color: Color = Color(1.0, 0.8, 0.35, 0.6)
## Diámetro del halo pegados (px del mundo).
@export var halo_size: float = 40.0
## Latido: rapidez (rad/s) al empezar y pegados.
@export var halo_pulse_slow: float = 4.0
@export var halo_pulse_fast: float = 16.0

@export_group("Al embocar")
## Segundos (reales) en que se apagan viñeta y halo.
@export var release_time: float = 0.3

@onready var _vignette: ColorRect = $Vignette/Rect

static var _halo_texture: Texture2D

var _t: float = 0.0
var _fade: float = 1.0        # viñeta y halo (0 tras embocar)
var _music_fade: float = 1.0  # cuánto del silencio de la música se aplica
var _sfx_fade: float = 1.0    # cuánto de la bajada de efectos se aplica
var _released: bool = false
var _phase: float = 0.0
var _halos: Array[Sprite2D] = []
var _silent: bool = false     # silencio pedido (justo antes del click)
var _sil: float = 0.0         # cuánto silencio se aplica ahora (0..1)

func _ready() -> void:
	_vignette.visible = false

## Cada cuadro (lo llama el CloseupManager): cercanía 0..1, segundos reales y los
## dos emboques (para poner el halo en sus extremos cuando existan).
func update(t: float, real_delta: float, a: Emboque, b: Emboque) -> void:
	_t = t
	if _halos.is_empty():
		_make_halos([a, b])
	var k := _t * _fade
	_phase += real_delta * lerpf(halo_pulse_slow, halo_pulse_fast, _t)

	# Silencio antes del golpe: bajón rápido cuando lo pide el WinManager.
	var step_time := silence_drop_time if _silent else silence_recover_time
	_sil = move_toward(_sil, 1.0 if _silent else 0.0, real_delta / maxf(step_time, 0.001))
	_apply_silence()

	# Viñeta.
	var v := vignette_strength * smoothstep(0.0, 1.0, k)
	_vignette.visible = v > 0.002
	(_vignette.material as ShaderMaterial).set_shader_parameter("strength", v)

	# Halo que late.
	var pulse := 0.7 + 0.3 * sin(_phase)
	for halo in _halos:
		if not is_instance_valid(halo):
			continue
		halo.visible = k > 0.005
		halo.modulate = Color(halo_color, halo_color.a * k * pulse)
		var size := halo_size * (0.6 + 0.4 * _t) * (0.95 + 0.05 * sin(_phase))
		halo.scale = Vector2.ONE * size / float(_halo_texture.get_width())

## Silencio antes del golpe: true justo antes del click; false si se deshizo.
func set_silent(on: bool) -> void:
	if not _released:
		_silent = on

## Al embocar: los efectos vuelven al instante (el click suena pleno), la viñeta y
## el halo se apagan y la música vuelve después (de golpe, o con un fundido si
## music_return_time > 0).
func release() -> void:
	if _released:
		return
	_released = true
	_sfx_fade = 0.0
	_apply_silence()
	var tw := create_tween().set_ignore_time_scale(true).set_parallel(true)
	tw.tween_property(self, "_fade", 0.0, release_time)
	if music_return_time > 0.0:
		tw.tween_property(self, "_music_fade", 0.0, music_return_time) \
			.set_delay(music_return_delay).set_trans(Tween.TRANS_SINE)
	else:
		tw.tween_callback(_music_back).set_delay(music_return_delay)
	tw.chain().tween_callback(_apply_silence)

## La música vuelve de golpe.
func _music_back() -> void:
	_music_fade = 0.0
	_apply_silence()

func _apply_silence() -> void:
	var s := _sil
	SettingsManager.set_music_duck(music_duck_db * s * _music_fade)
	SettingsManager.set_sfx_duck(sfx_duck_db * s * _sfx_fade)

func _make_halos(emboques: Array) -> void:
	if _halo_texture == null:
		_halo_texture = _make_halo_texture()
	for e in emboques:
		var end: Node2D = e.get_end() if e != null else null
		if end == null:
			_halos.clear()
			return
		var halo := Sprite2D.new()
		halo.name = "TensionHalo"
		halo.texture = _halo_texture
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		halo.material = mat
		halo.z_index = 1  # encima del extremo (luz que se suma)
		halo.visible = false
		end.add_child(halo)
		_halos.append(halo)

## Anillo de luz: casi transparente al centro (no lava el dibujo del extremo), más
## intenso alrededor y difuso hacia afuera.
static func _make_halo_texture() -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 0.5, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	return tex

func _notification(what: int) -> void:
	# En el menú de pausa todo suena normal; al volver, retoma el silencio.
	if what == NOTIFICATION_PAUSED:
		SettingsManager.set_music_duck(0.0)
		SettingsManager.set_sfx_duck(0.0)
	elif what == NOTIFICATION_UNPAUSED:
		_apply_silence()

func _exit_tree() -> void:
	SettingsManager.set_music_duck(0.0)
	SettingsManager.set_sfx_duck(0.0)
