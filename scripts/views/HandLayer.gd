class_name HandLayer
extends Control

const BattleLayoutScript := preload("res://scripts/core/BattleLayout.gd")
const PANEL_FILL := Color("#07182c", 0.64)
const PANEL_INNER := Color("#16314a", 0.42)
const GOLD := Color("#f6d26b")
const BLUE_LINE := Color("#9ff0ff", 0.28)

var state: BattleState
var assets: BattleAssets
var layout = BattleLayoutScript.new()
var hand_rects: Array = []
var hand_skill_indices: Array[int] = []
var prev_page_rect: Rect2 = Rect2()
var next_page_rect: Rect2 = Rect2()
var visible_skill_count := 1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if state == null or assets == null:
		return
	if state.chapter_phase != "battle":
		hand_rects.clear()
		hand_skill_indices.clear()
		prev_page_rect = Rect2()
		next_page_rect = Rect2()
		return
	var viewport_size := get_viewport_rect().size
	hand_rects.clear()
	hand_skill_indices.clear()
	prev_page_rect = Rect2()
	next_page_rect = Rect2()
	var dock_rect: Rect2 = layout.hand_dock_rect if layout != null else Rect2(18.0, viewport_size.y - 150.0 - 8.0, viewport_size.x - 36.0, 150.0)
	_draw_panel(dock_rect, Color("#071726", 0.86), Color("#9ff0ff", 0.16))

	var unit := state.selected_unit()
	if unit.is_empty():
		_draw_empty_prompt(dock_rect)
		return

	var skills := state.available_skills_for_selected()
	var can_choose := state.phase == "player" and state.action_mode == "command" and not bool(unit.get("acted", false))
	var title := "%s · 技能" % unit.get("name", "")
	var note := _skill_menu_note(unit, can_choose)
	draw_string(get_theme_default_font(), dock_rect.position + Vector2(22, 24), _shorten_to_width(title, dock_rect.size.x * 0.36, 16), HORIZONTAL_ALIGNMENT_LEFT, dock_rect.size.x * 0.36, 16, Color("#fff4ba"))
	draw_string(get_theme_default_font(), dock_rect.position + Vector2(22, 42), _shorten_to_width(note, dock_rect.size.x - 220.0, 10), HORIZONTAL_ALIGNMENT_LEFT, dock_rect.size.x - 220.0, 10, Color("#c7d6ea"))
	_draw_status_seal(Rect2(dock_rect.end - Vector2(122, dock_rect.size.y - 12), Vector2(96, 22)), unit, can_choose)
	if skills.is_empty():
		draw_string(get_theme_default_font(), dock_rect.position + Vector2(24, 78), "该角色暂未配置技能。", HORIZONTAL_ALIGNMENT_LEFT, dock_rect.size.x - 48, 13, Color("#b7caef"))
		return

	var card_gap := clampf(dock_rect.size.x * 0.01, 8.0, 12.0)
	var cards_area := Rect2(dock_rect.position + Vector2(22, 54), Vector2(dock_rect.size.x - 44, dock_rect.size.y - 68))
	visible_skill_count = clampi(floori((cards_area.size.x + card_gap) / 250.0), 1, 4)
	var page_count := state.skill_page_count(visible_skill_count)
	var start_index := state.skill_page_start(visible_skill_count)
	if page_count > 1:
		var arrow_w := 34.0
		prev_page_rect = Rect2(dock_rect.position + Vector2(22, 62), Vector2(arrow_w, dock_rect.size.y - 84))
		next_page_rect = Rect2(Vector2(dock_rect.end.x - 22 - arrow_w, dock_rect.position.y + 62), prev_page_rect.size)
		cards_area = Rect2(Vector2(prev_page_rect.end.x + 10, dock_rect.position.y + 54), Vector2(next_page_rect.position.x - prev_page_rect.end.x - 20, dock_rect.size.y - 68))
		visible_skill_count = clampi(floori((cards_area.size.x + card_gap) / 250.0), 1, 4)
		page_count = state.skill_page_count(visible_skill_count)
		start_index = state.skill_page_start(visible_skill_count)
		_draw_page_button(prev_page_rect, "<")
		_draw_page_button(next_page_rect, ">")
	else:
		prev_page_rect = Rect2()
		next_page_rect = Rect2()
	var show_count := mini(visible_skill_count, skills.size() - start_index)
	var available_button_w := (cards_area.size.x - card_gap * float(maxi(0, show_count - 1))) / float(maxi(1, show_count))
	var button_w := minf(clampf(available_button_w, 210.0, 300.0), available_button_w)
	var start_x := cards_area.position.x
	for visible_index in range(show_count):
		var skill_index := start_index + visible_index
		var rect := Rect2(Vector2(start_x + float(visible_index) * (button_w + card_gap), cards_area.position.y), Vector2(button_w, cards_area.size.y))
		hand_rects.append(rect)
		hand_skill_indices.append(skill_index)
		_draw_skill_button(rect, skills[skill_index], skill_index, can_choose and state.can_unit_execute_card(unit, skills[skill_index]))
	draw_string(get_theme_default_font(), dock_rect.position + Vector2(0, dock_rect.size.y - 10), "%d/%d" % [state.skill_page_index + 1, page_count], HORIZONTAL_ALIGNMENT_CENTER, dock_rect.size.x, 10, Color("#8ea4bf"))


func _draw_empty_prompt(rect: Rect2) -> void:
	draw_string(get_theme_default_font(), rect.position + Vector2(22, 24), "技能", HORIZONTAL_ALIGNMENT_LEFT, 120, 16, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(74, 24), "选择单位后显示当前技能。", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 96, 11, Color("#b7caef"))
	var prompt_rect := Rect2(rect.position + Vector2(22, 52), Vector2(minf(420.0, rect.size.x - 44.0), 48))
	_draw_skill_strip_frame(prompt_rect, Color("#9ff0ff", 0.18), 0.58)
	draw_string(get_theme_default_font(), prompt_rect.position + Vector2(18, 29), "选择未行动单位", HORIZONTAL_ALIGNMENT_LEFT, prompt_rect.size.x - 36, 14, Color("#fff4ba"))


func _skill_menu_note(unit: Dictionary, can_choose: bool) -> String:
	if bool(unit.get("acted", false)):
		return "该单位已行动"
	if state.action_mode == "move":
		return "点击自身格进入指令，或先移动到目标位置"
	if can_choose:
		return "选择技能，或点击敌人普通攻击"
	return "当前不能使用技能"


func _draw_skill_button(rect: Rect2, skill: Dictionary, index: int, playable: bool) -> void:
	var hovered := index == state.hover_card
	var selected := index == state.selected_card
	var accent := _skill_accent(skill.get("kind", ""))
	var ink := Color("#f4f7ff") if playable else Color("#9aa5b8")
	if hovered and playable:
		rect.position.y -= 2.0
	if selected:
		draw_rect(rect.grow(3), Color(accent, 0.16))
	_draw_skill_strip_frame(rect, accent, 0.86 if playable else 0.48)

	var icon_size := minf(44.0, rect.size.y - 14.0)
	var icon_rect := Rect2(rect.position + Vector2(10, (rect.size.y - icon_size) * 0.5), Vector2(icon_size, icon_size))
	var art_texture: Texture2D = assets.card_textures.get(skill.get("kind", ""))
	draw_rect(icon_rect, Color("#030814", 0.82))
	if art_texture != null:
		draw_texture_rect(art_texture, icon_rect, false)
	draw_rect(icon_rect, Color("#9ff0ff", 0.22), false, 1.0)

	var cost_rect := Rect2(rect.end - Vector2(34.0, rect.size.y - 8.0), Vector2(24.0, 18.0))
	draw_rect(cost_rect, Color("#061326", 0.92))
	draw_rect(cost_rect, Color(accent, 0.24), false, 1.0)
	draw_string(get_theme_default_font(), Vector2(cost_rect.position.x, cost_rect.position.y + 13), str(skill.get("cost", 0)), HORIZONTAL_ALIGNMENT_CENTER, cost_rect.size.x, 11, Color("#fff4ba") if playable else Color("#aab3c1"))

	var text_x := icon_rect.end.x + 10.0
	var text_w := cost_rect.position.x - text_x - 10.0
	draw_string(get_theme_default_font(), Vector2(text_x, rect.position.y + 18), _shorten_to_width(skill.get("title", ""), text_w, 14), HORIZONTAL_ALIGNMENT_LEFT, text_w, 14, ink)
	draw_string(get_theme_default_font(), Vector2(text_x, rect.position.y + 33), _shorten_to_width(skill.get("text", ""), text_w, 10), HORIZONTAL_ALIGNMENT_LEFT, text_w, 10, Color("#dce6ff") if playable else Color("#8f99ad"))
	draw_string(get_theme_default_font(), Vector2(text_x, rect.end.y - 8), _shorten_to_width(skill.get("school", _skill_role(skill.get("kind", ""))), text_w, 9), HORIZONTAL_ALIGNMENT_LEFT, text_w, 9, accent if playable else Color("#aab3c1"))
	if not playable:
		draw_rect(rect, Color("#071126", 0.32))


func _draw_skill_strip_frame(rect: Rect2, accent: Color, alpha: float) -> void:
	var texture: Texture2D = null
	if assets != null:
		texture = assets.ui_textures.get("oil_skill_strip", assets.ui_textures.get("skill_card_frame", assets.ui_textures.get("glass_skill_strip", null))) as Texture2D
	if texture != null:
		draw_texture_rect(texture, rect.grow(1.0), false, Color(1.0, 1.0, 1.0, alpha * 0.72))
	else:
		draw_rect(Rect2(rect.position + Vector2(0, 2), rect.size), Color("#030814", 0.22 * alpha))
		draw_rect(rect, Color("#071126", 0.92 * alpha))
		draw_rect(rect, Color("#9ff0ff", 0.14 * alpha), false, 1.0)
	draw_rect(Rect2(rect.position + Vector2(0, 0), Vector2(4, rect.size.y)), Color(accent, 0.68 * alpha))
	draw_rect(rect.grow(-2), Color("#e5fbff", 0.04 * alpha), false, 1.0)


func _draw_page_button(rect: Rect2, label: String) -> void:
	var texture: Texture2D = assets.ui_textures.get("small_button", null) if assets != null else null
	if texture != null:
		draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, 0.56))
	else:
		draw_rect(rect, Color("#071126", 0.86))
		draw_rect(rect, Color("#9ff0ff", 0.18), false, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(0, rect.size.y * 0.58), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 18, Color("#fff4ba"))


func skill_index_for_rect(rect_index: int) -> int:
	if rect_index >= 0 and rect_index < hand_skill_indices.size():
		return hand_skill_indices[rect_index]
	return rect_index


func _draw_panel(rect: Rect2, fill: Color, border: Color) -> void:
	var texture: Texture2D = null
	if assets != null:
		texture = assets.ui_textures.get("oil_hand_dock", assets.ui_textures.get("glass_hand_dock", assets.ui_textures.get("hand_dock", null))) as Texture2D
	if texture != null:
		draw_texture_rect(texture, rect.grow(2.0), false, Color(1.0, 1.0, 1.0, 0.46))
	else:
		draw_rect(Rect2(rect.position + Vector2(0, 3), rect.size), Color("#030814", 0.28))
		draw_rect(rect, Color("#061326", 0.72))
	draw_rect(rect.grow(-4), fill)
	draw_rect(rect, Color("#9ff0ff", 0.18), false, 1.2)
	draw_rect(rect.grow(-3), border, false, 1.0)


func _draw_brush_wash(rect: Rect2, alpha: float) -> void:
	draw_rect(rect, Color("#9ff0ff", 0.022 * alpha))
	draw_line(rect.position + Vector2(18, rect.size.y * 0.28), rect.position + Vector2(rect.size.x - 24, rect.size.y * 0.18), Color("#e5fbff", 0.058 * alpha), 2.0)
	draw_line(rect.position + Vector2(20, rect.size.y * 0.76), rect.position + Vector2(rect.size.x - 22, rect.size.y * 0.62), Color("#5bbde6", 0.070 * alpha), 2.0)


func _draw_status_seal(rect: Rect2, unit: Dictionary, can_choose: bool) -> void:
	var label := "可行动" if can_choose else "移动中"
	var accent := Color("#65e08c") if can_choose else Color("#f6d26b")
	if bool(unit.get("acted", false)):
		label = "已待机"
		accent = Color("#9fb0c8")
	draw_rect(rect, Color("#071126", 0.82))
	draw_rect(rect, Color("#9ff0ff", 0.12), false, 1.0)
	draw_rect(Rect2(rect.position + Vector2(6, 7), Vector2(6, 6)), accent)
	draw_string(get_theme_default_font(), rect.position + Vector2(16, 15), label, HORIZONTAL_ALIGNMENT_LEFT, 34, 9, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(52, 15), _shorten_to_width("Lv%d" % int(unit.get("level", 1)), rect.size.x - 56.0, 9), HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 56, 9, Color("#dce6ff"))


func _draw_frame_corners(rect: Rect2, color: Color, length: float, width: float) -> void:
	draw_line(rect.position + Vector2(5, 5), rect.position + Vector2(5 + length, 5), color, width)
	draw_line(rect.position + Vector2(5, 5), rect.position + Vector2(5, 5 + length), color, width)
	draw_line(rect.position + Vector2(rect.size.x - 5, 5), rect.position + Vector2(rect.size.x - 5 - length, 5), color, width)
	draw_line(rect.position + Vector2(rect.size.x - 5, 5), rect.position + Vector2(rect.size.x - 5, 5 + length), color, width)
	draw_line(rect.position + Vector2(5, rect.size.y - 5), rect.position + Vector2(5 + length, rect.size.y - 5), color, width)
	draw_line(rect.position + Vector2(5, rect.size.y - 5), rect.position + Vector2(5, rect.size.y - 5 - length), color, width)
	draw_line(rect.end - Vector2(5, 5), rect.end - Vector2(5 + length, 5), color, width)
	draw_line(rect.end - Vector2(5, 5), rect.end - Vector2(5, 5 + length), color, width)


func _skill_accent(kind: String) -> Color:
	match kind:
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


func _skill_role(kind: String) -> String:
	match kind:
		BattleAssets.CARD_STRIKE, BattleAssets.CARD_LANCE:
			return "攻击"
		BattleAssets.CARD_DASH:
			return "机动"
		BattleAssets.CARD_GUARD:
			return "守护"
		BattleAssets.CARD_ENGAGE:
			return "纹章"
		BattleAssets.CARD_HEAL:
			return "恢复"
	return "战术"


func _shorten(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, maxi(0, max_chars - 1)) + "…"


func _shorten_to_width(text: String, width: float, font_size: int) -> String:
	var max_chars := maxi(4, int(width / maxf(6.0, float(font_size) * 0.72)))
	return _shorten(text, max_chars)
