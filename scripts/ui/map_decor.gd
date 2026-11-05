extends Control

## Fondo del mapa de niveles: círculos grandes de color como los de la portada
## (azul arriba a la izquierda, rojo abajo a la derecha), muy tenues.

func _draw() -> void:
	draw_circle(Vector2(90, 40), 330, Color(0.16, 0.29, 0.71, 0.55))
	draw_circle(Vector2(1260, 760), 260, Color(0.80, 0.25, 0.16, 0.45))
	draw_circle(Vector2(1240, 10), 150, Color(0.30, 0.31, 0.38, 0.35))
