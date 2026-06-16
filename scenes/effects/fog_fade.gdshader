shader_type canvas_item;

void fragment() {
	float fade = smoothstep(0.0, 0.25, UV.y);
	COLOR.a *= fade;
}
