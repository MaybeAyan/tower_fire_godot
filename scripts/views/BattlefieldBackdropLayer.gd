class_name BattlefieldBackdropLayer
extends TextureRect

const BattleLayoutScript := preload("res://scripts/core/BattleLayout.gd")

const BACKDROP_SHADER := """
shader_type canvas_item;

uniform float blur_amount = 2.8;
uniform float focus_radius = 0.26;
uniform vec2 focus_center = vec2(0.5, 0.52);
uniform float vignette_strength = 0.38;
uniform float grain_strength = 0.025;
uniform vec4 wash_tint : source_color = vec4(0.98, 0.93, 0.82, 1.0);

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV;
	float focus_distance = distance(uv, focus_center);
	float depth = smoothstep(focus_radius, focus_radius + 0.46, focus_distance);
	vec2 px = TEXTURE_PIXEL_SIZE * blur_amount * (0.35 + depth * 1.15);
	vec4 color = texture(TEXTURE, uv) * 0.24;
	color += texture(TEXTURE, uv + vec2(px.x, 0.0)) * 0.11;
	color += texture(TEXTURE, uv - vec2(px.x, 0.0)) * 0.11;
	color += texture(TEXTURE, uv + vec2(0.0, px.y)) * 0.11;
	color += texture(TEXTURE, uv - vec2(0.0, px.y)) * 0.11;
	color += texture(TEXTURE, uv + vec2(px.x, px.y)) * 0.08;
	color += texture(TEXTURE, uv + vec2(-px.x, px.y)) * 0.08;
	color += texture(TEXTURE, uv + vec2(px.x, -px.y)) * 0.08;
	color += texture(TEXTURE, uv + vec2(-px.x, -px.y)) * 0.08;

	float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	color.rgb = mix(color.rgb, vec3(luma), 0.08);
	color.rgb = mix(color.rgb, color.rgb * wash_tint.rgb, 0.42);
	color.rgb *= vec3(0.84, 0.82, 0.78);

	float vignette = smoothstep(0.98, 0.24, distance(uv, vec2(0.5, 0.52)));
	color.rgb *= mix(1.0 - vignette_strength, 1.0, vignette);
	color.rgb += (hash21(uv * 2048.0) - 0.5) * grain_strength;
	COLOR = vec4(color.rgb, 1.0);
}
"""

var state: BattleState
var assets: BattleAssets
var layout = BattleLayoutScript.new()
var backdrop_material: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var shader := Shader.new()
	shader.code = BACKDROP_SHADER
	backdrop_material = ShaderMaterial.new()
	backdrop_material.shader = shader
	material = backdrop_material
	visible = false


func sync() -> void:
	if state == null or assets == null or layout == null or assets.battlefield_texture == null:
		visible = false
		texture = null
		return
	visible = state.chapter_phase == "battle"
	var backdrop_texture: Texture2D = assets.battlefield_texture_for(state.current_battlefield_background_path())
	texture = backdrop_texture if visible else null
	if not visible:
		return
	var board_center: Vector2 = layout.board_rect.get_center()
	var view_size: Vector2 = get_viewport_rect().size
	if view_size.x > 0.0 and view_size.y > 0.0:
		backdrop_material.set_shader_parameter("focus_center", board_center / view_size)
	var scale_ratio := clampf(layout.board_rect.size.y / 560.0, 0.56, 1.0)
	backdrop_material.set_shader_parameter("blur_amount", lerpf(6.8, 3.8, scale_ratio))
	backdrop_material.set_shader_parameter("focus_radius", lerpf(0.14, 0.24, scale_ratio))
