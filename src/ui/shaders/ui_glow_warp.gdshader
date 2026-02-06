shader_type canvas_item;

uniform float warp_strength : hint_range(0.0, 0.05) = 0.008;
uniform float warp_scale : hint_range(1.0, 40.0) = 10.0;
uniform float speed : hint_range(0.0, 3.0) = 0.35;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.22;

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	vec2 w = vec2(
		sin((uv.y + t) * warp_scale * 1.3),
		cos((uv.x + t) * warp_scale * 1.6)
	);
	uv += w * warp_strength;

	vec4 col = texture(TEXTURE, uv);
	float pulse = 1.0 - pulse_amount + (pulse_amount * (0.5 + 0.5 * sin(TIME * 1.2)));
	col.a *= pulse;
	COLOR = col;
}
