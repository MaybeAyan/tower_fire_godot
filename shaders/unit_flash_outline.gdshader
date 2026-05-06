shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0, 0.96, 0.72, 1.0);
uniform vec4 outline_color : source_color = vec4(1.0, 0.88, 0.35, 1.0);
uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;
uniform float outline_strength : hint_range(0.0, 1.0) = 0.0;
uniform float outline_px : hint_range(0.0, 6.0) = 2.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	vec2 texel = TEXTURE_PIXEL_SIZE * outline_px;
	float outline_alpha = 0.0;
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(texel.x, 0.0)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV - vec2(texel.x, 0.0)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(0.0, texel.y)).a);
	outline_alpha = max(outline_alpha, texture(TEXTURE, UV - vec2(0.0, texel.y)).a);
	float edge = max(outline_alpha - base.a, 0.0) * outline_strength;
	vec4 outlined = mix(base, outline_color, edge);
	outlined.a = max(base.a, edge * outline_color.a);
	COLOR = mix(outlined, vec4(flash_color.rgb, outlined.a), flash_strength * base.a);
}
