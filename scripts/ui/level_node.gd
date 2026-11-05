extends Control
class_name LevelNode

## Un nivel en el mapa: disco de madera (mismo shader que los botones del menú)
## con su número. Estados: bloqueado (oscuro, sin número), disponible (madera
## con un anillo que late: "jugá este") y completado (número dorado; una
## sopaipilla al lado si se juntaron todas).

signal chosen(level_id: String)
signal focused(level_id: String)

const SIZE := 64.0

var level_id := ""
var unlocked := false
var completed := false
var all_collected := false

@onready var _fondo: ColorRect = $Fondo
@onready var _number: Label = $Number
@onready var _btn: Button = $Btn
@onready var _ring: Control = $Ring
@onready var _sopaipilla: TextureRect = $Sopaipilla

var _hover := false
var _focus := false
var _pulse := 0.0
var _base_scale := 1.0

func _ready() -> void:
	pivot_offset = Vector2(SIZE, SIZE) * 0.5
	_btn.pressed.connect(func() -> void: chosen.emit(level_id))
	_btn.mouse_entered.connect(func() -> void:
		_hover = true
		_btn.grab_focus())
	_btn.mouse_exited.connect(func() -> void: _hover = false; _refresh())
	_btn.focus_entered.connect(func() -> void:
		_focus = true
		_refresh()
		focused.emit(level_id))
	_btn.focus_exited.connect(func() -> void: _focus = false; _refresh())
	_ring.draw.connect(_draw_ring)

func setup(id: String, number: int, is_unlocked: bool, is_completed: bool, got_all: bool,
		special: bool = false) -> void:
	level_id = id
	unlocked = is_unlocked
	completed = is_completed
	all_collected = got_all
	_number.text = str(number) if unlocked else ""
	_sopaipilla.visible = completed and all_collected
	var mat := _fondo.material as ShaderMaterial
	if not unlocked:
		mat.set_shader_parameter("wood_dark", Color(0.10, 0.09, 0.10))
		mat.set_shader_parameter("wood_light", Color(0.22, 0.19, 0.19))
		mat.set_shader_parameter("gold_dim", Color(0.28, 0.25, 0.25))
	elif special:
		# El final: madera dorada y más grande.
		mat.set_shader_parameter("wood_dark", Color(0.45, 0.28, 0.06))
		mat.set_shader_parameter("wood_light", Color(0.86, 0.62, 0.22))
		mat.set_shader_parameter("gold_dim", Color(0.98, 0.82, 0.3))
	if completed:
		_number.add_theme_color_override("font_color", Color(1.0, 0.86, 0.38))
	_base_scale = 1.3 if special else 1.0
	scale = Vector2.ONE * _base_scale
	_refresh()

func button() -> Button:
	return _btn

func _process(delta: float) -> void:
	_pulse += delta
	if unlocked and not completed:
		_ring.queue_redraw()

func _refresh() -> void:
	var active := _focus or _hover
	(_fondo.material as ShaderMaterial).set_shader_parameter("active", 1.0 if active else 0.0)
	var target := Vector2.ONE * _base_scale * (1.14 if active else 1.0)
	create_tween().tween_property(self, "scale", target, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Anillo que late alrededor de los niveles disponibles sin completar.
func _draw_ring() -> void:
	if not unlocked or completed:
		return
	var t := 0.5 + 0.5 * sin(_pulse * 3.2)
	var center := Vector2(SIZE, SIZE) * 0.5
	_ring.draw_arc(center, SIZE * 0.5 + 6.0 + t * 4.0, 0.0, TAU, 48,
		Color(0.98, 0.82, 0.30, 0.25 + 0.45 * (1.0 - t)), 3.0, true)

## Aparición (al desbloquearse recién).
func pop_in(delay: float) -> void:
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "scale", Vector2.ONE * _base_scale, 0.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Sacudida corta (al intentar entrar a un nivel bloqueado).
func shake() -> void:
	var base := position
	var tween := create_tween()
	for dx in [-6.0, 6.0, -4.0, 4.0, 0.0]:
		tween.tween_property(self, "position", base + Vector2(dx, 0), 0.04)
