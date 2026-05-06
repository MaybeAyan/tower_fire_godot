@tool
class_name LevelPreview
extends Control

const BattleContentScript := preload("res://scripts/core/BattleContent.gd")
const GRID_W := 10
const GRID_H := 8

@export var encounter_id := "chapter1_1":
	set(value):
		encounter_id = value
		queue_redraw()

@export_range(36, 96, 1) var tile_size := 58:
	set(value):
		tile_size = value
		custom_minimum_size = Vector2(float(GRID_W * tile_size + 220), float(GRID_H * tile_size + 56))
		queue_redraw()

var content = BattleContentScript.new()


func _ready() -> void:
	custom_minimum_size = Vector2(float(GRID_W * tile_size + 220), float(GRID_H * tile_size + 56))
	queue_redraw()


func _draw() -> void:
	var origin := Vector2(24, 42)
	var terrain: Dictionary = content.battlefield_terrain(encounter_id)
	var units: Array = content.build_encounter(encounter_id, content.build_party())
	var tutorial_steps: Array = content.battle_tutorial_steps(encounter_id)
	_draw_board(origin, terrain, tutorial_steps)
	_draw_units(origin, units)
	_draw_sidebar(origin + Vector2(float(GRID_W * tile_size + 22), 0), units, tutorial_steps)


func _draw_board(origin: Vector2, terrain: Dictionary, tutorial_steps: Array) -> void:
	draw_string(get_theme_default_font(), Vector2(origin.x, 24), "关卡预览：%s" % encounter_id, HORIZONTAL_ALIGNMENT_LEFT, 360, 15, Color("#fff4ba"))
	var tutorial_focus := _tutorial_focus_lookup(tutorial_steps)
	for y in range(GRID_H):
		for x in range(GRID_W):
			var tile := Vector2i(x, y)
			var rect := Rect2(origin + Vector2(float(x * tile_size), float(y * tile_size)), Vector2(tile_size, tile_size))
			var kind: String = terrain.get(tile, "floor")
			draw_rect(rect, _terrain_color(kind, x, y))
			draw_rect(rect, Color("#eaf6ff", 0.24), false, 1.0)
			var focus_steps: Array = tutorial_focus.get(tile, [])
			if not focus_steps.is_empty():
				_draw_tutorial_focus_marker(rect, focus_steps)
			if kind != "floor":
				draw_string(get_theme_default_font(), rect.position + Vector2(0, rect.size.y * 0.58), _terrain_label(kind), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, Color("#fff4ba"))


func _draw_units(origin: Vector2, units: Array) -> void:
	for unit in units:
		var pos: Vector2i = unit.get("pos", Vector2i.ZERO)
		var rect := Rect2(origin + Vector2(float(pos.x * tile_size), float(pos.y * tile_size)), Vector2(tile_size, tile_size))
		var center := rect.get_center()
		var color := Color("#6ad7ff") if unit.get("team", "") == "player" else Color("#ff6685")
		draw_circle(center, rect.size.x * 0.31, Color("#071126", 0.84))
		draw_circle(center, rect.size.x * 0.27, color)
		draw_circle(center, rect.size.x * 0.27, Color("#fff4ba", 0.35), false, 1.5)
		draw_string(get_theme_default_font(), center + Vector2(-rect.size.x * 0.24, 4), _unit_initial(unit), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x * 0.48, 15, Color("#101832"))


func _draw_sidebar(pos: Vector2, units: Array, tutorial_steps: Array) -> void:
	var rect := Rect2(pos, Vector2(230, float(GRID_H * tile_size)))
	draw_rect(rect, Color("#071126", 0.72))
	draw_rect(rect, Color("#75cfff", 0.18), false, 1.2)
	draw_string(get_theme_default_font(), rect.position + Vector2(12, 22), "出生单位", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24, 14, Color("#fff4ba"))
	var row_y := rect.position.y + 48.0
	for unit in units:
		var color := Color("#6ad7ff") if unit.get("team", "") == "player" else Color("#ff6685")
		draw_circle(Vector2(rect.position.x + 20, row_y - 4), 5, color)
		var pos_text: String = "(%d,%d)" % [unit.get("pos", Vector2i.ZERO).x, unit.get("pos", Vector2i.ZERO).y]
		draw_string(get_theme_default_font(), Vector2(rect.position.x + 34, row_y), "%s %s" % [unit.get("name", ""), pos_text], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 46, 11, Color("#dce6ff"))
		row_y += 19.0
	row_y += 12.0
	draw_string(get_theme_default_font(), Vector2(rect.position.x + 12, row_y), "教学步骤", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24, 14, Color("#fff4ba"))
	row_y += 24.0
	if tutorial_steps.is_empty():
		draw_string(get_theme_default_font(), Vector2(rect.position.x + 12, row_y), "无", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24, 11, Color("#8fa7c7"))
	else:
		for i in range(tutorial_steps.size()):
			var step: Dictionary = tutorial_steps[i]
			var label := "%d. %s" % [i + 1, String(step.get("title", ""))]
			draw_string(get_theme_default_font(), Vector2(rect.position.x + 12, row_y), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24, 11, Color("#dce6ff"))
			row_y += 17.0
			var action := String(step.get("action", ""))
			var detail := action
			if step.has("character_id"):
				detail += " / %s" % String(step.get("character_id", ""))
			if step.has("required_skill_id"):
				detail += " / %s" % String(step.get("required_skill_id", ""))
			draw_string(get_theme_default_font(), Vector2(rect.position.x + 24, row_y), detail, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36, 10, Color("#79f2c9"))
			row_y += 18.0


func _tutorial_focus_lookup(tutorial_steps: Array) -> Dictionary:
	var lookup := {}
	for i in range(tutorial_steps.size()):
		var step: Dictionary = tutorial_steps[i]
		for raw_pos in step.get("focus", []):
			var tile := content._array_to_vector2i(raw_pos)
			if not lookup.has(tile):
				lookup[tile] = []
			lookup[tile].append(i + 1)
	return lookup


func _draw_tutorial_focus_marker(rect: Rect2, focus_steps: Array) -> void:
	var inner := rect.grow(-4)
	draw_rect(inner, Color("#f6d26b", 0.18))
	draw_rect(inner, Color("#fff4ba", 0.62), false, 2.0)
	var label := _join_ints(focus_steps, "/")
	draw_string(get_theme_default_font(), inner.position + Vector2(0, 14), label, HORIZONTAL_ALIGNMENT_CENTER, inner.size.x, 12, Color("#fff4ba"))


func _terrain_color(kind: String, x: int, y: int) -> Color:
	match kind:
		"wall":
			return Color("#182235", 0.88)
		"pillar":
			return Color("#2d3549", 0.9)
		"gate":
			return Color("#9f7a28", 0.76)
		"high":
			return Color("#8c7b45", 0.68)
		"holy":
			return Color("#247b66", 0.68)
		"fire":
			return Color("#84333a", 0.74)
		"marker":
			return Color("#245a8f", 0.66)
	return Color("#30465f", 0.62) if (x + y) % 2 == 0 else Color("#25384f", 0.62)


func _terrain_label(kind: String) -> String:
	match kind:
		"wall":
			return "墙"
		"pillar":
			return "柱"
		"gate":
			return "门"
		"high":
			return "高"
		"holy":
			return "愈"
		"fire":
			return "火"
		"marker":
			return "标"
	return ""


func _unit_initial(unit: Dictionary) -> String:
	var name: String = unit.get("name", "")
	if name.is_empty():
		return "?"
	return name.substr(0, 1)


func _join_ints(values: Array, separator: String) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(str(value))
	return separator.join(parts)
