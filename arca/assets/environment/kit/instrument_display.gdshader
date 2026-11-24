shader_type spatial;
render_mode unshaded;

uniform vec4 phosphor : source_color = vec4(0.28, 0.76, 0.74, 1.0);
uniform float channel = 0.0;

void fragment() {
	vec2 uv = UV;
	float grid_x = step(0.96, fract(uv.x * 10.0));
	float grid_y = step(0.95, fract(uv.y * 5.0));
	float grid = max(grid_x, grid_y) * 0.15;
	float sample_x = floor(uv.x * 90.0) * 0.07;
	float wave = 0.55 + 0.12 * sin(sample_x * 3.0 + channel);
	wave += 0.09 * sin(sample_x * 11.0) * sin(sample_x * 2.0 + channel);
	float trace = 1.0 - smoothstep(0.005, 0.025, abs(wave - uv.y));
	float sweep = fract(TIME * 0.32 + channel);
	float persistence = 0.38 + 0.62 * exp(-5.0 * fract(sweep - uv.x));
	float scanline = mix(0.83, 1.0, step(0.30, fract(uv.y * 128.0)));
	float margin = step(0.035, uv.x) * step(uv.x, 0.965);
	ALBEDO = vec3(0.025, 0.052, 0.054) + phosphor.rgb * scanline * margin *
		(grid + trace * persistence * 0.74);
}
