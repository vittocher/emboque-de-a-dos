extends RefCounted
class_name Channel

## Canales que conectan placas de presión con compuertas y plataformas móviles.
## Una compuerta (o plataforma) de canal N se activa mientras alguna placa de
## canal N esté presionada (o todas, según su "require_all"). Cada canal tiene
## un color, que llevan la placa y lo que activa: así se lee qué abre qué.

## Amarillo, celeste, rosado, morado (sin verde: es el color de lanzar).
const COLORS: Array[Color] = [
	Color(0.98, 0.78, 0.22), Color(0.35, 0.75, 0.98), Color(0.98, 0.46, 0.62), Color(0.68, 0.5, 0.95),
]
## Grupo de las placas y grupo de quienes escuchan los cambios.
const PLATES := &"pressure_plates"
const LISTENERS := &"channel_listeners"

static func color(channel: int) -> Color:
	return COLORS[posmod(channel, COLORS.size())]

## True si el canal está activo: alguna placa (o todas, con [param require_all])
## de ese canal presionada.
static func is_active(tree: SceneTree, channel: int, require_all := false) -> bool:
	var any := false
	for plate in tree.get_nodes_in_group(PLATES):
		if plate.channel != channel:
			continue
		if plate.pressed:
			any = true
		elif require_all:
			return false
	return any

## Avisa a compuertas y plataformas que un canal cambió.
static func notify(tree: SceneTree, channel: int) -> void:
	tree.call_group(LISTENERS, &"_on_channel_changed", channel)
