shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec3 sweep_col : source_color = vec3(1.0, 1.0, 0.97);
uniform float sweep_duration : hint_range(0.4, 1.5) = 0.8;
uniform float sweep_period : hint_range(1.5, 8.0) = 3.6;
uniform float sweep_width : hint_range(0.04, 0.4) = 0.15;
uniform float sweep_strength : hint_range(0.05, 0.8) = 0.28;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = max(tex.r, max(tex.g, tex.b));
	float mask = tex.a * smoothstep(0.03, 0.11, lum);
	vec3 out_col = tex.rgb;

	float phase = mod(TIME, sweep_period);
	float u = phase / max(sweep_duration, 0.05);
	float alive = smoothstep(0.0, 0.08, u) * (1.0 - smoothstep(0.92, 1.0, u));
	float center = mix(-0.28, 1.28, clamp(u, 0.0, 1.0));
	float diag = (UV.x + UV.y) * 0.5;
	float dist = abs(diag - center);
	float halo = 1.0 - smoothstep(sweep_width * 0.35, sweep_width, dist);
	float core = 1.0 - smoothstep(0.0, sweep_width * 0.28, dist);
	float stripe = (halo * 0.55 + core * 0.45) * alive;
	out_col += sweep_col * stripe * sweep_strength * mix(0.75, 1.15, lum);

	COLOR = vec4(out_col, mask * COLOR.a);
}
