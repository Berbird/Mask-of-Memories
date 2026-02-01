shader_type canvas_item;

// taper_amount: Üst kısmın ne kadar daralacağı (0.0 = daralma yok, 1.0 = nokta)
uniform float taper_amount : hint_range(0.0, 0.9) = 0.7;
// base_width: Yolun en alt kısmının genişlik oranı (0.5 = yarı yarıya daralmış)
uniform float base_width : hint_range(0.1, 1.0) = 0.5;

void fragment() {
	vec2 uv = UV;
	
	// Yolun altı 'base_width' kadar, üstü ise 'base_width * (1.0 - taper_amount)' kadar geniş olacak.
	float current_width = base_width * (1.0 - taper_amount * (1.0 - uv.y));
	current_width = max(current_width, 0.01); // Güvenlik önlemi

	float x = (uv.x - 0.5) / current_width + 0.5;
	
	if (x < 0.0 || x > 1.0) {
		discard;
	}
	
	COLOR = texture(TEXTURE, vec2(x, uv.y));
}