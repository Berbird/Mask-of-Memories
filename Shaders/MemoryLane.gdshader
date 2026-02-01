shader_type canvas_item;

uniform float taper_amount : hint_range(0.0, 0.9) = 0.7;
uniform float base_width : hint_range(0.1, 1.0) = 0.5;

void fragment() {
	vec2 uv = UV;
	
	float current_width = base_width * (1.0 - taper_amount * (1.0 - uv.y));
	current_width = max(current_width, 0.01); 

	float x = (uv.x - 0.5) / current_width + 0.5;
	
	if (x < 0.0 || x > 1.0) {
		discard;
	}
	
	COLOR = texture(TEXTURE, vec2(x, uv.y));
}