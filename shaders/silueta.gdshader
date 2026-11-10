shader_type canvas_item;
render_mode blend_premul_alpha;

// Sombra o brillo con la FORMA (silueta) de la textura de un sprite: difumina su
// canal alfa y lo pinta de un color. Lo usan DropShadow (sombras de jugadores,
// emboques, cajas…) y HazardArt (halo del fuego / la caca, sombra de las púas).
// Agranda el cuadro del sprite para que el difuminado quepa fuera del dibujo.
// Supone un sprite centrado (Sprite2D / AnimatedSprite2D con centered = true).

// Color; el alfa es la opacidad máxima.
uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.0, 0.45);
// Radio del difuminado, en px del mundo (no depende de la escala del sprite).
uniform float blur_px = 6.0;
// 0 = sombra (tapa lo de atrás), 1 = luz (se suma a lo de atrás).
uniform float additive = 0.0;
// Multiplica la opacidad / la luz.
uniform float intensity = 1.0;
// Engorda la silueta (0..1): el borde difuminado se vuelve más denso.
uniform float grow = 0.0;
// Parpadeo (0 = nada, 0.3 = la luz baja hasta un 30 %) y su rapidez.
uniform float flicker = 0.0;
uniform float flicker_speed = 1.0;

// UV agrandado sin recortar: Godot recorta (clamp) el UV de los sprites a 0..1
// antes del fragment, y fuera del dibujo repetiría el borde (rayas).
varying vec2 v_uv;
// Modulate del nodo. En el fragment, COLOR ya viene multiplicado por la textura en
// el UV recortado: no sirve como modulate (oscurecía / recortaba el dibujo).
varying vec4 v_modulate;
varying vec2 v_radius_uv;
varying float v_edge;
varying float v_lod;
varying float v_seed;

// Cobertura (alfa) de la textura en uv, 0 fuera de ella (con un borde de un texel).
// Es una macro y no una función: pasarle TEXTURE a una función propia no compila
// bien en el renderer de canvas.
#define COVER(uv) (textureLod(TEXTURE, clamp((uv), vec2(0.0), vec2(1.0)), v_lod).a 		* clamp(1.0 - max(max(-(uv).x, (uv).x - 1.0), max(-(uv).y, (uv).y - 1.0)) / v_edge, 0.0, 1.0))

void vertex() {
	v_modulate = COLOR;
	vec2 s = max(vec2(length(MODEL_MATRIX[0].xy), length(MODEL_MATRIX[1].xy)), vec2(0.0001));
	// Margen (px locales) para que quepa el difuminado; cada esquina se aleja del
	// centro (sign) y su UV se sale de 0..1 en la misma proporción (vale con flip).
	vec2 margin = vec2(blur_px * 1.6 + 2.0) / s;
	VERTEX += sign(VERTEX) * margin;
	UV += sign(UV - 0.5) * margin * TEXTURE_PIXEL_SIZE;
	v_uv = UV;
	v_radius_uv = blur_px / s * TEXTURE_PIXEL_SIZE;
	// Leer de un mipmap más chico ya difumina; las muestras completan el resto.
	float texels = blur_px / min(s.x, s.y);
	v_lod = max(log2(texels * 0.4), 0.0);
	// Fuera del dibujo la cobertura es 0 (borde de un texel). Con muchas muestras el
	// difuminado queda suave aunque el dibujo toque el borde del PNG.
	v_edge = max(TEXTURE_PIXEL_SIZE.x, TEXTURE_PIXEL_SIZE.y);
	v_seed = MODEL_MATRIX[3].x * 0.013 + MODEL_MATRIX[3].y * 0.007;
}

void fragment() {
	// Espiral de 20 muestras (ángulo dorado) dentro del radio, más el centro.
	float a = COVER(v_uv) * 0.5;
	float wsum = 0.5;
	for (int i = 0; i < 20; i++) {
		float fi = float(i) + 0.5;
		float r = sqrt(fi / 20.0);
		float ang = fi * 2.39996;
		float w = 1.0 - r * 0.6;
		a += COVER(v_uv + vec2(cos(ang), sin(ang)) * r * v_radius_uv) * w;
		wsum += w;
	}
	a /= wsum;
	if (grow > 0.0) {
		a = 1.0 - pow(1.0 - clamp(a, 0.0, 1.0), 1.0 + grow * 4.0);
	}
	float f = 1.0;
	if (flicker > 0.0) {
		float t = TIME * flicker_speed;
		float n = 0.5 + 0.5 * sin(t * 7.3 + v_seed * 13.0) * sin(t * 3.1 + v_seed * 5.0);
		f = 1.0 - flicker * n;
	}
	float k = a * tint.a * intensity * f * v_modulate.a;
	// Premultiplicado: rgb se suma siempre; alfa tapa lo de atrás solo en modo sombra.
	COLOR = vec4(tint.rgb * k, k * (1.0 - additive));
}
