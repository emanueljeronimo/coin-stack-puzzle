shader_type canvas_item;

// Aclara el pozo central (gris de la textura) al nivel pastel del juego
// y deja un poco de relieve solo en las luces del borde.
uniform float volume_amount : hint_range(0.0, 1.0) = 0.28;
uniform float face_lift : hint_range(0.5, 1.0) = 0.90;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 face_tex = texture(TEXTURE, vec2(0.5, 0.5));
	float lum = max(dot(tex.rgb, vec3(0.299, 0.587, 0.114)), 0.001);
	float face = max(dot(face_tex.rgb, vec3(0.299, 0.587, 0.114)), 0.001);

	// Sube las zonas oscuras hacia un gris claro; el centro queda clarito.
	float lifted = mix(face_lift, lum, 0.28);
	float hi = max(lum - face, 0.0);
	float lit = clamp(lifted + hi * volume_amount, 0.0, 1.05);
	float scale = lit / lum;

	COLOR.rgb = COLOR.rgb * tex.rgb * scale;
	COLOR.a *= tex.a;
}
