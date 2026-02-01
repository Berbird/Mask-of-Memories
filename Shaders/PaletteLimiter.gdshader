shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 color1 : source_color;
uniform vec4 color2 : source_color;
uniform vec4 color3 : source_color;
uniform vec4 color4 : source_color;
uniform vec4 color5 : source_color;

void fragment() {
	vec4 curr_color = texture(screen_texture, SCREEN_UV);
	float avg = (curr_color.r + curr_color.g + curr_color.b) / 3.0;
	
	if (avg < 0.125) {
		COLOR = color1;
	} else if (avg < 0.375) {
		COLOR = color2;
	} else if (avg < 0.625) {
		COLOR = color3;
	} else if (avg < 0.875) {
		COLOR = color4;
	} else {
		COLOR = color5;
	}
	
	COLOR.a = curr_color.a;
}