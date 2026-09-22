shader_type canvas_item;

uniform float scroll_offset = 0.0;

void fragment() {
	vec2 uv = UV;
	uv.x += scroll_offset;
	COLOR = texture(TEXTURE, uv);
}
