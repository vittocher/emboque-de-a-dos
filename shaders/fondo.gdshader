shader_type canvas_item;

// Fondo de los niveles con menos protagonismo, para que los personajes y objetos
// se lean primero: desenfoque suave (como profundidad de campo), menos contraste y
// saturación, un poco más oscuro y una viñeta en los bordes. Ver background.tscn.

// Desenfoque (en texels de la textura; 0 = nítido). Lee de un mipmap más chico
// y promedia 8 muestras alrededor.
uniform float blur : hint_range(0.0, 8.0) = 2.0;
// Contraste alrededor del color medio del fondo (1 = igual, menos = más plano).
uniform float contrast : hint_range(0.0, 2.0) = 0.7;
// Saturación (1 = igual).
uniform float saturation : hint_range(0.0, 2.0) = 0.8;
// Brillo (1 = igual).
uniform float brightness : hint_range(0.0, 2.0) = 0.85;
// Viñeta: cuánto oscurece las esquinas (0 = nada) y desde dónde empieza (0..1).
uniform float vignette : hint_range(0.0, 1.0) = 0.35;
uniform float vignette_start : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * blur;
	float lod = log2(max(blur, 1.0));
	vec3 c = textureLod(TEXTURE, UV, lod).rgb * 0.2;
	for (int i = 0; i < 8; i++) {
		float ang = float(i) * 0.785398;
		c += textureLod(TEXTURE, UV + vec2(cos(ang), sin(ang)) * px, lod).rgb * 0.1;
	}
	// Contraste respecto al tono medio de la imagen (el mipmap más chico).
	vec3 mean = textureLod(TEXTURE, vec2(0.5), 12.0).rgb;
	c = mean + (c - mean) * contrast;
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(luma), c, saturation) * brightness;
	// Viñeta elíptica (la imagen es 16:9).
	float d = length((UV - 0.5) * vec2(1.0, 0.75)) * 2.0;
	c *= 1.0 - vignette * smoothstep(vignette_start, 1.2, d);
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0) * vec4(1.0, 1.0, 1.0, texture(TEXTURE, UV).a);
}
