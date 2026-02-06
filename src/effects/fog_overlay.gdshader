shader_type canvas_item;
render_mode unshaded;

uniform vec4 fog_color : source_color = vec4(0.01, 0.01, 0.03, 1.0);
uniform float darkness_alpha = 0.85;

uniform float radius_px = 420.0;
uniform float softness_px = 240.0;

uniform vec2 player_screen_px = vec2(960.0, 540.0);
uniform vec2 viewport_size_px = vec2(1920.0, 1080.0);

uniform float noise_strength = 0.06;
uniform float noise_scale = 0.02;


float _hash(vec2 p) {
	// Cheap stable hash in [0, 1].
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}


void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = uv * viewport_size_px;

	float d = distance(px, player_screen_px);
	float soft = max(1.0, softness_px);
	float edge = smoothstep(radius_px, radius_px + soft, d);

	float n = _hash(px * noise_scale + vec2(TIME * 0.35, -TIME * 0.27));
	n = (n - 0.5) * 2.0;
	edge = clamp(edge + n * noise_strength, 0.0, 1.0);

	float alpha = darkness_alpha * edge;
	COLOR = vec4(fog_color.rgb, alpha);
}
