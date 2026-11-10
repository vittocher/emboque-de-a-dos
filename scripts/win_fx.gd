extends Node
class_name WinFx

## Efecto de partículas de la victoria (lo crea el WinManager al embocar): al
## entrar dispara todas las CPUParticles2D hijas, las hace correr en TIEMPO REAL
## (el closeup pone cámara lenta; sin esto el confetti flotaría 3 veces más lento)
## y se borra solo. Va en la raíz de scenes/fx/emboque_burst.tscn y
## scenes/fx/win_confetti.tscn; para cambiar el efecto, editar esas escenas.

## Ignorar la cámara lenta (Engine.time_scale).
@export var realtime := true
## Las partículas continuas (no one_shot, p. ej. destellos que quedan) dejan de
## salir a los N s reales.
@export var emit_time := 1.5
## Se borra a los N s reales.
@export var free_after := 4.0

var _t := 0.0
var _particles: Array[CPUParticles2D] = []

func _ready() -> void:
	for n in find_children("*", "CPUParticles2D", true, false):
		var p := n as CPUParticles2D
		_particles.append(p)
		p.restart()
	_update_speed()

func _process(delta: float) -> void:
	_t += delta / maxf(Engine.time_scale, 0.0001) if realtime else delta
	_update_speed()
	if _t >= emit_time:
		for p in _particles:
			if not p.one_shot:
				p.emitting = false
	if _t >= free_after:
		queue_free()

func _update_speed() -> void:
	var s := 1.0 / maxf(Engine.time_scale, 0.05) if realtime else 1.0
	for p in _particles:
		p.speed_scale = s
