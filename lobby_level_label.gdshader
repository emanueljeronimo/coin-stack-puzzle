shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform float span_px = 400.0;
uniform vec3 gold : source_color = vec3(0.96, 0.82, 0.42);
uniform vec3 rose : source_color = vec3(0.94, 0.62, 0.78);
uniform vec3 sky : source_color = vec3(0.55, 0.86, 0.88);

varying float v_x;

void vertex() {
	v_x = VERTEX.x;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = dot(COLOR.rgb, vec3(0.33, 0.5, 0.17));
	float t = clamp(v_x / max(span_px, 1.0), 0.0, 1.0);
	vec3 fill = mix(sky, gold, smoothstep(0.0, 0.48, t));
	fill = mix(fill, rose, smoothstep(0.48, 1.0, t));
	float keep_outline = step(lum, 0.42);
	vec3 out_col = mix(fill, COLOR.rgb, keep_outline);
	COLOR = vec4(out_col, tex.a * COLOR.a);
}
