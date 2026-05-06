class_name BattleAtmosphereLayer
extends Control

const BattleLayoutScript := preload("res://scripts/core/BattleLayout.gd")

var state: BattleState
var assets: BattleAssets
var layout = BattleLayoutScript.new()
var anim_time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func sync() -> void:
	visible = state != null and assets != null and state.chapter_phase == "battle"
	queue_redraw()


func _draw() -> void:
	if state == null or assets == null or layout == null or state.chapter_phase != "battle":
		return
	var view_size := get_viewport_rect().size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		return
	if _uses_corridor_set():
		_draw_corridor_set(view_size)
	else:
		_draw_courtyard_set(view_size)


func _uses_corridor_set() -> bool:
	return state.current_battlefield_background_path().contains("west-corridor")


func _draw_courtyard_set(view_size: Vector2) -> void:
	_draw_asset("sacred_crest", Rect2(Vector2(view_size.x * 0.055, view_size.y * 0.12), _scaled_size(116.0)), 0.13, 0.0)
	_draw_asset("lantern_glow", Rect2(Vector2(view_size.x * 0.055, view_size.y * 0.72), _scaled_size(104.0)), 0.18, 0.0)
	_draw_asset("rune_fire", Rect2(Vector2(view_size.x * 0.62, view_size.y * 0.13), _scaled_size(94.0)), 0.10, -0.18)
	_draw_asset("torn_banner", Rect2(Vector2(view_size.x * 0.82, view_size.y * 0.17), _scaled_size(126.0)), 0.10, 0.10)
	_draw_soft_edge_wash(view_size, Color("#f6c76a", 0.035), Color("#6aa7ff", 0.030))


func _draw_corridor_set(view_size: Vector2) -> void:
	_draw_asset("torn_banner", Rect2(Vector2(view_size.x * 0.045, view_size.y * 0.10), _scaled_size(150.0)), 0.16, -0.10)
	_draw_asset("rune_fire", Rect2(Vector2(view_size.x * 0.68, view_size.y * 0.71), _scaled_size(112.0)), 0.16, 0.16)
	_draw_asset("lantern_glow", Rect2(Vector2(view_size.x * 0.82, view_size.y * 0.27), _scaled_size(106.0)), 0.18, 0.0)
	_draw_asset("sacred_crest", Rect2(Vector2(view_size.x * 0.18, view_size.y * 0.70), _scaled_size(96.0)), 0.09, 0.08)
	_draw_soft_edge_wash(view_size, Color("#f08a43", 0.045), Color("#6da9ff", 0.038))


func _scaled_size(base: float) -> Vector2:
	var scale := clampf(get_viewport_rect().size.y / 720.0, 0.72, 1.22)
	return Vector2(base, base) * scale


func _draw_asset(key: String, rect: Rect2, alpha: float, pulse_phase: float) -> void:
	var texture := assets.atmosphere_texture(key)
	if texture == null:
		return
	if _too_close_to_board(rect):
		return
	var pulse := 0.5 + 0.5 * sin(anim_time * 1.7 + pulse_phase * TAU)
	var modulate := Color(1, 1, 1, alpha * (0.86 + pulse * 0.14))
	draw_texture_rect(texture, rect, false, modulate)


func _too_close_to_board(rect: Rect2) -> bool:
	var board_rect: Rect2 = layout.board_rect
	if board_rect.size == Vector2.ZERO:
		return false
	return board_rect.grow(18.0).intersects(rect)


func _draw_soft_edge_wash(view_size: Vector2, warm: Color, cool: Color) -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(view_size.x, view_size.y * 0.15)), cool)
	draw_rect(Rect2(Vector2(0.0, view_size.y * 0.76), Vector2(view_size.x, view_size.y * 0.24)), warm)
	draw_rect(Rect2(Vector2.ZERO, Vector2(view_size.x * 0.18, view_size.y)), Color("#050812", 0.045))
	draw_rect(Rect2(Vector2(view_size.x * 0.84, 0.0), Vector2(view_size.x * 0.16, view_size.y)), Color("#050812", 0.045))
