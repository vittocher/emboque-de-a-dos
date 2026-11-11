shader_type canvas_item;
render_mode blend_premul_alpha;

// Sombra o luz difusa alrededor de un RECTÁNGULO (terreno, zonas de peligro).
// Va en un ColorRect más grande que la caja (margin por lado) y centrado en ella.
// Dos capas: una corrida (sombra proyectada / luz que sube) y una centrada que
// oscurece el contorno (oclusión ambiental). Lo usan TerrainArt y HazardArt.

// Tamaño de la caja, en px.
uniform vec2 box_size = vec2(100.0, 30.0);
// Borde extra del ColorRect a cada lado, en px.
uniform vec2 margin = vec2(40.0, 40.0);
// Color; el alfa es la opacidad máxima.
uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.0, 0.4);
// Capa corrida: corrimiento (px, en el espacio del rectángulo) y difuminado.
uniform vec2 offset = vec2(0.0, 0.0);
uniform float radius = 12.0;
// Capa centrada (contorno): opacidad relativa (0 = sin ella) y difuminado.
uniform float ao_strength = 0.0;
uniform float ao_radius = 6.0;
// Esquinas redondeadas (px).
uniform float corner = 3.0;
// 0 = sombra (tapa), 1 = luz (se suma).
uniform float additive = 0.0;
// Parpadeo: fuerza (0..1), rapidez y respiración lenta (0..1).
uniform float flicker = 0.0;
uniform float flicker_speed = 1.0;
uniform float breathe = 0.0;
// Degradado desde el centro (luces): > 0 = la capa corrida ya no es pareja dentro
// de la caja, sino que va de `core` × alfa en la línea central hasta 0 a `radius`
// px fuera del borde. `core_power` = curva (más alto = centro más concentrado).
uniform float core = 0.0;
uniform float core_power = 2.0;

varying float v_seed;

float sd_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

// 1 dentro de la caja, cae suave afuera (casi 0 a la distancia rad).
float falloff(float d, float rad) {
	float x = max(d, 0.0) / max(rad, 0.001);
	return exp(-x * x * 3.0);
}

void vertex() {
	v_seed = MODEL_MATRIX[3].x * 0.011 + MODEL_MATRIX[3].y * 0.017;
}

void fragment() {
	vec2 p = UV * (box_size + margin * 2.0) - margin - box_size * 0.5;
	vec2 half_box = box_size * 0.5;
	float cr = min(corner, min(half_box.x, half_box.y));
	float d = sd_box(p - offset, half_box, cr);
	float drop;
	if (core > 0.0) {
		// Distancia normalizada: 0 en la línea central de la caja, 1 a radius del borde.
		float depth = min(half_box.x, half_box.y);
		float t = clamp((d + depth) / max(depth + radius, 0.001), 0.0, 1.0);
		drop = pow(1.0 - t, core_power) * core;
	} else {
		drop = falloff(d, radius);
	}
	float ao = falloff(sd_box(p, half_box, cr), ao_radius) * ao_strength;
	float a = 1.0 - (1.0 - drop) * (1.0 - clamp(ao, 0.0, 1.0));
	float f = 1.0;
	float t = TIME * flicker_speed;
	if (flicker > 0.0) {
		float n = 0.5 + 0.5 * sin(t * 9.1 + v_seed * 17.0) * sin(t * 4.3 + v_seed * 3.0);
		f -= flicker * n;
	}
	if (breathe > 0.0) {
		f *= 1.0 - breathe * (0.5 + 0.5 * sin(t * 1.7 + v_seed * 7.0));
	}
	float k = a * tint.a * f * COLOR.a;
	COLOR = vec4(tint.rgb * k, k * (1.0 - additive));
}
