shader_type canvas_item;

uniform vec4 color1 : source_color;
uniform vec4 color2 : source_color;
uniform vec4 color3 : source_color;
uniform vec4 color4 : source_color;
uniform vec4 color5 : source_color;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float b = max(tex_color.r, max(tex_color.g, tex_color.b));
	vec4 res;

	if (b < 0.2) {
		res = color1;
	} else if (b < 0.4) {
		res = color2;
	} else if (b < 0.6) {
		res = color3;
	} else if (b < 0.8) {
		res = color4;
	} else {
		res = color5;
	}

	COLOR = vec4(res.rgb, tex_color.a);
}