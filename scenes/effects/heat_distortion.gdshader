shader_type canvas_item;

uniform float intensity : hint_range(0.0, 0.05) = 0.015;
uniform float speed : hint_range(0.0, 5.0) = 2.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float wave = sin(uv.y * 40.0 + TIME * speed) * intensity;
	uv.x += wave;
	COLOR = texture(SCREEN_TEXTURE, uv);
}
