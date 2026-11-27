shader_type canvas_item;

// Botón de madera procedural con esquinas redondeadas, borde dorado y brillo al
// resaltar. Se dibuja sobre un ColorRect (UV 0..1 = todo el rect). El script
// pasa rect_size (tamaño del rect en px) y active (0 normal … 1 resaltado).
//
// Opcionales para que se lea como un botón de verdad (con los valores por
// defecto queda la tabla plana de siempre, p. ej. las placas del HUD):
//   pad    margen libre alrededor del botón dentro del rect (px), para dibujar la
//          sombra y el halo dorado afuera del botón (el ColorRect es así de más
//          grande que el botón).
//   depth  alto del canto de la tabla (px): la cara va arriba y abajo se ve el
//          costado, más oscuro.
//   press  0 arriba … 1 hundido: la cara baja `depth` y tapa el canto.
//   shine  posición (0..1) del destello que cruza la cara en diagonal; < 0 = sin destello.

uniform vec2 rect_size = vec2(460.0, 88.0);
uniform float active = 0.0;
uniform float corner = 16.0;
uniform float pad = 0.0;
uniform float depth = 0.0;
uniform float press = 0.0;
uniform float shine = -1.0;
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
// El radio se limita a la mitad del lado más corto (un disco sigue siendo disco).
float rounded_box(vec2 p, vec2 b, float r) {
	r = min(r, min(b.x, b.y));
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 pos = UV * rect_size;
	// El botón ocupa el rect menos el margen `pad`.
	vec2 bsize = max(rect_size - vec2(2.0 * pad), vec2(1.0));
	vec2 bp = pos - vec2(pad);
	float off = press * depth;
	float face_h = max(bsize.y - depth, 1.0);

	// Cuerpo: desde el borde de arriba de la cara (baja al apretar) hasta abajo del canto.
	float d_body = rounded_box(bp - vec2(bsize.x * 0.5, (off + bsize.y) * 0.5),
		vec2(bsize.x * 0.5, (bsize.y - off) * 0.5), corner);
	// Cara: la tabla de arriba, corrida `off` hacia abajo.
	float d = rounded_box(bp - vec2(bsize.x * 0.5, off + face_h * 0.5),
		vec2(bsize.x * 0.5, face_h * 0.5), corner);
	// UV de la cara (la veta se mueve con ella al hundirse).
	vec2 fuv = (bp - vec2(0.0, off)) / vec2(bsize.x, face_h);

	// Veta de madera: fibras largas horizontales + estrías finas verticales.
	float grain = fbm(vec2(fuv.x * 4.0, fuv.y * 26.0));
	float streak = fbm(vec2(fuv.x * 48.0, fuv.y * 3.0)) * 0.5;
	float w = clamp(grain * 0.7 + streak, 0.0, 1.0);
	vec3 wood = mix(wood_dark.rgb, wood_light.rgb, smoothstep(0.25, 0.85, w));
	// Luz suave: arriba más claro, abajo más oscuro (volumen).
	wood *= mix(1.12, 0.80, clamp(fuv.y, 0.0, 1.0));
	// Resaltado: la madera se aclara (sube el brillo).
	wood *= 1.0 + 0.22 * active;

	// Borde dorado (más grueso y brillante al resaltar).
	float border_w = mix(3.0, 5.5, active);
	float edge = clamp(smoothstep(-border_w - 1.0, -border_w + 1.5, d), 0.0, 1.0);
	vec3 gcol = mix(gold_dim.rgb, gold.rgb, active);
	vec3 face = mix(wood, gcol, edge);

	// Filo de luz bajo el borde de arriba (bisel): la tabla tiene volumen.
	if (depth > 0.0) {
		float top = bp.y - off;
		float bevel = 1.0 - smoothstep(border_w, border_w + 6.0, top);
		face = mix(face, face * 1.25 + vec3(0.03), bevel * (1.0 - edge) * 0.6);
	}

	// Brillo interior dorado al resaltar.
	float glow = smoothstep(-18.0, 0.0, d);
	face = mix(face, gold.rgb, glow * 0.35 * active);

	// Destello que cruza la cara en diagonal (al pasar el mouse).
	if (shine >= 0.0) {
		float k = (bp.x + (bp.y - off) * 0.7) / (bsize.x + face_h * 0.7);
		float band = 1.0 - smoothstep(0.0, 0.07, abs(k - shine));
		face += vec3(1.0, 0.95, 0.8) * band * 0.3 * (1.0 - edge);
	}

	// Canto: la madera de la cara, más oscura, con el borde dorado apagado.
	float body_edge = clamp(smoothstep(-border_w - 1.0, -border_w + 1.5, d_body), 0.0, 1.0);
	vec3 lip = mix(wood_dark.rgb * 0.75, gcol * 0.6, body_edge);

	float a_face = 1.0 - smoothstep(-1.0, 0.5, d);
	float a_body = 1.0 - smoothstep(-1.0, 0.5, d_body);
	vec3 col = mix(lip, face, a_face);
	float alpha = max(a_body, a_face);

	// Afuera del botón (solo con pad): sombra difusa abajo + halo dorado al resaltar.
	if (pad > 0.0) {
		float drop = 3.0 + depth * (1.0 - press) * 0.5;
		float d_shadow = rounded_box(bp - vec2(bsize.x * 0.5, bsize.y * 0.5 + drop),
			bsize * 0.5 - vec2(2.0), corner);
		float sh = (1.0 - smoothstep(-4.0, pad * 0.9, d_shadow)) * mix(0.5, 0.3, press);
		float halo = (1.0 - smoothstep(0.0, pad, d_body)) * 0.55 * active;
		float under_a = clamp(sh + halo, 0.0, 1.0);
		vec3 under_col = gold.rgb * halo / max(sh + halo, 0.001);
		float ua = under_a * (1.0 - alpha);
		float oa = alpha + ua;
		col = oa > 0.0 ? (col * alpha + under_col * ua) / oa : vec3(0.0);
		alpha = oa;
	}

	COLOR = vec4(col, alpha);
}
