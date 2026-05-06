shader_type canvas_item;

uniform vec4 pulse_color : source_color = vec4(1.0, 0.86, 0.28, 1.0);
uniform float speed : hint_range(0.1, 8.0) = 3.0;
uniform float strength : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	float wave = 0.5 + 0.5 * sin(TIME * speed);
	float border = smoothstep(0.42, 0.50, abs(UV.x - 0.5)) + smoothstep(0.42, 0.50, abs(UV.y - 0.5));
	float glow = clamp(border, 0.0, 1.0) * wave * strength;
	COLOR = mix(base, pulse_color, glow);
	COLOR.a = max(base.a, glow * pulse_color.a);
}
