shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform float span_px = 400.0;
uniform vec3 gold_hi : source_color = vec3(1.00, 0.95, 0.68);
uniform vec3 gold_mid : source_color = vec3(0.96, 0.78, 0.28);
uniform vec3 gold_lo : source_color = vec3(0.76, 0.46, 0.12);

varying float v_x;

void vertex() {
	v_x = VERTEX.x;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = dot(COLOR.rgb, vec3(0.33, 0.5, 0.17));
	float t = clamp(v_x / max(span_px, 1.0), 0.0, 1.0);
	vec3 fill = mix(gold_hi, gold_mid, smoothstep(0.0, 0.48, t));
	fill = mix(fill, gold_lo, smoothstep(0.48, 1.0, t));
	float keep_outline = step(lum, 0.42);
	vec3 out_col = mix(fill, COLOR.rgb, keep_outline);
	COLOR = vec4(out_col, tex.a * COLOR.a);
}
