class_name SidebarLayer
extends Control

const BattleLayoutScript := preload("res://scripts/core/BattleLayout.gd")

const PANEL_FILL := Color("#07182c", 0.62)
const PANEL_LINE := Color("#9ff0ff", 0.28)
const GOLD := Color("#f6d26b")
const CYAN := Color("#6ad7ff")
const MINT := Color("#65e08c")
const ROSE := Color("#ff77a0")
const STONE := Color("#17283d", 0.78)
const INK := Color("#071126", 0.86)

var state: BattleState
var assets: BattleAssets
var layout = BattleLayoutScript.new()
var end_turn_rect: Rect2 = Rect2()
var undo_move_rect: Rect2 = Rect2()
var restart_rect: Rect2 = Rect2()
var log_toggle_rect: Rect2 = Rect2()
var character_prev_rect: Rect2 = Rect2()
var character_next_rect: Rect2 = Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if state == null or assets == null:
		return
	character_prev_rect = Rect2()
	character_next_rect = Rect2()
	log_toggle_rect = Rect2()
	var panel: Rect2 = layout.sidebar_rect if layout != null else Rect2(760, 96, 360, 360)
	_draw_shell(panel)

	var inner := panel.grow(-26)
	var footer_y := panel.end.y - 50.0
	var gap := 10.0
	var available_h := maxf(220.0, footer_y - inner.position.y)
	var header_h := 36.0
	var mission_h := 54.0
	var hero_h := clampf(available_h - header_h - mission_h - 34.0 - gap * 2.0, 132.0, 154.0)
	var log_h := maxf(30.0, available_h - header_h - hero_h - mission_h - gap * 2.0)
	var header_rect := Rect2(inner.position, Vector2(inner.size.x, header_h))
	var hero_rect := Rect2(header_rect.position + Vector2(0, header_rect.size.y + gap), Vector2(inner.size.x, hero_h))
	var mission_rect := Rect2(hero_rect.position + Vector2(0, hero_rect.size.y + gap), Vector2(inner.size.x, mission_h))
	var log_rect := Rect2(mission_rect.position + Vector2(0, mission_rect.size.y + gap), Vector2(inner.size.x, log_h))

	_draw_header(header_rect)
	_draw_character_section(hero_rect)
	_draw_mission_section(mission_rect)
	_draw_log_section(log_rect)
	_draw_footer(panel, footer_y)


func _draw_shell(panel: Rect2) -> void:
	draw_rect(Rect2(panel.position + Vector2(4, 6), panel.size), Color("#030814", 0.26))
	draw_rect(panel, Color("#061326", 0.58))
	draw_rect(panel.grow(-5), PANEL_FILL)
	_draw_brush_wash(panel.grow(-10), 0.84)
	draw_rect(panel.grow(-15), Color("#19324a", 0.16))
	draw_rect(panel, Color("#9ff0ff", 0.34), false, 2.0)
	draw_rect(panel.grow(-5), Color("#e5fbff", 0.24), false, 1.4)
	draw_rect(panel.grow(-13), Color("#f6d26b", 0.12), false, 1.0)
	_draw_frame_corners(panel.grow(-5), Color("#f6d26b", 0.58), 30.0, 1.8)


func _draw_header(rect: Rect2) -> void:
	var phase_color := MINT if state.phase == "player" else ROSE if state.phase == "enemy" else GOLD
	draw_rect(rect, Color("#071126", 0.82))
	draw_rect(rect, Color("#9ff0ff", 0.16), false, 1.0)
	var pill_w := 64.0
	draw_string(get_theme_default_font(), rect.position + Vector2(12, 16), "战术面板", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - pill_w * 2.0 - 28.0, 14, Color("#fff1b2"))
	draw_string(get_theme_default_font(), rect.position + Vector2(12, 30), "第 %d 战" % state.battle_index, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - pill_w * 2.0 - 28.0, 9, Color("#8ea4bf"))
	_draw_pill(Rect2(rect.position + Vector2(rect.size.x - pill_w * 2.0 - 10.0, 7), Vector2(pill_w, 20)), "回合 %d" % state.turn, Color("#071126", 0.70), GOLD)
	_draw_pill(Rect2(rect.position + Vector2(rect.size.x - pill_w - 4.0, 7), Vector2(pill_w, 20)), _shorten_to_width(state.phase_name(), pill_w - 8.0, 10), Color("#071126", 0.70), phase_color)


func _draw_character_section(rect: Rect2) -> void:
	_draw_panel(rect, Color("#07182c", 0.46), Color("#9ff0ff", 0.20))
	draw_string(get_theme_default_font(), rect.position + Vector2(12, 16), "单位", HORIZONTAL_ALIGNMENT_LEFT, 64, 12, Color("#fff4ba"))
	character_prev_rect = Rect2(rect.position + Vector2(rect.size.x - 70, 6), Vector2(20, 20))
	character_next_rect = Rect2(rect.position + Vector2(rect.size.x - 24, 6), Vector2(20, 20))
	_draw_small_button(character_prev_rect, "<")
	_draw_small_button(character_next_rect, ">")
	draw_string(get_theme_default_font(), rect.position + Vector2(rect.size.x - 56, 18), state.character_panel_count_label(), HORIZONTAL_ALIGNMENT_CENTER, 28, 9, Color("#8ea4bf"))
	draw_line(rect.position + Vector2(12, 30), rect.position + Vector2(rect.size.x - 12, 30), Color("#9ff0ff", 0.12), 1.0)

	var unit := state.inspected_player_unit()
	if unit.is_empty():
		_draw_character_member_fallback(rect)
		return

	var portrait_size := clampf(rect.size.y * 0.34, 48.0, 62.0)
	var token_rect := Rect2(rect.position + Vector2(14, 42), Vector2(portrait_size, portrait_size))
	var token: Texture2D = assets.token_textures.get(unit.get("id", "hero"))
	draw_rect(Rect2(token_rect.position + Vector2(0, 3), token_rect.size), Color("#030814", 0.32))
	draw_rect(token_rect, Color("#061326", 0.86))
	draw_rect(token_rect.grow(-4), Color("#12314d", 0.54))
	draw_rect(token_rect, Color("#9ff0ff", 0.52), false, 1.6)
	draw_rect(token_rect.grow(-5), Color("#f6d26b", 0.16), false, 1.0)
	if token != null:
		draw_texture_rect(token, token_rect.grow(-8), false)
	if bool(unit.get("acted", false)):
		draw_rect(token_rect.grow(-3), Color("#071126", 0.42))
		draw_string(get_theme_default_font(), token_rect.position + Vector2(0, 46), "待机", HORIZONTAL_ALIGNMENT_CENTER, token_rect.size.x, 12, Color("#dce6ff"))

	var info_x := token_rect.end.x + 10.0
	var info_w := rect.end.x - info_x - 14.0
	draw_string(get_theme_default_font(), Vector2(info_x, rect.position.y + 54), _shorten_to_width(unit.get("name", ""), info_w, 15), HORIZONTAL_ALIGNMENT_LEFT, info_w, 15, Color("#fff4ba"))
	draw_string(get_theme_default_font(), Vector2(info_x, rect.position.y + 70), _shorten_to_width("%s Lv%d" % [unit.get("class_name", ""), int(unit.get("level", 1))], info_w, 10), HORIZONTAL_ALIGNMENT_LEFT, info_w, 10, Color("#8ea4bf"))
	var hp_ratio: float = float(unit["hp"]) / float(maxi(1, int(unit["max_hp"])))
	_draw_bar(Rect2(Vector2(info_x, rect.position.y + 80), Vector2(info_w, 13)), hp_ratio, MINT, "%d/%d" % [unit["hp"], unit["max_hp"]])
	var stat_y := rect.end.y - 26.0
	var stat_w := (rect.size.x - 32.0) / 3.0
	_draw_stat_box(Rect2(Vector2(rect.position.x + 12, stat_y), Vector2(stat_w, 18)), "力", str(int(unit["atk"]) + state.player_power), ROSE)
	_draw_stat_box(Rect2(Vector2(rect.position.x + 16 + stat_w, stat_y), Vector2(stat_w, 18)), "移", str(unit.get("move_range", 0)), CYAN)
	_draw_stat_box(Rect2(Vector2(rect.position.x + 20 + stat_w * 2.0, stat_y), Vector2(stat_w, 18)), "挡", str(unit.get("block", 0)), MINT)


func _draw_character_member_fallback(rect: Rect2) -> void:
	var member := state.inspected_party_member()
	if member.is_empty():
		draw_string(get_theme_default_font(), rect.position + Vector2(14, 74), "暂无角色", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28, 13, Color("#b7caef"))
		return
	var text_w := rect.size.x - 28.0
	draw_string(get_theme_default_font(), rect.position + Vector2(14, 54), _shorten_to_width(member.get("name", ""), text_w, 15), HORIZONTAL_ALIGNMENT_LEFT, text_w, 15, Color.WHITE)
	draw_string(get_theme_default_font(), rect.position + Vector2(14, 72), _shorten_to_width(state.class_name_for_member(member), text_w, 11), HORIZONTAL_ALIGNMENT_LEFT, text_w, 11, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(14, 90), "Lv%d  EXP %d" % [int(member.get("level", 1)), int(member.get("xp", 0))], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28, 10, Color("#dce6ff"))


func _draw_stat_text(pos: Vector2, width: float, label: String, value: String, color: Color) -> void:
	draw_string(get_theme_default_font(), pos, label, HORIZONTAL_ALIGNMENT_LEFT, width * 0.46, 12, Color("#b7caef"))
	draw_string(get_theme_default_font(), pos, value, HORIZONTAL_ALIGNMENT_RIGHT, width - 4.0, 12, color)


func _draw_stat_box(rect: Rect2, label: String, value: String, color: Color) -> void:
	draw_rect(rect, Color("#071126", 0.58))
	draw_rect(rect, Color("#9ff0ff", 0.13), false, 1.0)
	var icon := Rect2(rect.position + Vector2(4, 3), Vector2(15, 15))
	draw_rect(icon, Color(color, 0.20))
	draw_rect(icon, Color("#9ff0ff", 0.22), false, 1.0)
	draw_string(get_theme_default_font(), icon.position + Vector2(0, 11), label, HORIZONTAL_ALIGNMENT_CENTER, icon.size.x, 9, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(0, 15), value, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 7, 12, color)


func _draw_mission_section(rect: Rect2) -> void:
	_draw_panel(rect, Color("#071126", 0.44), Color("#f6d26b", 0.12))
	draw_string(get_theme_default_font(), rect.position + Vector2(12, 16), "目标", HORIZONTAL_ALIGNMENT_LEFT, 42, 11, Color("#b7caef"))
	draw_string(get_theme_default_font(), rect.position + Vector2(48, 16), _shorten_to_width(state.objective_summary(), rect.size.x - 58.0, 11), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 58.0, 11, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(12, 32), _shorten_to_width(state.failure_summary(), rect.size.x - 24.0, 9), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24.0, 9, Color("#ffcfda"))
	var chip_w := (rect.size.x - 28.0) / 2.0
	var chip_y := rect.position.y + 35.0
	_draw_metric(Rect2(Vector2(rect.position.x + 10, chip_y), Vector2(chip_w, 16)), "击破", int(state.battle_stats.get("enemies_defeated", 0)), GOLD)
	_draw_metric(Rect2(Vector2(rect.position.x + 18 + chip_w, chip_y), Vector2(chip_w, 16)), "受伤", int(state.battle_stats.get("damage_taken", 0)), ROSE)


func _draw_log_section(rect: Rect2) -> void:
	_draw_panel(rect, Color("#051024", 0.40), Color("#78d7ff", 0.10))
	var title := "战况" if state.log_expanded else "提示"
	draw_string(get_theme_default_font(), rect.position + Vector2(12, 16), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 96, 11, Color("#b7caef"))
	log_toggle_rect = Rect2(Vector2(rect.end.x - 58, rect.position.y + 7), Vector2(42, 22))
	_draw_small_button(log_toggle_rect, "收起" if state.log_expanded else "展开")

	var focus_line := _focus_summary()
	if state.log_expanded:
		var logs: Array = state.battle_log.slice(maxi(0, state.battle_log.size() - 5), state.battle_log.size())
		var base_y := rect.position.y + 31.0
		var max_lines := mini(logs.size(), maxi(1, int((rect.size.y - 52.0) / 15.0)))
		var first_line := maxi(0, logs.size() - max_lines)
		for i in range(max_lines):
			var line := String(logs[first_line + i])
			draw_string(get_theme_default_font(), Vector2(rect.position.x + 14, base_y + float(i * 15)), _shorten_to_width(line, rect.size.x - 28.0, 11), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28, 11, Color("#dce6ff"))
		if focus_line != "":
			draw_line(Vector2(rect.position.x + 12, rect.end.y - 29), Vector2(rect.end.x - 12, rect.end.y - 29), Color("#78d7ff", 0.13), 1.0)
			draw_string(get_theme_default_font(), Vector2(rect.position.x + 14, rect.end.y - 10), _shorten_to_width(focus_line, rect.size.x - 28.0, 11), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28, 11, Color("#fff4ba"))
	else:
		var main_text := focus_line if focus_line != "" else state.message
		draw_string(get_theme_default_font(), rect.position + Vector2(14, 34), _shorten_to_width(main_text, rect.size.x - 28.0, 11), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28, 11, Color("#e6f2ff"))


func _draw_footer(panel: Rect2, footer_y: float) -> void:
	var gap := 8.0
	var usable_w := panel.size.x - 48.0
	var restart_w := 76.0
	var undo_w := 78.0
	var end_w := maxf(116.0, usable_w - restart_w - undo_w - gap * 2.0)
	end_turn_rect = Rect2(Vector2(panel.position.x + 24, footer_y), Vector2(end_w, 34))
	var can_end := state.phase == "player" and not state.victory and not state.defeat
	var button_color := GOLD if can_end else Color("#59617e")
	var label := "待机" if state.selected_unit_uid != "" else "结束回合"
	_draw_button(end_turn_rect, label, button_color)

	undo_move_rect = Rect2(Vector2(end_turn_rect.end.x + gap, footer_y), Vector2(undo_w, 34))
	var can_undo := state.can_undo_selected_move()
	_draw_button(undo_move_rect, "撤回", CYAN if can_undo else Color("#4f5a72"), Color("#101832") if can_undo else Color("#b7caef"))

	restart_rect = Rect2(Vector2(undo_move_rect.end.x + gap, footer_y), Vector2(restart_w, 34))
	_draw_button(restart_rect, "重开", CYAN)


func _focus_summary() -> String:
	if state.selected_card >= 0:
		return "技能｜%s" % state.selected_card_sidebar_summary()
	return ""


func _draw_panel(rect: Rect2, fill: Color = Color("#111a33", 0.86), border: Color = Color("#9fd7ff", 0.25)) -> void:
	draw_rect(Rect2(rect.position + Vector2(0, 3), rect.size), Color("#030814", 0.28))
	draw_rect(rect, Color("#0a1a2f", 0.50))
	draw_rect(rect.grow(-3), fill)
	_draw_brush_wash(rect.grow(-5), 0.58)
	draw_rect(rect, border, false, 1.2)
	draw_rect(rect.grow(-5), Color("#e5fbff", 0.10), false, 1.0)


func _draw_button(rect: Rect2, label: String, fill: Color, text_color: Color = Color("#101832")) -> void:
	draw_rect(Rect2(rect.position + Vector2(0, 3), rect.size), Color("#030814", 0.26))
	draw_rect(rect, Color("#071126", 0.82))
	draw_rect(rect.grow(-2), Color(fill, 0.78))
	draw_rect(rect, Color("#9ff0ff", 0.30), false, 1.4)
	draw_rect(rect.grow(-4), Color("#fff4ba", 0.18), false, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(0, 24), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 16, text_color)


func _draw_brush_wash(rect: Rect2, alpha: float) -> void:
	draw_rect(rect, Color("#9ff0ff", 0.026 * alpha))
	draw_line(rect.position + Vector2(12, rect.size.y * 0.23), rect.position + Vector2(rect.size.x - 14, rect.size.y * 0.17), Color("#e5fbff", 0.060 * alpha), 2.0)
	draw_line(rect.position + Vector2(10, rect.size.y * 0.66), rect.position + Vector2(rect.size.x - 18, rect.size.y * 0.58), Color("#5bbde6", 0.070 * alpha), 2.0)


func _draw_small_button(rect: Rect2, label: String) -> void:
	draw_rect(rect, Color("#071126", 0.78))
	draw_rect(rect, Color("#9ff0ff", 0.32), false, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(0, 15), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, Color("#fff4ba"))


func _draw_pill(rect: Rect2, label: String, fill: Color, accent: Color) -> void:
	draw_rect(rect, Color(fill, 0.68))
	draw_rect(rect, Color("#9ff0ff", 0.22), false, 1.0)
	draw_rect(Rect2(rect.position + Vector2(4, rect.size.y - 4), Vector2(rect.size.x - 8, 1)), accent * Color(1, 1, 1, 0.42))
	draw_string(get_theme_default_font(), rect.position + Vector2(0, 18), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 12, accent)


func _draw_metric(rect: Rect2, label: String, value: int, color: Color) -> void:
	draw_rect(rect, Color("#071126", 0.52))
	draw_rect(rect, Color("#9ff0ff", 0.12), false, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(7, 16), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x * 0.55, 11, Color("#b7caef"))
	draw_string(get_theme_default_font(), rect.position + Vector2(0, 16), str(value), HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 8, 11, color)


func _draw_terrain_chip(rect: Rect2, label: String, value: String, color: Color) -> void:
	draw_rect(rect, Color("#071126", 0.48))
	draw_rect(rect, Color("#9ff0ff", 0.11), false, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(6, 12), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x * 0.42, 9, Color("#b7caef"))
	draw_string(get_theme_default_font(), rect.position + Vector2(rect.size.x * 0.38, 12), value, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x * 0.56, 9, color)


func _shorten(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, maxi(0, max_chars - 1)) + "…"


func _shorten_to_width(text: String, width: float, font_size: int) -> String:
	var max_chars := maxi(4, int(width / maxf(6.0, float(font_size) * 0.72)))
	return _shorten(text, max_chars)


func _draw_bar(rect: Rect2, ratio: float, fill: Color, label: String) -> void:
	var clamped_ratio: float = clampf(ratio, 0.0, 1.0)
	draw_rect(rect, Color("#030814", 0.88))
	draw_rect(rect.grow(-1), Color("#10233f", 0.78))
	draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2((rect.size.x - 4) * clamped_ratio, rect.size.y - 4)), fill)
	draw_rect(rect, Color("#9ff0ff", 0.34), false, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(0, rect.size.y - 4), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 13, Color.WHITE)


func _draw_exp_bar(rect: Rect2, ratio: float, label: String) -> void:
	var clamped_ratio: float = clampf(ratio, 0.0, 1.0)
	draw_rect(rect, Color("#030814", 0.86))
	draw_rect(Rect2(rect.position + Vector2(1, 1), Vector2((rect.size.x - 2) * clamped_ratio, rect.size.y - 2)), Color("#79d8ff", 0.82))
	draw_rect(rect, Color("#9ff0ff", 0.24), false, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(0, 2), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 8, Color("#f4f7ff"))


func _draw_mini_bar(rect: Rect2, ratio: float, fill: Color) -> void:
	var clamped_ratio: float = clampf(ratio, 0.0, 1.0)
	draw_rect(rect, Color("#071126", 0.86))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clamped_ratio, rect.size.y)), fill)


func _draw_buff_chip(rect: Rect2, label: String, accent: Color) -> void:
	draw_rect(rect, Color("#071126", 0.68))
	draw_rect(rect, Color(accent, 0.28), false, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(0, 12), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 9, Color("#fff4ba"))


func _draw_frame_corners(rect: Rect2, color: Color, length: float, width: float) -> void:
	draw_line(rect.position + Vector2(6, 6), rect.position + Vector2(6 + length, 6), color, width)
	draw_line(rect.position + Vector2(6, 6), rect.position + Vector2(6, 6 + length), color, width)
	draw_line(rect.position + Vector2(rect.size.x - 6, 6), rect.position + Vector2(rect.size.x - 6 - length, 6), color, width)
	draw_line(rect.position + Vector2(rect.size.x - 6, 6), rect.position + Vector2(rect.size.x - 6, 6 + length), color, width)
	draw_line(rect.position + Vector2(6, rect.size.y - 6), rect.position + Vector2(6 + length, rect.size.y - 6), color, width)
	draw_line(rect.position + Vector2(6, rect.size.y - 6), rect.position + Vector2(6, rect.size.y - 6 - length), color, width)
	draw_line(rect.end - Vector2(6, 6), rect.end - Vector2(6 + length, 6), color, width)
	draw_line(rect.end - Vector2(6, 6), rect.end - Vector2(6, 6 + length), color, width)
