shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 color_a : source_color = vec4(0.86, 0.70, 0.98, 1.0);
uniform vec4 color_b : source_color = vec4(0.72, 0.42, 0.94, 1.0);
uniform vec4 color_c : source_color = vec4(0.45, 0.20, 0.72, 1.0);
uniform vec2 bar_size = vec2(200.0, 76.0);

float sd_rounded_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r, r);
	return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void fragment() {
	vec2 px = UV * bar_size;
	float r = min(bar_size.x, bar_size.y) * 0.5;
	float d = sd_rounded_box(px - bar_size * 0.5, bar_size * 0.5, r);
	if (d > 0.5) {
		discard;
	}
	float t = clamp(UV.x, 0.0, 1.0);
	vec3 col = mix(color_a.rgb, color_b.rgb, smoothstep(0.0, 0.52, t));
	col = mix(col, color_c.rgb, smoothstep(0.42, 1.0, t));
	float shine = mix(1.10, 0.86, UV.y);
	float edge = 1.0 - smoothstep(0.0, 1.2, d);
	COLOR = vec4(col * shine, edge);
}
