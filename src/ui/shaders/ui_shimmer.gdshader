shader_type canvas_item;

uniform float intensity : hint_range(0.0, 2.0) = 0.55;
uniform float width : hint_range(0.01, 1.0) = 0.18;
uniform float speed : hint_range(0.0, 4.0) = 0.8;
uniform float angle : hint_range(-3.14159, 3.14159) = 0.65;

void fragment() {
	// Use a periodic sweep so the shimmer is always animated,
	// regardless of how long the game has been running.
	vec4 base = texture(TEXTURE, UV) * COLOR;
	vec2 p = UV - vec2(0.5);
	float s = sin(angle);
	float c = cos(angle);
	vec2 r = vec2(c * p.x - s * p.y, s * p.x + c * p.y);

	float sweep = fract(TIME * speed);
	float center = mix(-1.1 - width, 1.1 + width, sweep);
	float x = r.x - center;
	float band = smoothstep(-width, 0.0, x) - smoothstep(0.0, width, x);
	float glow = band * intensity;

	base.rgb = clamp(base.rgb + glow, 0.0, 2.0);
	COLOR = base;
}
