shader_type canvas_item;

// Botón de madera procedural con esquinas redondeadas, borde dorado y glow al
// enfocar. Se dibuja sobre un ColorRect (UV 0..1 = todo el rect). El script pasa
// rect_size (tamaño en px) y active (0 normal, 1 resaltado).

uniform vec2 rect_size = vec2(460.0, 88.0);
uniform float active = 0.0;
uniform float corner = 16.0;
uniform vec4 wood_dark : source_color = vec4(0.24, 0.13, 0.07, 1.0);
uniform vec4 wood_light : source_color = vec4(0.52, 0.33, 0.17, 1.0);
uniform vec4 gold : source_color = vec4(0.98, 0.82, 0.30, 1.0);
uniform vec4 gold_dim : source_color = vec4(0.60, 0.43, 0.13, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 5; i++) {
		v += amp * noise(p);
		p *= 2.0;
		amp *= 0.5;
	}
	return v;
}

// Distancia con signo a un rectángulo de esquinas redondeadas (negativo = dentro).
float rounded_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 pos = UV * rect_size;
	vec2 p = pos - rect_size * 0.5;
	float d = rounded_box(p, rect_size * 0.5, corner);
	float alpha = 1.0 - smoothstep(-1.0, 0.5, d);

	// Veta de madera: fibras largas horizontales + estrías finas verticales.
	float grain = fbm(vec2(UV.x * 4.0, UV.y * 26.0));
	float streak = fbm(vec2(UV.x * 48.0, UV.y * 3.0)) * 0.5;
	float w = clamp(grain * 0.7 + streak, 0.0, 1.0);
	vec3 wood = mix(wood_dark.rgb, wood_light.rgb, smoothstep(0.25, 0.85, w));
	// Luz suave: arriba más claro, abajo más oscuro (volumen).
	wood *= mix(1.12, 0.80, UV.y);

	// Borde dorado (más grueso y brillante cuando está activo).
	float border_w = mix(3.0, 5.5, active);
	float edge = smoothstep(-border_w - 1.0, -border_w + 1.5, d);
	vec3 gcol = mix(gold_dim.rgb, gold.rgb, active);
	vec3 col = mix(wood, gcol, clamp(edge, 0.0, 1.0));

	// Glow interior dorado al enfocar.
	if (active > 0.5) {
		float glow = smoothstep(-18.0, 0.0, d);
		col = mix(col, gold.rgb, glow * 0.35);
	}

	COLOR = vec4(col, alpha);
}
