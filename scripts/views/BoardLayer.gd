class_name BoardLayer
extends Control

const BattleProjectionScript := preload("res://scripts/core/BattleProjection.gd")
const BattleLayoutScript := preload("res://scripts/core/BattleLayout.gd")

var state: BattleState
var assets: BattleAssets
var layout = BattleLayoutScript.new()
var anim_time := 0.0
var board_rect: Rect2 = Rect2()

@export var draw_battlefield_background := true
@export var draw_board_frame := true
@export var draw_terrain_tiles := true
@export_range(0.52, 0.88, 0.01) var tile_visual_height_ratio := 0.70
@export_range(-0.3, 0.36, 0.01) var unit_base_y_ratio := 0.10
@export_range(0.2, 0.55, 0.01) var unit_base_radius_ratio := 0.26
@export_range(0.55, 0.9, 0.01) var unit_sprite_y_ratio := 0.76


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if state == null or assets == null:
		return
	var viewport_size := get_viewport_rect().size
	board_rect = layout.board_rect if layout != null else Rect2(Vector2(52, 86), Vector2(630, 450))
	if draw_battlefield_background:
		_draw_background(viewport_size)
	_draw_board()
	_draw_hover_preview()
	_draw_action_hints()
	_draw_hovered_unit_tiles()
	_draw_skill_release_events()
	_draw_units()
	_draw_enemy_intents()


func _draw_background(viewport_size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#102036"))
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#fff1b2", 0.025))
	draw_rect(Rect2(Vector2.ZERO, Vector2(viewport_size.x, 32)), Color("#030814", 0.42))
	draw_rect(Rect2(Vector2(0, viewport_size.y - 150), Vector2(viewport_size.x, 150)), Color("#030814", 0.34))
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#030814", 0.08), false, 18.0)


func _draw_panel(rect: Rect2, fill: Color = Color("#111a33", 0.86), border: Color = Color("#9fd7ff", 0.25)) -> void:
	draw_rect(rect, Color("#030814", 0.35))
	draw_rect(rect.grow(-2), fill)
	draw_rect(rect.grow(-2), border, false, 2.0)


func _terrain_fill(kind: String, x: int, y: int) -> Color:
	match kind:
		"wall":
			return Color("#182235", 0.54)
		"pillar":
			return Color("#2d3549", 0.62)
		"high":
			return Color("#d9c884", 0.18)
		"holy":
			return Color("#74f6c5", 0.18)
		"fire":
			return Color("#ff6b5e", 0.18)
		"gate":
			return Color("#f6d26b", 0.16)
		"marker":
			return Color("#6ad7ff", 0.14)
	return Color("#e8f7ff", 0.13) if (x + y) % 2 == 0 else Color("#5fc7ff", 0.08)


func _draw_terrain_mark(rect: Rect2, kind: String) -> void:
	if assets != null and assets.terrain_tileset_texture != null:
		_draw_terrain_runtime_glow(rect, kind)
		return
	match kind:
		"wall", "pillar":
			draw_rect(rect.grow(-8), Color("#030814", 0.28))
			draw_rect(rect.grow(-12), Color("#dce6ff", 0.16), false, 1.0)
		"high":
			draw_line(rect.position + Vector2(12, rect.size.y - 14), rect.end - Vector2(12, 14), Color("#f6d26b", 0.3), 2.0)
		"holy":
			draw_circle(rect.get_center(), rect.size.x * 0.18, Color("#8fffd8", 0.2))
			draw_arc(rect.get_center(), rect.size.x * 0.24, 0.0, TAU, 32, Color("#8fffd8", 0.36), 1.4)
		"fire":
			draw_arc(rect.get_center(), rect.size.x * 0.22, -PI * 0.2, PI * 1.1, 24, Color("#ff6685", 0.44), 2.0)
		"gate":
			draw_rect(rect.grow(-10), Color("#f6d26b", 0.18), false, 2.0)
		"marker":
			draw_circle(rect.get_center(), rect.size.x * 0.2, Color("#6ad7ff", 0.15))
			draw_arc(rect.get_center(), rect.size.x * 0.28, 0.0, TAU, 32, Color("#6ad7ff", 0.34), 1.6)


func _draw_terrain_runtime_glow(rect: Rect2, kind: String) -> void:
	var pulse := 0.5 + 0.5 * sin(anim_time * 3.2)
	match kind:
		"holy":
			draw_circle(rect.get_center(), rect.size.x * (0.31 + pulse * 0.035), Color("#8fffd8", 0.10 + pulse * 0.08))
			draw_arc(rect.get_center(), rect.size.x * 0.33, 0.0, TAU, 36, Color("#dffdf2", 0.18 + pulse * 0.12), 1.6)
		"fire":
			draw_circle(rect.get_center(), rect.size.x * (0.30 + pulse * 0.04), Color("#ff6685", 0.10 + pulse * 0.07))
			draw_arc(rect.get_center(), rect.size.x * 0.34, -PI * 0.22, PI * 1.1, 28, Color("#ffd66e", 0.18 + pulse * 0.14), 1.8)
		"marker":
			draw_arc(rect.get_center(), rect.size.x * (0.31 + pulse * 0.04), 0.0, TAU, 36, Color("#79d8ff", 0.22 + pulse * 0.12), 1.8)
		"gate":
			draw_rect(rect.grow(-8), Color("#f6d26b", 0.10 + pulse * 0.035), false, 2.0)
		"high":
			draw_line(rect.position + Vector2(10, rect.size.y - 11), rect.end - Vector2(10, 11), Color("#fff4ba", 0.18), 2.0)


func _draw_bar(rect: Rect2, ratio: float, fill: Color, label: String) -> void:
	var clamped_ratio: float = clampf(ratio, 0.0, 1.0)
	draw_rect(Rect2(rect.position + Vector2(0, 2), rect.size), Color("#030814", 0.36))
	draw_rect(rect, Color("#101008", 0.96))
	draw_rect(rect.grow(-1), Color("#24231d", 0.82))
	draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2((rect.size.x - 4) * clamped_ratio, rect.size.y - 4)), fill)
	draw_rect(rect, Color("#c19a4a", 0.62), false, 1.2)
	var label_rect := Rect2(rect.position + Vector2(-10, -14), Vector2(rect.size.x + 20, 16))
	draw_rect(label_rect, Color("#030814", 0.58))
	draw_rect(label_rect, Color("#fff4ba", 0.20), false, 1.0)
	draw_string(get_theme_default_font(), label_rect.position + Vector2(0, 12), label, HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x, 13, Color("#ffffff"))


func _draw_board() -> void:
	var valid_tiles: Array = state.get_valid_tiles()
	var focused_enemy_tiles: Array = state.focused_enemy_tiles()
	var tutorial_tiles: Array = state.tutorial_focus_tiles()
	var recommended_tiles: Array = state.tutorial_recommended_tiles()
	var show_valid_tiles := _selected_skill_uses_board_targets()
	if draw_board_frame:
		_draw_board_frame()
	for tile in _tile_draw_order():
		var cell_rect := state.tile_rect(tile, board_rect)
		var kind := state.terrain_kind(tile)
		if draw_terrain_tiles and not _using_scene_tilemap():
			var base := _terrain_fill(kind, tile.x, tile.y)
			if assets.terrain_tileset_texture != null:
				var region: Rect2 = assets.terrain_tile_regions.get(kind, assets.terrain_tile_regions.get("floor", Rect2()))
				var visual_rect := BattleProjectionScript.tile_visual_rect(tile, board_rect, BattleState.GRID_W, BattleState.GRID_H, tile_visual_height_ratio)
				draw_texture_rect_region(assets.terrain_tileset_texture, visual_rect, region)
			else:
				_draw_diamond(cell_rect, base, _terrain_tint(kind), 1.0)
		_draw_cell_grid(cell_rect, tile)
		_draw_terrain_mark(cell_rect, kind)
		if tile in focused_enemy_tiles:
			_draw_threat_tile(cell_rect, false)
		if tile in tutorial_tiles:
			_draw_tutorial_focus_tile(cell_rect)
		if tile in recommended_tiles:
			_draw_tutorial_recommended_tile(cell_rect)
		if show_valid_tiles and tile in valid_tiles:
			var pulse: float = 0.55 + 0.35 * sin(anim_time * 5.0)
			var color := _valid_tile_color()
			_draw_valid_tile(cell_rect, tile, color, pulse)


func _using_scene_tilemap() -> bool:
	return state != null and state.current_tilemap_scene_path() != ""


func _selected_skill_uses_board_targets() -> bool:
	if state.selected_card < 0 or state.selected_card >= state.hand.size():
		return true
	var card: Dictionary = state.hand[state.selected_card]
	match String(card.get("target_mode", "")):
		"unit_self":
			return false
	return String(card.get("kind", "")) not in [BattleAssets.CARD_GUARD, BattleAssets.CARD_ENGAGE]


func _draw_board_frame() -> void:
	var points := BattleProjectionScript.board_diamond_points(board_rect, BattleState.GRID_W, BattleState.GRID_H)
	var shadow := PackedVector2Array()
	for point in points:
		shadow.append(point + Vector2(0, 11))
	draw_polygon(shadow, [Color("#030814", 0.34)])
	draw_polygon(points, [Color("#051026", 0.28)])
	_draw_polyline(points, Color("#0c1322", 0.72), 8.0, true)
	_draw_polyline(points, Color("#c19a4a", 0.42), 4.0, true)
	_draw_polyline(points, Color("#f0c66e", 0.30), 1.8, true)


func _tile_draw_order() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for y in range(BattleState.GRID_H):
		for x in range(BattleState.GRID_W):
			tiles.append(Vector2i(x, y))
	return tiles


func _diamond_points(rect: Rect2) -> PackedVector2Array:
	return BattleProjectionScript.diamond_points(rect)


func _draw_diamond(rect: Rect2, fill: Color, border: Color, width: float = 1.0) -> void:
	var points := _diamond_points(rect)
	if fill.a > 0.0:
		draw_polygon(points, [fill])
	if border.a > 0.0:
		_draw_polyline(points, border, width, true)


func _draw_polyline(points: PackedVector2Array, color: Color, width: float, closed: bool = false) -> void:
	var count := points.size()
	if count < 2:
		return
	for i in range(count - 1):
		draw_line(points[i], points[i + 1], color, width)
	if closed:
		draw_line(points[count - 1], points[0], color, width)


func _terrain_tint(kind: String) -> Color:
	match kind:
		"wall", "pillar":
			return Color("#071126", 0.08)
		"high":
			return Color("#fff4ba", 0.08)
		"holy":
			return Color("#8fffd8", 0.06)
		"fire":
			return Color("#ff6685", 0.08)
		"gate":
			return Color("#f6d26b", 0.08)
		"marker":
			return Color("#6ad7ff", 0.06)
	return Color("#ffffff", 0.02)


func _draw_cell_grid(rect: Rect2, tile: Vector2i) -> void:
	var alpha := 0.24 if (tile.x + tile.y) % 2 == 0 else 0.18
	_draw_diamond(rect, Color("#10131b", 0.02), Color("#f6d26b", alpha), 1.1)
	draw_line(rect.position + Vector2(4, 4), Vector2(rect.end.x - 4, rect.position.y + 4), Color("#fff1b2", 0.07), 1.0)
	draw_line(rect.position + Vector2(4, 4), Vector2(rect.position.x + 4, rect.end.y - 4), Color("#fff1b2", 0.05), 1.0)


func _draw_threat_tile(rect: Rect2, overlaps_player: bool = false) -> void:
	var inner := rect.grow(-3)
	var pulse := 0.5 + 0.35 * sin(anim_time * 5.8)
	var texture_key := "range_danger" if overlaps_player else "range_attack"
	_draw_range_texture(inner, texture_key, 0.42 + pulse * 0.10)
	var line_color := Color("#ff4f5e", 0.64 + pulse * 0.14)
	_draw_diamond(inner, Color("#ff2638", 0.10 + pulse * 0.05), line_color, 2.2)
	for i in range(-2, 5):
		var x0 := inner.position.x + float(i) * inner.size.x * 0.26
		draw_line(Vector2(x0, inner.end.y), Vector2(x0 + inner.size.x * 0.42, inner.position.y), Color("#ffb3a4", 0.30 + pulse * 0.10), 1.6)
	_draw_corner_brackets(inner, Color("#ffd6a4", 0.74 + pulse * 0.12), 0.31, 3.0)
	_draw_attack_glyph(inner, line_color)


func _draw_player_threat_tile(rect: Rect2, overlaps_enemy: bool = false) -> void:
	var inner := rect.grow(-7)
	var pulse := 0.5 + 0.25 * sin(anim_time * 4.6)
	var texture_key := "range_danger" if overlaps_enemy else "range_selected"
	_draw_range_texture(inner, texture_key, 0.26 + pulse * 0.06)
	var line_color := Color("#d7b56b", 0.46 + pulse * 0.12) if not overlaps_enemy else Color("#c6a0ff", 0.50 + pulse * 0.12)
	_draw_diamond(inner, Color(line_color, 0.07), line_color, 1.6)
	_draw_corner_brackets(inner, line_color, 0.24, 2.0)


func _draw_valid_tile(rect: Rect2, tile: Vector2i, color: Color, pulse: float) -> void:
	var inner := rect.grow(-4)
	var texture_key := _valid_tile_texture_key()
	_draw_range_texture(inner, texture_key, 0.68 + pulse * 0.10)
	var fill := Color(color, 0.12 + pulse * 0.08)
	var line := Color("#fff4ba", 0.55 + pulse * 0.25)
	_draw_diamond(inner, fill, Color(color, 0.48 + pulse * 0.16), 2.0)
	if texture_key == "range_move":
		_draw_diamond(inner.grow(-4), Color("#58d8ff", 0.12 + pulse * 0.06), Color("#9ff0ff", 0.46), 1.2)
		_draw_corner_brackets(inner, Color("#9ff0ff", 0.82), 0.34, 3.0)
		_draw_move_glyph(inner, Color("#9ff0ff", 0.72 + pulse * 0.12))
	elif texture_key == "range_attack":
		_draw_corner_brackets(inner, Color("#ffd6a4", 0.84), 0.32, 3.0)
		_draw_attack_glyph(inner, Color("#ff4f5e", 0.84 + pulse * 0.10))
	else:
		_draw_corner_brackets(inner, line, 0.32, 3.0)
		var center := inner.get_center()
		draw_circle(center, inner.size.x * 0.16, Color(color, 0.22 + pulse * 0.08))
	if tile == state.hover_tile:
		_draw_diamond(inner.grow(-2), Color("#fff4ba", 0.06), Color("#fff4ba", 0.78), 3.0)


func _draw_tutorial_focus_tile(rect: Rect2) -> void:
	var pulse := 0.55 + 0.35 * sin(anim_time * 4.8)
	var inner := rect.grow(-4)
	_draw_diamond(inner, Color("#f6d26b", 0.04 + pulse * 0.04), Color("#fff4ba", 0.42 + pulse * 0.18), 2.4)
	_draw_corner_brackets(inner.grow(-4), Color("#fff4ba", 0.72 + pulse * 0.16), 0.22, 3.0)
	draw_line(inner.position + Vector2(inner.size.x * 0.18, inner.size.y * 0.18), inner.position + Vector2(inner.size.x * 0.38, inner.size.y * 0.18), Color("#fff4ba", 0.55), 2.0)


func _draw_tutorial_recommended_tile(rect: Rect2) -> void:
	var pulse := 0.55 + 0.35 * sin(anim_time * 5.2)
	var inner := rect.grow(-6)
	var center := inner.get_center()
	_draw_diamond(inner, Color("#8fffd8", 0.05 + pulse * 0.04), Color("#8fffd8", 0.36 + pulse * 0.16), 2.0)
	_draw_corner_brackets(inner.grow(-6), Color("#dffdf2", 0.58 + pulse * 0.14), 0.18, 2.4)
	var marker := PackedVector2Array([
		center + Vector2(0, -inner.size.y * 0.22),
		center + Vector2(inner.size.x * 0.16, -inner.size.y * 0.02),
		center + Vector2(0, inner.size.y * 0.18),
		center + Vector2(-inner.size.x * 0.16, -inner.size.y * 0.02),
	])
	draw_polygon(marker, [Color("#dffdf2", 0.24 + pulse * 0.08)])
	_draw_polyline(marker, Color("#dffdf2", 0.62 + pulse * 0.12), 1.8, true)


func _draw_selected_unit_tile() -> void:
	return


func _valid_tile_color() -> Color:
	if state.selected_card >= 0 and state.selected_card < state.hand.size():
		var card: Dictionary = state.hand[state.selected_card]
		return _skill_event_color(card.get("kind", ""))
	return Color("#8fffd8") if state.action_mode == "move" else Color("#ff6685")


func _valid_tile_texture_key() -> String:
	if state.selected_card >= 0 and state.selected_card < state.hand.size():
		var card: Dictionary = state.hand[state.selected_card]
		match String(card.get("kind", "")):
			BattleAssets.CARD_STRIKE, BattleAssets.CARD_LANCE:
				return "range_attack"
			BattleAssets.CARD_DASH:
				return "range_move"
			_:
				return "range_selected"
	if state.action_mode == "move":
		return "range_move"
	return "range_attack"


func _draw_range_texture(rect: Rect2, key: String, alpha: float) -> void:
	if assets == null:
		return
	var texture: Texture2D = assets.ui_textures.get(key, null) as Texture2D
	if texture == null:
		return
	draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0)))


func _draw_corner_brackets(rect: Rect2, color: Color, ratio: float, width: float) -> void:
	var corner := minf(rect.size.x, rect.size.y) * ratio
	draw_line(rect.position, rect.position + Vector2(corner, 0), color, width)
	draw_line(rect.position, rect.position + Vector2(0, corner), color, width)
	draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x - corner, rect.position.y), color, width)
	draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x, rect.position.y + corner), color, width)
	draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.position.x + corner, rect.end.y), color, width)
	draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.position.x, rect.end.y - corner), color, width)
	draw_line(rect.end, rect.end - Vector2(corner, 0), color, width)
	draw_line(rect.end, rect.end - Vector2(0, corner), color, width)


func _draw_attack_glyph(rect: Rect2, color: Color) -> void:
	var center := rect.get_center()
	var r := rect.size.x * 0.18
	draw_line(center + Vector2(0, -r), center + Vector2(0, r), color, 2.4)
	draw_line(center + Vector2(-r * 0.45, -r * 0.25), center + Vector2(r * 0.45, -r * 0.25), color, 2.0)
	draw_line(center + Vector2(-r * 0.60, r * 0.35), center + Vector2(r * 0.60, r * 0.35), color, 2.0)
	draw_arc(center, r * 1.12, 0.0, TAU, 28, Color(color, color.a * 0.55), 1.6)


func _draw_move_glyph(rect: Rect2, color: Color) -> void:
	var center := rect.get_center()
	var r := rect.size.x * 0.16
	var diamond := [
		center + Vector2(0, -r),
		center + Vector2(r, 0),
		center + Vector2(0, r),
		center + Vector2(-r, 0),
	]
	draw_polygon(diamond, [Color(color, color.a * 0.32), Color(color, color.a * 0.22), Color(color, color.a * 0.32), Color(color, color.a * 0.22)])
	for i in range(diamond.size()):
		draw_line(diamond[i], diamond[(i + 1) % diamond.size()], color, 1.6)


func _draw_action_hints() -> void:
	if state.action_mode != "select":
		return
	for unit in state.get_player_units():
		if bool(unit.get("acted", false)):
			continue
		var cell_rect := state.tile_rect(unit["pos"], board_rect)
		var pulse: float = 0.5 + 0.35 * sin(anim_time * 5.5)
		_draw_diamond(cell_rect.grow(-6), Color("#fff4ba", 0.10 + pulse * 0.10), Color("#fff4ba", 0.36 + pulse * 0.22), 2.4)


func _draw_tactics_hint() -> void:
	if state.chapter_phase != "battle" or state.phase != "player":
		return
	var label := "选择未行动单位"
	var unit := state.selected_unit()
	if not unit.is_empty():
		label = "%s  |  %s" % [unit.get("name", ""), "选择移动格；点自身格原地行动" if state.action_mode == "move" else "选择敌人攻击、技能，或点击待机"]
	var hint_rect := Rect2(board_rect.position + Vector2(18, board_rect.size.y + 14), Vector2(minf(board_rect.size.x - 36.0, 520.0), 30))
	draw_rect(hint_rect, Color("#071126", 0.78))
	draw_rect(hint_rect, Color("#f6d26b", 0.32), false, 1.4)
	draw_string(get_theme_default_font(), hint_rect.position + Vector2(12, 21), label, HORIZONTAL_ALIGNMENT_LEFT, hint_rect.size.x - 24, 14, Color("#fff4ba"))


func _draw_hover_preview() -> void:
	if not state.has_hover_tile():
		return
	var preview := {}
	if state.selected_card >= 0:
		preview = state.selected_card_preview(state.hover_tile)
	elif state.selected_unit_uid != "" and state.hover_tile in state.attack_tiles_for_selected():
		preview = state.normal_attack_preview(state.hover_tile)
	if preview.is_empty():
		return
	var rect := state.tile_rect(state.hover_tile, board_rect)
	var color := _skill_event_color(preview["kind"])
	var valid: bool = preview["valid"]
	var border_color := color if valid else Color("#ff6685")
	_draw_diamond(rect.grow(-5), Color(border_color, 0.18 if valid else 0.1), Color(border_color, 0.72 if valid else 0.38), 3.0)
	if preview["kind"] in [BattleAssets.CARD_STRIKE, BattleAssets.CARD_LANCE, "normal_attack"]:
		_draw_attack_preview(rect, preview, valid)
	elif preview["kind"] == BattleAssets.CARD_DASH and valid:
		_draw_dash_preview(rect)
	elif preview["kind"] in [BattleAssets.CARD_GUARD, BattleAssets.CARD_ENGAGE, BattleAssets.CARD_HEAL]:
		_draw_self_preview(preview)


func _draw_hovered_unit_tiles() -> void:
	var unit := state.hovered_unit()
	if unit.is_empty() or state.selected_card >= 0 or _showing_normal_attack_preview():
		return
	var tiles := state.hovered_unit_tiles()
	var color := Color("#79d8ff") if unit.get("role", "") == "mage" else Color("#ff6685")
	if unit["team"] == "player":
		color = Color("#fff4ba")
	for tile in tiles:
		var rect := state.tile_rect(tile, board_rect)
		_draw_diamond(rect.grow(-8), Color(color, 0.16), Color(color, 0.52), 2.2)
	var unit_rect := state.tile_rect(unit["pos"], board_rect)
	_draw_diamond(unit_rect.grow(-4), Color("#fff4ba", 0.04), Color("#fff4ba", 0.58), 3.0)


func _draw_hovered_unit_tooltip() -> void:
	var unit := state.hovered_unit()
	if unit.is_empty() or state.selected_card >= 0 or _showing_normal_attack_preview():
		return
	_draw_unit_tooltip(unit, state.tile_rect(unit["pos"], board_rect))


func _draw_hovered_tile_tooltip() -> void:
	if not state.has_hover_tile() or state.selected_card >= 0 or _showing_normal_attack_preview():
		return
	if not state.hovered_unit().is_empty():
		return
	var kind := state.terrain_kind(state.hover_tile)
	if kind == "floor":
		return
	var tile_rect := state.tile_rect(state.hover_tile, board_rect)
	var title := state.terrain_label(kind)
	var detail := state.terrain_effect_text(kind)
	var tooltip_size := Vector2(244, 66)
	var pos := tile_rect.position + Vector2(tile_rect.size.x + 10, -8)
	if pos.x + tooltip_size.x > board_rect.end.x:
		pos.x = tile_rect.position.x - tooltip_size.x - 10
	if pos.y + tooltip_size.y > board_rect.end.y:
		pos.y = board_rect.end.y - tooltip_size.y
	pos.y = maxf(board_rect.position.y, pos.y)
	var rect := Rect2(pos, tooltip_size)
	var accent := _terrain_tooltip_color(kind)
	draw_rect(Rect2(rect.position + Vector2(3, 4), rect.size), Color("#030814", 0.36))
	draw_rect(rect, Color("#071126", 0.94))
	draw_rect(rect.grow(-3), Color("#0c1830", 0.62))
	draw_rect(rect, Color(accent, 0.34), false, 1.4)
	draw_circle(rect.position + Vector2(17, 18), 5.0, accent)
	draw_string(get_theme_default_font(), rect.position + Vector2(30, 22), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 42, 13, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(12, 47), detail, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24, 11, Color("#dce6ff"))


func _showing_normal_attack_preview() -> bool:
	return state.selected_card < 0 and state.selected_unit_uid != "" and state.has_hover_tile() and state.hover_tile in state.attack_tiles_for_selected()


func _draw_unit_tooltip(unit: Dictionary, unit_rect: Rect2) -> void:
	var forecast := state.enemy_hover_forecast(unit)
	var tooltip_size := Vector2(292, 166 if not forecast.is_empty() else 120)
	var pos := unit_rect.position + Vector2(unit_rect.size.x + 12, -12)
	if pos.x + tooltip_size.x > board_rect.end.x:
		pos.x = unit_rect.position.x - tooltip_size.x - 12
	if pos.y + tooltip_size.y > board_rect.end.y:
		pos.y = board_rect.end.y - tooltip_size.y
	pos.y = maxf(board_rect.position.y, pos.y)
	var rect := Rect2(pos, tooltip_size)
	draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color("#030814", 0.36))
	draw_rect(rect, Color("#071126", 0.94))
	draw_rect(rect.grow(-3), Color("#0c1830", 0.64))
	draw_rect(rect, Color("#f6d26b", 0.32), false, 1.5)
	draw_rect(rect.grow(-5), Color("#9fd7ff", 0.16), false, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(12, 22), unit["name"], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24, 16, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(12, 43), "%s  攻击 %d  范围 %d" % [_tooltip_role(unit), unit["atk"], int(unit.get("attack_range", 1))], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24, 13, Color("#dce6ff"))
	draw_string(get_theme_default_font(), rect.position + Vector2(12, 62), "武器 %s  技能 %s" % [state.unit_weapon_label(unit), state.unit_skill_label(unit)], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24, 12, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(12, 80), "生命 %d/%d  格挡 %d  %s" % [unit["hp"], unit["max_hp"], unit["block"], state.enemy_intent_label(unit) if unit["team"] == "enemy" else "我方"], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24, 12, Color("#b7caef"))
	draw_string(get_theme_default_font(), rect.position + Vector2(12, 96), state.unit_trait_label(unit), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24, 11, Color("#9fb9dc"))
	if not forecast.is_empty():
		var forecast_rect := Rect2(rect.position + Vector2(10, 112), Vector2(rect.size.x - 20, 44))
		var attacking := bool(forecast.get("attacking", false))
		var accent := Color("#ff6685") if attacking else Color("#ffd66e")
		draw_rect(forecast_rect, Color("#030814", 0.36))
		draw_rect(forecast_rect, Color(accent, 0.22), false, 1.1)
		var action_text := "将攻击" if attacking else "将接近"
		draw_string(get_theme_default_font(), forecast_rect.position + Vector2(8, 13), "%s：%s" % [action_text, forecast.get("target_name", "")], HORIZONTAL_ALIGNMENT_LEFT, forecast_rect.size.x - 16, 11, accent)
		var detail := ""
		if attacking:
			detail = "伤害%d  格挡%d  实际%d" % [int(forecast.get("amount", 0)), int(forecast.get("blocked", 0)), int(forecast.get("damage", 0))]
		else:
			detail = "距离%d / 范围%d" % [int(forecast.get("distance", 0)), int(forecast.get("range", 0))]
		draw_string(get_theme_default_font(), forecast_rect.position + Vector2(8, 28), detail, HORIZONTAL_ALIGNMENT_LEFT, forecast_rect.size.x - 16, 10, Color("#dce6ff"))
		var movement_intent := String(forecast.get("movement_intent", ""))
		if movement_intent != "":
			draw_string(get_theme_default_font(), forecast_rect.position + Vector2(8, 40), "倾向：%s" % movement_intent, HORIZONTAL_ALIGNMENT_LEFT, forecast_rect.size.x - 16, 10, Color("#fff4ba"))


func _tooltip_role(unit: Dictionary) -> String:
	match String(unit.get("role", "")):
		"hero":
			return "纹章剑士"
		"faith":
			return "圣辉"
		"lance":
			return "枪卫"
		"sword":
			return "近战"
		"mage":
			return "术式"
		"guard":
			return "守卫"
	return "单位"


func _draw_attack_preview(rect: Rect2, preview: Dictionary, valid: bool) -> void:
	var hero := state.selected_executor()
	if hero.is_empty():
		hero = state.selected_unit()
	if hero.is_empty():
		return
	var hero_center := state.tile_rect(hero["pos"], board_rect).get_center()
	var target_center := rect.get_center()
	var line_color := Color("#ff6685", 0.38 if valid else 0.18)
	draw_line(hero_center, target_center, line_color, 4.0)
	if valid:
		var label := "击破" if bool(preview.get("kill", false)) else "-%d" % int(preview["amount"])
		var badge := Rect2(target_center + Vector2(-32, -54), Vector2(64, 24))
		draw_rect(badge, Color("#071126", 0.82))
		draw_rect(badge, Color("#ff6685", 0.68), false, 1.4)
		draw_string(get_theme_default_font(), badge.position + Vector2(0, 17), label, HORIZONTAL_ALIGNMENT_CENTER, badge.size.x, 13, Color("#fff4ba"))
		var hp_text := "HP %d" % int(preview.get("after", 0))
		draw_string(get_theme_default_font(), badge.position + Vector2(-18, 40), hp_text, HORIZONTAL_ALIGNMENT_CENTER, badge.size.x + 36, 11, Color("#dce6ff"))
		_draw_forecast_panel(rect, preview)


func _draw_forecast_panel(target_rect: Rect2, preview: Dictionary) -> void:
	var blocked := int(preview.get("blocked", 0))
	var panel_size := Vector2(190, 78 if blocked > 0 else 58)
	var pos := target_rect.position + Vector2(target_rect.size.x + 10, -8)
	if pos.x + panel_size.x > board_rect.end.x:
		pos.x = target_rect.position.x - panel_size.x - 10
	if pos.y + panel_size.y > board_rect.end.y:
		pos.y = board_rect.end.y - panel_size.y
	pos.y = maxf(board_rect.position.y, pos.y)
	var rect := Rect2(pos, panel_size)
	draw_rect(Rect2(rect.position + Vector2(3, 4), rect.size), Color("#030814", 0.36))
	draw_rect(rect, Color("#061026", 0.90))
	draw_rect(rect.grow(-3), Color("#10213a", 0.72))
	draw_rect(rect, Color("#f6d26b", 0.30), false, 1.4)
	var title: String = String(preview.get("title", "攻击"))
	var result: String = "击破" if bool(preview.get("kill", false)) else "剩余 %d" % int(preview.get("after", 0))
	draw_string(get_theme_default_font(), rect.position + Vector2(10, 19), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, 13, Color("#fff4ba"))
	if blocked > 0:
		draw_string(get_theme_default_font(), rect.position + Vector2(10, 38), "总伤害 %d" % int(preview.get("raw_amount", preview.get("amount", 0))), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x * 0.48, 12, Color("#ffcfda"))
		draw_string(get_theme_default_font(), rect.position + Vector2(rect.size.x * 0.48, 38), "格挡 -%d" % blocked, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x * 0.46, 12, Color("#8fffd8"))
		draw_string(get_theme_default_font(), rect.position + Vector2(10, 58), "实际 %d" % int(preview.get("amount", 0)), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x * 0.48, 13, Color("#ffcfda"))
		draw_string(get_theme_default_font(), rect.position + Vector2(rect.size.x * 0.48, 58), result, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x * 0.46, 13, Color("#dce6ff"))
	else:
		draw_string(get_theme_default_font(), rect.position + Vector2(10, 38), "伤害 %d" % int(preview.get("amount", 0)), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x * 0.48, 13, Color("#ffcfda"))
		draw_string(get_theme_default_font(), rect.position + Vector2(rect.size.x * 0.48, 38), result, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x * 0.46, 13, Color("#dce6ff"))


func _draw_dash_preview(rect: Rect2) -> void:
	var center := rect.get_center()
	draw_circle(center, rect.size.x * 0.26, Color("#79f2c9", 0.16))
	draw_arc(center, rect.size.x * 0.34, -PI * 0.15, PI * 1.1, 28, Color("#79f2c9", 0.56), 2.4)
	draw_string(get_theme_default_font(), center + Vector2(-38, -34), "移动", HORIZONTAL_ALIGNMENT_CENTER, 76, 13, Color("#dffdf2"))


func _draw_self_preview(preview: Dictionary) -> void:
	var hero := state.selected_executor()
	if hero.is_empty():
		return
	var center := state.tile_rect(hero["pos"], board_rect).get_center()
	var color := _skill_event_color(preview["kind"])
	draw_circle(center, 46.0 + 4.0 * sin(anim_time * 5.0), Color(color, 0.16))
	draw_arc(center, 52.0, 0.0, TAU, 44, Color(color, 0.52), 2.2)


func _target_label(card: Dictionary) -> String:
	match card["kind"]:
		BattleAssets.CARD_STRIKE:
			return "相邻敌人"
		BattleAssets.CARD_LANCE:
			return "直线目标"
		BattleAssets.CARD_DASH:
			return "空白格"
		BattleAssets.CARD_GUARD, BattleAssets.CARD_ENGAGE, BattleAssets.CARD_HEAL:
			return "自身"
	return "目标"


func _draw_units() -> void:
	var ordered_units: Array = state.units.duplicate()
	ordered_units.sort_custom(func(a, b):
		var pa: Vector2i = a.get("pos", Vector2i.ZERO)
		var pb: Vector2i = b.get("pos", Vector2i.ZERO)
		var da := pa.x + pa.y
		var db := pb.x + pb.y
		if da == db:
			return pa.y < pb.y
		return da < db
	)
	for unit in ordered_units:
		var center: Vector2 = _unit_draw_center(unit)
		var unit_size := state.tile_rect(unit["pos"], board_rect).size.x * 1.12
		var fx: Dictionary = state.unit_fx.get(unit["uid"], {})
		var fx_progress := 1.0
		if not fx.is_empty():
			fx_progress = clampf(float(fx["age"]) / float(fx["duration"]), 0.0, 1.0)
		var bob := sin(anim_time * 2.0 + float(unit["pos"].x + unit["pos"].y)) * 2.0
		var shake := Vector2.ZERO
		if not fx.is_empty() and fx["kind"] == "hit":
			shake.x = sin(fx_progress * TAU * 4.0) * (1.0 - fx_progress) * 10.0
		if fx.is_empty() or fx["kind"] != "death":
			center.y += bob
		center += shake
		var unit_alpha := _unit_alpha(unit, fx, fx_progress)
		var outer_radius := unit_size * 0.44
		var is_player: bool = unit["team"] == "player"
		var token: Texture2D = assets.token_textures.get(unit["id"])
		var action_sheet: Texture2D = assets.unit_action_sheets.get(_unit_sheet_key(unit), null) as Texture2D
		var sheet_meta := _unit_sheet_meta(unit)
		_draw_unit_base(center, unit_size, unit, fx)
		var acted_fade := is_player and bool(unit.get("acted", false)) and fx.is_empty()
		var unit_modulate := Color(0.54, 0.54, 0.54, unit_alpha * 0.72) if acted_fade else Color(1.0, 1.0, 1.0, unit_alpha)
		if not fx.is_empty() and fx["kind"] == "move":
			var ghost_alpha := (1.0 - fx_progress) * 0.32
			draw_circle(center + Vector2(-unit_size * 0.16, 4), outer_radius * 0.92, Color("#8fffd8", ghost_alpha))
		if not fx.is_empty() and fx["kind"] == "prepare":
			draw_arc(center, outer_radius * 1.14, 0.0, TAU, 44, Color("#fff4ba", 0.48 * (1.0 - fx_progress)), 3.0)
		var outline_color := _unit_outline_color(unit, fx)
		var outline_strength := _unit_outline_strength(unit, fx, fx_progress)
		var flash_strength := _unit_flash_strength(fx, fx_progress)
		if action_sheet != null:
			_draw_unit_action_sheet_frame(action_sheet, sheet_meta, center, unit_size, unit, fx, unit_modulate, outline_color, outline_strength, flash_strength)
		elif token != null:
			var sprite_size := unit_size * 1.02
			var token_rect := Rect2(center - Vector2(sprite_size * 0.5, sprite_size * 0.72), Vector2(sprite_size, sprite_size))
			_draw_texture_with_outline(token, token_rect, unit_modulate, outline_color, outline_strength, flash_strength)
		else:
			var body: Color = Color("#8a8a8a", unit_alpha * 0.72) if acted_fade else (Color("#32d2ff", unit_alpha) if is_player else Color("#ff5f7d", unit_alpha))
			draw_circle(center + Vector2(0, -5), unit_size * 0.28, body)
		var hp_ratio: float = float(unit["hp"]) / float(unit["max_hp"])
		var hp_rect := Rect2(center + Vector2(-unit_size * 0.42, unit_size * 0.40), Vector2(unit_size * 0.84, 12))
		if unit_alpha > 0.2:
			_draw_bar(hp_rect, hp_ratio, Color("#65e08c") if is_player else Color("#ff6685"), "%d/%d" % [maxi(unit["hp"], 0), unit["max_hp"]])
		if unit["block"] > 0:
			draw_circle(center + Vector2(unit_size * 0.36, -unit_size * 0.34), 14, Color("#8fffd8", unit_alpha))
			draw_string(get_theme_default_font(), center + Vector2(unit_size * 0.27, -unit_size * 0.28), str(unit["block"]), HORIZONTAL_ALIGNMENT_CENTER, 16, 12, Color("#10233b"))
		if is_player and bool(unit.get("acted", false)):
			var tag_rect := Rect2(center + Vector2(-unit_size * 0.33, -unit_size * 0.58), Vector2(unit_size * 0.66, 18))
			draw_rect(tag_rect, Color("#030814", 0.58))
			draw_rect(tag_rect, Color("#b7caef", 0.28), false, 1.0)
			draw_string(get_theme_default_font(), tag_rect.position + Vector2(0, 13), "待机", HORIZONTAL_ALIGNMENT_CENTER, tag_rect.size.x, 11, Color("#dce6ff", 0.86))
		if is_player and state.player_power > 0:
			_draw_power_mark(center, unit_size)
		if unit_alpha > 0.3:
			_draw_low_hp_mark(center, unit_size, hp_ratio)
		if not fx.is_empty() and fx["kind"] == "hit":
			draw_circle(center, outer_radius * (1.0 + fx_progress * 0.55), Color("#ff6685", 0.22 * (1.0 - fx_progress)), false, 3.0)
		if not fx.is_empty() and fx["kind"] == "death":
			draw_circle(center, outer_radius * (0.9 + fx_progress * 0.65), Color("#fff4ba", 0.24 * (1.0 - fx_progress)), false, 3.0)


func _draw_unit_base(_center: Vector2, _unit_size: float, unit: Dictionary, _fx: Dictionary) -> void:
	var is_player: bool = unit["team"] == "player"
	var role: String = unit.get("role", "sword")
	var _base_color := Color("#f6d26b", 0.42) if is_player else Color("#ff6e91", 0.36)
	if role == "faith":
		_base_color = Color("#8fffd8", 0.38)
	elif role == "mage":
		_base_color = Color("#79d8ff", 0.38)
	elif role == "guard":
		_base_color = Color("#8fffd8", 0.34)
	return


func _draw_unit_action_sheet_frame(sheet: Texture2D, sheet_meta: Dictionary, center: Vector2, unit_size: float, unit: Dictionary, fx: Dictionary, modulate: Color, outline_color: Color, outline_strength: float, flash_strength: float) -> void:
	var columns := 4
	var rows := 6
	var frame_size: Vector2 = sheet_meta.get("frame_size", Vector2(float(sheet.get_width()) / float(columns), float(sheet.get_height()) / float(rows)))
	if frame_size.x <= 0.0 or frame_size.y <= 0.0:
		frame_size = Vector2(float(sheet.get_width()) / float(columns), float(sheet.get_height()) / float(rows))
	var source_frame_size := Vector2(float(sheet.get_width()) / float(columns), float(sheet.get_height()) / float(rows))
	var action_context := _unit_action_context(unit, fx)
	var action: String = action_context["action"]
	var row := _action_row(action)
	var frame := _action_frame(unit, action_context)
	var source := Rect2(Vector2(float(frame) * source_frame_size.x, float(row) * source_frame_size.y), source_frame_size)
	var sprite_size := unit_size * 1.30
	var draw_scale := sprite_size / maxf(1.0, frame_size.x)
	var pivot: Vector2 = sheet_meta.get("pivot", Vector2(frame_size.x * 0.5, frame_size.y * unit_sprite_y_ratio))
	var dest_size := Vector2(frame_size.x, frame_size.y) * draw_scale
	var dest := Rect2(center - pivot * draw_scale, dest_size)
	var flip_h := _sheet_should_flip(unit, sheet_meta)
	_draw_texture_region_with_outline(sheet, dest, source, modulate, outline_color, outline_strength, flash_strength, flip_h)


func _draw_texture_with_outline(texture: Texture2D, dest: Rect2, texture_modulate: Color, outline_color: Color, outline_strength: float, flash_strength: float) -> void:
	if outline_strength > 0.01:
		var outline_modulate := Color(outline_color, outline_color.a * outline_strength)
		for offset in _outline_offsets(maxf(1.0, dest.size.x * 0.035)):
			draw_texture_rect(texture, Rect2(dest.position + offset, dest.size), false, outline_modulate)
	draw_texture_rect(texture, dest, false, texture_modulate)
	if flash_strength > 0.01:
		draw_texture_rect(texture, dest, false, Color(1.0, 0.95, 0.78, flash_strength))


func _draw_texture_region_with_outline(texture: Texture2D, dest: Rect2, source: Rect2, texture_modulate: Color, outline_color: Color, outline_strength: float, flash_strength: float, flip_h: bool = false) -> void:
	if outline_strength > 0.01:
		var outline_modulate := Color(outline_color, outline_color.a * outline_strength)
		for offset in _outline_offsets(maxf(1.0, dest.size.x * 0.035)):
			_draw_sheet_region(texture, Rect2(dest.position + offset, dest.size), source, outline_modulate, flip_h)
	_draw_sheet_region(texture, dest, source, texture_modulate, flip_h)
	if flash_strength > 0.01:
		_draw_sheet_region(texture, dest, source, Color(1.0, 0.95, 0.78, flash_strength), flip_h)


func _draw_sheet_region(texture: Texture2D, dest: Rect2, source: Rect2, texture_modulate: Color, flip_h: bool = false) -> void:
	if not flip_h:
		draw_texture_rect_region(texture, dest, source, texture_modulate)
		return
	draw_set_transform(dest.position + Vector2(dest.size.x, 0), 0.0, Vector2(-1, 1))
	draw_texture_rect_region(texture, Rect2(Vector2.ZERO, dest.size), source, texture_modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _outline_offsets(radius: float) -> Array[Vector2]:
	return [
		Vector2(-radius, 0),
		Vector2(radius, 0),
		Vector2(0, -radius),
		Vector2(0, radius),
		Vector2(-radius * 0.72, -radius * 0.72),
		Vector2(radius * 0.72, -radius * 0.72),
		Vector2(-radius * 0.72, radius * 0.72),
		Vector2(radius * 0.72, radius * 0.72),
	]


func _unit_outline_color(unit: Dictionary, fx: Dictionary) -> Color:
	if not fx.is_empty():
		match String(fx.get("kind", "")):
			"hit":
				return Color("#ff6685", 0.88)
			"guard":
				return Color("#8fffd8", 0.82)
			"death":
				return Color("#fff4ba", 0.72)
	if unit.get("uid", "") == state.selected_unit_uid:
		return Color("#fff4ba", 0.96)
	if unit["team"] == "player" and not bool(unit.get("acted", false)) and state.action_mode == "select":
		return Color("#79f2c9", 0.18)
	return Color("#ffffff", 0.0)


func _unit_outline_strength(unit: Dictionary, fx: Dictionary, fx_progress: float) -> float:
	if not fx.is_empty():
		match String(fx.get("kind", "")):
			"hit":
				return 0.86 * (1.0 - fx_progress)
			"guard":
				return 0.62 * sin(fx_progress * PI)
			"death":
				return 0.44 * (1.0 - fx_progress)
	if unit.get("uid", "") == state.selected_unit_uid:
		return 0.92 + 0.14 * sin(anim_time * 6.2)
	if unit["team"] == "player" and not bool(unit.get("acted", false)) and state.action_mode == "select":
		return 0.0
	return 0.0


func _unit_flash_strength(fx: Dictionary, fx_progress: float) -> float:
	if fx.is_empty():
		return 0.0
	match String(fx.get("kind", "")):
		"hit":
			return 0.62 * (1.0 - fx_progress)
		"death":
			return 0.32 * sin(fx_progress * PI)
		"guard":
			return 0.18 * sin(fx_progress * PI)
	return 0.0


func _unit_sheet_key(unit: Dictionary) -> String:
	var character_id: String = unit.get("character_id", "")
	if character_id != "":
		return character_id
	var unit_key: String = unit.get("unit_key", "")
	if unit_key != "" and assets != null and assets.unit_action_sheets.has(unit_key):
		return unit_key
	return String(unit.get("role", unit.get("id", "")))


func _unit_sheet_meta(unit: Dictionary) -> Dictionary:
	if assets == null:
		return {}
	return assets.unit_action_sheet_meta_for(_unit_sheet_key(unit))


func _sheet_should_flip(unit: Dictionary, sheet_meta: Dictionary) -> bool:
	var desired := "right" if String(unit.get("team", "")) == "player" else "left"
	var base := String(sheet_meta.get("base_facing", "left"))
	return base != desired


func _unit_action_context(unit: Dictionary, fx: Dictionary) -> Dictionary:
	if bool(unit.get("dead", false)):
		return _action_context_from_fx("defeat", fx)
	if not fx.is_empty():
		match String(fx.get("kind", "")):
			"move":
				return _action_context_from_fx("move", fx)
			"hit":
				return _action_context_from_fx("hit", fx)
			"death":
				return _action_context_from_fx("defeat", fx)
			"guard":
				return _action_context_from_fx("skill", fx)
	var action_event := _action_unit_event(unit.get("uid", ""))
	if not action_event.is_empty():
		match String(action_event.get("kind", "")):
			"move":
				return _action_context_from_event("move", action_event)
			"attack":
				return _action_context_from_event("attack", action_event)
			"skill_release":
				return _action_context_from_event(String(action_event.get("action_hint", "skill")), action_event)
			"guard", "heal", "engage", "prepare":
				return _action_context_from_event("skill", action_event)
			"hit":
				return _action_context_from_event("hit", action_event)
			"death":
				return _action_context_from_event("defeat", action_event)
	return {
		"action": "idle",
		"progress": 0.0,
		"event_driven": false,
		"uid_offset": float(abs(hash(unit.get("uid", "")) % 1000)) * 0.01,
	}


func _action_context_from_fx(action: String, fx: Dictionary) -> Dictionary:
	var progress := 0.0
	if not fx.is_empty() and float(fx.get("duration", 0.0)) > 0.0:
		progress = clampf(float(fx.get("age", 0.0)) / float(fx.get("duration", 1.0)), 0.0, 1.0)
	return {
		"action": action,
		"progress": progress,
		"event_driven": true,
		"uid_offset": 0.0,
	}


func _action_context_from_event(action: String, event: Dictionary) -> Dictionary:
	var progress := 0.0
	if float(event.get("duration", 0.0)) > 0.0:
		progress = clampf(float(event.get("age", 0.0)) / float(event.get("duration", 1.0)), 0.0, 1.0)
	return {
		"action": action,
		"progress": progress,
		"event_driven": true,
		"uid_offset": 0.0,
	}


func _action_row(action: String) -> int:
	match action:
		"idle":
			return 0
		"move":
			return 1
		"attack":
			return 2
		"skill":
			return 3
		"hit":
			return 4
		"defeat":
			return 5
	return 0


func _action_frame(_unit: Dictionary, context: Dictionary) -> int:
	var action: String = context.get("action", "idle")
	if bool(context.get("event_driven", false)):
		var progress: float = clampf(float(context.get("progress", 0.0)), 0.0, 0.999)
		return _event_action_frame(action, progress)
	var offset: float = float(context.get("uid_offset", 0.0))
	var speed := 5.0
	if action == "idle":
		speed = 2.8
	elif action == "defeat":
		speed = 3.0
	return int(floor((anim_time + offset) * speed)) % 4


func _event_action_frame(action: String, progress: float) -> int:
	match action:
		"attack":
			if progress < 0.18:
				return 0
			if progress < 0.46:
				return 1
			if progress < 0.78:
				return 2
			return 3
		"skill":
			if progress < 0.20:
				return 0
			if progress < 0.52:
				return 1
			if progress < 0.82:
				return 2
			return 3
		"hit":
			if progress < 0.22:
				return 0
			if progress < 0.52:
				return 1
			if progress < 0.78:
				return 2
			return 3
		"defeat":
			if progress < 0.20:
				return 0
			if progress < 0.46:
				return 1
			if progress < 0.72:
				return 2
			return 3
		"move":
			if progress < 0.22:
				return 0
			if progress < 0.48:
				return 1
			if progress < 0.74:
				return 2
			return 3
	return clampi(int(floor(progress * 4.0)), 0, 3)


func _draw_low_hp_mark(center: Vector2, unit_size: float, hp_ratio: float) -> void:
	if hp_ratio > 0.35:
		return
	var pulse := 0.55 + 0.3 * sin(anim_time * 7.0)
	var warn_color := Color("#ff6685", 0.22 + pulse * 0.16)
	draw_arc(center, unit_size * 0.51, -PI * 0.82, -PI * 0.18, 18, warn_color, 3.0)
	draw_arc(center, unit_size * 0.51, PI * 0.18, PI * 0.82, 18, warn_color, 3.0)


func _draw_power_mark(center: Vector2, unit_size: float) -> void:
	var mark_rect := Rect2(center + Vector2(-unit_size * 0.54, -unit_size * 0.55), Vector2(34, 20))
	draw_rect(Rect2(mark_rect.position + Vector2(0, 2), mark_rect.size), Color("#030814", 0.30))
	draw_rect(mark_rect, Color("#17120c", 0.90))
	draw_rect(mark_rect, Color("#c19a4a", 0.66), false, 1.2)
	draw_rect(mark_rect.grow(-3), Color("#f6d26b", 0.18), false, 1.0)
	draw_string(get_theme_default_font(), mark_rect.position + Vector2(0, 15), "+%d力" % state.player_power, HORIZONTAL_ALIGNMENT_CENTER, mark_rect.size.x, 10, Color("#fff4ba"))


func _draw_skill_release_events() -> void:
	for visual_event in state.visual_events:
		if visual_event.get("kind", "") != "skill_release":
			continue
		var progress: float = clampf(float(visual_event["age"]) / float(visual_event["duration"]), 0.0, 1.0)
		var tile: Vector2i = visual_event["tile"]
		var rect := state.tile_rect(tile, board_rect)
		var center := rect.get_center()
		var skill_kind: String = visual_event.get("skill_kind", "")
		var color := _skill_event_color(skill_kind)
		var radius := rect.size.x * (0.26 + progress * 0.38)
		color.a = 0.42 * (1.0 - progress)
		draw_circle(center, radius, color)
		draw_arc(center, radius * 0.88, -PI * 0.22, PI * 1.2, 36, Color("#fff4ba", 0.62 * (1.0 - progress)), 2.4)
		draw_string(get_theme_default_font(), center + Vector2(-54, -rect.size.y * 0.52 - 18.0 * progress), visual_event.get("message", "技能"), HORIZONTAL_ALIGNMENT_CENTER, 108, 14, Color("#fff4ba", 1.0 - progress))


func _skill_event_color(skill_kind: String) -> Color:
	match skill_kind:
		"normal_attack":
			return Color("#ff6685")
		BattleAssets.CARD_STRIKE, BattleAssets.CARD_LANCE:
			return Color("#ff6685")
		BattleAssets.CARD_DASH:
			return Color("#79f2c9")
		BattleAssets.CARD_GUARD:
			return Color("#8fffd8")
		BattleAssets.CARD_ENGAGE:
			return Color("#6ad7ff")
		BattleAssets.CARD_HEAL:
			return Color("#65e08c")
	return Color("#fff4ba")


func _terrain_tooltip_color(kind: String) -> Color:
	match kind:
		"high":
			return Color("#f6d26b")
		"holy":
			return Color("#8fffd8")
		"fire":
			return Color("#ff6685")
		"wall", "pillar":
			return Color("#b7caef")
		"gate":
			return Color("#fff4ba")
		"marker":
			return Color("#6ad7ff")
	return Color("#dce6ff")


func _unit_draw_center(unit: Dictionary) -> Vector2:
	var base_center: Vector2 = BattleProjectionScript.tile_unit_anchor(unit["pos"], board_rect, BattleState.GRID_W, BattleState.GRID_H)
	var active_event := _motion_unit_event(unit["uid"])
	if active_event.is_empty():
		return base_center
	var kind: String = active_event["kind"]
	var progress: float = clampf(float(active_event["age"]) / float(active_event["duration"]), 0.0, 1.0)
	if kind == "move" and active_event.has("from_tile"):
		var from_tile: Vector2i = active_event["from_tile"]
		var to_tile: Vector2i = active_event.get("to_tile", unit["pos"])
		var from_center: Vector2 = BattleProjectionScript.tile_unit_anchor(from_tile, board_rect, BattleState.GRID_W, BattleState.GRID_H)
		var to_center: Vector2 = BattleProjectionScript.tile_unit_anchor(to_tile, board_rect, BattleState.GRID_W, BattleState.GRID_H)
		var eased: float = 1.0 - pow(1.0 - progress, 3.0)
		return from_center.lerp(to_center, eased) + Vector2(0, -sin(progress * PI) * 16.0)
	if kind == "attack" and active_event.has("from_tile") and active_event.has("to_tile"):
		var attack_from_tile: Vector2i = active_event["from_tile"]
		var attack_to_tile: Vector2i = active_event["to_tile"]
		var attack_from: Vector2 = BattleProjectionScript.tile_unit_anchor(attack_from_tile, board_rect, BattleState.GRID_W, BattleState.GRID_H)
		var attack_to: Vector2 = BattleProjectionScript.tile_unit_anchor(attack_to_tile, board_rect, BattleState.GRID_W, BattleState.GRID_H)
		var direction := (attack_to - attack_from).normalized()
		var role := _unit_role_by_uid(unit["uid"])
		var lunge := sin(progress * PI) * (10.0 if role == "mage" else 20.0)
		return base_center + direction * lunge
	if kind == "prepare":
		return base_center + Vector2(0, -4.0 * sin(progress * PI))
	return base_center


func _unit_alpha(unit: Dictionary, fx: Dictionary, fx_progress: float) -> float:
	if bool(unit.get("dead", false)):
		if not fx.is_empty() and fx["kind"] == "death":
			if fx_progress < 0.70:
				return 1.0
			return clampf(1.0 - ((fx_progress - 0.70) / 0.30), 0.0, 1.0)
		return 0.0
	return 1.0


func _motion_unit_event(uid: String) -> Dictionary:
	for visual_event in state.visual_events:
		if visual_event.get("uid", "") == uid and visual_event["kind"] in ["move", "attack", "prepare"]:
			return visual_event
	return {}


func _action_unit_event(uid: String) -> Dictionary:
	var priorities := ["death", "hit", "attack", "skill_release", "guard", "heal", "engage", "move", "prepare"]
	for kind in priorities:
		for visual_event in state.visual_events:
			if visual_event.get("uid", "") == uid and visual_event.get("kind", "") == kind:
				return visual_event
	return {}


func _unit_role_by_uid(uid: String) -> String:
	for unit in state.units:
		if unit.get("uid", "") == uid:
			return unit.get("role", "")
	return ""


func _draw_enemy_intents() -> void:
	if state.phase != "player":
		return
	var unit := state.focused_enemy()
	if unit.is_empty():
		return
	var forecast := state.focused_enemy_forecast()
	var center: Vector2 = state.tile_rect(unit["pos"], board_rect).get_center()
	var attacking: bool = bool(forecast.get("attacking", false))
	var label: String = String(forecast.get("summary", state.enemy_intent_label(unit)))
	var intent_color: Color = _intent_color(unit, attacking)
	var intent_rect := Rect2(center + Vector2(-88, -68), Vector2(176, 28))
	draw_rect(intent_rect, Color("#071126", 0.86))
	draw_rect(intent_rect, intent_color, false, 1.5)
	draw_string(get_theme_default_font(), intent_rect.position + Vector2(8, 19), _shorten_to_width(label, intent_rect.size.x - 16.0, 11), HORIZONTAL_ALIGNMENT_LEFT, intent_rect.size.x - 16.0, 11, intent_color)


func _draw_intent_target_mark(center: Vector2, color: Color, attacking: bool) -> void:
	var radius := 22.0 if attacking else 17.0
	var alpha := 0.42 if attacking else 0.24
	draw_arc(center, radius, 0.0, TAU, 36, Color(color, alpha), 2.2 if attacking else 1.5)
	draw_line(center + Vector2(-radius * 0.45, 0), center + Vector2(radius * 0.45, 0), Color(color, alpha), 1.4)
	draw_line(center + Vector2(0, -radius * 0.45), center + Vector2(0, radius * 0.45), Color(color, alpha), 1.4)


func _intent_color(unit: Dictionary, attacking: bool) -> Color:
	if unit.get("role", "") == "mage":
		return Color("#79d8ff") if attacking else Color("#b7caef")
	if unit.get("role", "") == "guard":
		return Color("#8fffd8") if unit["hp"] <= unit["max_hp"] / 2 and unit["block"] <= 0 else Color("#ffd66e")
	return Color("#ff6685") if attacking else Color("#ffd66e")


func _shorten(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, maxi(0, max_chars - 1)) + "…"


func _shorten_to_width(text: String, width: float, font_size: int) -> String:
	var max_chars := maxi(4, int(width / maxf(6.0, float(font_size) * 0.72)))
	return _shorten(text, max_chars)
