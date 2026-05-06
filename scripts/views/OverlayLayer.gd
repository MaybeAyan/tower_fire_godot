class_name OverlayLayer
extends Control

const BattleLayoutScript := preload("res://scripts/core/BattleLayout.gd")

var state: BattleState
var assets: BattleAssets
var layout = BattleLayoutScript.new()
var reward_rects: Array[Rect2] = []
var promotion_rects: Array[Rect2] = []
var map_node_rects: Array[Rect2] = []
var camp_party_rects: Array[Rect2] = []
var camp_skill_rects: Array[Rect2] = []
var camp_event_rects: Array[Rect2] = []
var camp_close_rect: Rect2 = Rect2()
var camp_rest_rect: Rect2 = Rect2()
var camp_deploy_rect: Rect2 = Rect2()
var next_battle_rect: Rect2 = Rect2()
var deck_toggle_rect: Rect2 = Rect2()
var show_battle_prompt_cards := true
var show_flow_panels := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if state == null:
		return
	reward_rects.clear()
	promotion_rects.clear()
	map_node_rects.clear()
	camp_party_rects.clear()
	camp_skill_rects.clear()
	camp_event_rects.clear()
	camp_close_rect = Rect2()
	camp_rest_rect = Rect2()
	camp_deploy_rect = Rect2()
	next_battle_rect = Rect2()
	deck_toggle_rect = Rect2()
	var viewport_size := get_viewport_rect().size
	if state.chapter_phase == "intro":
		if not show_flow_panels:
			return
		_draw_intro_panel(viewport_size)
		return
	if state.chapter_phase == "chapter_map":
		if not show_flow_panels:
			return
		_draw_chapter_map(viewport_size)
		return
	if _uses_legacy_battle_prompts():
		_draw_banners(viewport_size)
		_draw_objective_cards(viewport_size)
		_draw_tutorial_feedback_cards(viewport_size)
		_draw_tutorial_panel(viewport_size)
	if state.chapter_phase == "promotion":
		if not show_flow_panels:
			return
		_draw_promotion_panel(viewport_size)
		return
	if state.chapter_phase == "complete":
		if not show_flow_panels:
			return
		_draw_chapter_complete_panel(viewport_size)
		return
	if not state.victory and not state.defeat:
		return
	if state.victory and not state.reward_claimed and state.reward_options.size() > 0:
		if not show_flow_panels:
			return
		_draw_reward_panel(viewport_size)
		return
	if not show_flow_panels:
		return
	_draw_result_panel(viewport_size)
	if state.victory and state.reward_claimed and state.deck_view_open:
		_draw_skill_panel(viewport_size)


func _uses_legacy_battle_prompts() -> bool:
	return show_battle_prompt_cards and state.chapter_phase != "battle"


func _draw_result_panel(viewport_size: Vector2) -> void:
	var rect := Rect2(Vector2(viewport_size.x * 0.5 - 290, viewport_size.y * 0.5 - 152), Vector2(580, 304))
	draw_rect(rect, Color("#061026", 0.9))
	if assets != null:
		var frame: Texture2D = assets.ui_textures.get("status_panel")
		if frame != null:
			draw_texture_rect(frame, rect, false)
	draw_rect(rect.grow(-18), Color("#101832", 0.88))
	draw_rect(rect.grow(-10), Color("#f6d26b", 0.56), false, 2.0)
	var title := "胜利" if state.victory else "战败"
	var grade := state.battle_grade()
	draw_string(get_theme_default_font(), rect.position + Vector2(30, 56), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 60, 32, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(36, 88), "战斗评价  %s" % grade, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 72, 22, Color("#79d8ff") if grade == "S" else Color("#dce6ff"))
	draw_string(get_theme_default_font(), rect.position + Vector2(38, 122), state.battle_result_summary(), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 76, 14, Color.WHITE)
	draw_string(get_theme_default_font(), rect.position + Vector2(42, 154), state.battle_result_note(), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 84, 14, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(42, 176), state.battle_exp_summary(), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 84, 12, Color("#79d8ff"))
	var footer := "重开可尝试更漂亮的走位与更少损伤。"
	if state.victory and state.reward_claimed:
		draw_rect(Rect2(rect.position + Vector2(54, 198), Vector2(rect.size.x - 108, 50)), Color("#071126", 0.52))
		draw_rect(Rect2(rect.position + Vector2(54, 198), Vector2(rect.size.x - 108, 50)), Color("#c19a4a", 0.22), false, 1.2)
		draw_string(get_theme_default_font(), rect.position + Vector2(70, 218), state.reward_confirmation_title(), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 140, 13, Color("#fff4ba"))
		draw_string(get_theme_default_font(), rect.position + Vector2(70, 234), state.reward_confirmation_note(), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 140, 11, Color("#b7caef"))
		var next_label := "选择转职" if state.battle_in_chapter >= state.chapter_encounter_count() else "继续下一战"
		next_battle_rect = Rect2(rect.position + Vector2(rect.size.x * 0.5 - 142, 262), Vector2(132, 30))
		deck_toggle_rect = Rect2(rect.position + Vector2(rect.size.x * 0.5 + 10, 262), Vector2(132, 30))
		_draw_result_button(next_battle_rect, next_label, Color("#f6d26b"), Color("#101832"))
		_draw_result_button(deck_toggle_rect, "收起技能" if state.deck_view_open else "查看技能", Color("#6ad7ff"), Color("#101832"))
	else:
		draw_string(get_theme_default_font(), rect.position + Vector2(42, 220), footer, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 84, 13, Color("#b7caef"))


func _draw_chapter_map(viewport_size: Vector2) -> void:
	_draw_intro_background(viewport_size)
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#030814", 0.44))
	var panel := Rect2(Vector2(viewport_size.x * 0.5 - 420, viewport_size.y * 0.5 - 235), Vector2(840, 470))
	draw_rect(panel, Color("#061026", 0.90))
	draw_rect(panel.grow(-10), Color("#f6d26b", 0.34), false, 2.0)
	draw_rect(panel.grow(-24), Color("#101832", 0.50))
	draw_string(get_theme_default_font(), panel.position + Vector2(0, 54), "章节地图", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 30, Color("#fff4ba"))
	draw_string(get_theme_default_font(), panel.position + Vector2(0, 82), "两段式战线：前哨压制，随后直取关键目标", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 14, Color("#dce6ff"))
	var nodes := state.chapter_map_nodes()
	var node_size := Vector2(170, 92)
	var gap := 44.0
	var total_w := node_size.x * float(nodes.size()) + gap * float(maxi(nodes.size() - 1, 0))
	var start := Vector2(panel.position.x + (panel.size.x - total_w) * 0.5, panel.position.y + 132)
	for i in range(nodes.size()):
		var node: Dictionary = nodes[i]
		var rect := Rect2(start + Vector2(float(i) * (node_size.x + gap), 0), node_size)
		map_node_rects.append(rect)
		if i > 0:
			var left := map_node_rects[i - 1].get_center() + Vector2(node_size.x * 0.5, 0)
			var right := rect.get_center() - Vector2(node_size.x * 0.5, 0)
			draw_line(left, right, Color("#f6d26b", 0.30), 3.0)
		_draw_chapter_map_node(rect, node)
	_draw_chapter_map_party(Rect2(panel.position + Vector2(44, 256), Vector2(panel.size.x - 88, 132)))
	draw_string(get_theme_default_font(), panel.position + Vector2(42, panel.size.y - 58), state.chapter_reward_summary(), HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 84, 11, Color("#b7caef"))
	draw_string(get_theme_default_font(), panel.position + Vector2(42, panel.size.y - 34), state.chapter_camp_pending_summary(), HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 84, 11, Color("#fff4ba"))
	if state.camp_view_open:
		_draw_chapter_camp_detail(viewport_size)


func _draw_chapter_map_node(rect: Rect2, node: Dictionary) -> void:
	var status := String(node.get("status", "locked"))
	var fill := Color("#18213a")
	var accent := Color("#778299")
	if status == "completed":
		fill = Color("#102b2a")
		accent = Color("#8fffd8")
	elif status == "current":
		fill = Color("#2b2535")
		accent = Color("#f6d26b")
	elif bool(node.get("boss", false)):
		accent = Color("#ff6685")
	draw_rect(Rect2(rect.position + Vector2(0, 5), rect.size), Color("#030814", 0.34))
	draw_rect(rect, fill)
	draw_rect(rect.grow(-4), Color("#071126", 0.62))
	draw_rect(rect, Color(accent, 0.58), false, 1.8)
	var status_label := "已完成" if status == "completed" else ("当前目标" if status == "current" else "未解锁")
	var badge := Rect2(rect.position + Vector2(12, 10), Vector2(72, 20))
	draw_rect(badge, Color(accent, 0.20))
	draw_rect(badge, Color(accent, 0.42), false, 1.0)
	draw_string(get_theme_default_font(), badge.position + Vector2(0, 14), status_label, HORIZONTAL_ALIGNMENT_CENTER, badge.size.x, 10, accent)
	draw_string(get_theme_default_font(), rect.position + Vector2(12, 52), "%d. %s" % [int(node.get("index", 0)), String(node.get("name", ""))], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24, 15, Color("#fff4ba") if status != "locked" else Color("#9fb0ca"))
	var detail := "Boss遭遇" if bool(node.get("boss", false)) else "战斗节点"
	draw_string(get_theme_default_font(), rect.position + Vector2(12, 74), detail, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24, 11, Color("#dce6ff") if status != "locked" else Color("#778299"))


func _draw_chapter_map_party(rect: Rect2) -> void:
	draw_rect(rect, Color("#071126", 0.52))
	draw_rect(rect, Color("#79d8ff", 0.18), false, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(16, 24), "营地整理", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32, 16, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(110, 24), "%s｜队伍状态与本章成长预览" % state.deployment_summary(), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 126, 12, Color("#b7caef"))
	var rows := state.chapter_map_party_rows()
	var card_gap := 12.0
	var visible_count := mini(rows.size(), 4)
	var card_w := (rect.size.x - 32.0 - card_gap * float(maxi(visible_count - 1, 0))) / float(maxi(visible_count, 1))
	for i in range(visible_count):
		var row: Dictionary = rows[i]
		var card_rect := Rect2(rect.position + Vector2(16.0 + float(i) * (card_w + card_gap), 42), Vector2(card_w, 76))
		camp_party_rects.append(card_rect)
		_draw_chapter_map_party_card(card_rect, row)


func _draw_chapter_map_party_card(rect: Rect2, row: Dictionary) -> void:
	var character_id := String(row.get("character_id", ""))
	var accent := _portrait_accent(character_id, 0.88)
	draw_rect(Rect2(rect.position + Vector2(0, 3), rect.size), Color("#030814", 0.24))
	draw_rect(rect, Color("#101832", 0.82))
	draw_rect(Rect2(rect.position, Vector2(5, rect.size.y)), accent)
	draw_rect(rect, Color(accent, 0.22), false, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(14, 20), String(row.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28, 13, Color("#fff4ba"))
	var deploy_label := "出战" if bool(row.get("deployed", false)) else "候补"
	var deploy_color := Color("#8fffd8") if bool(row.get("deployed", false)) else Color("#778299")
	draw_string(get_theme_default_font(), rect.position + Vector2(rect.size.x - 54, 20), deploy_label, HORIZONTAL_ALIGNMENT_RIGHT, 40, 10, deploy_color)
	draw_string(get_theme_default_font(), rect.position + Vector2(14, 38), "%s T%d  Lv%d %d/100" % [String(row.get("class", "")), int(row.get("tier", 1)), int(row.get("level", 1)), int(row.get("xp", 0))], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28, 11, Color("#79d8ff"))
	var learned_count := int(row.get("learned_count", 0))
	var learned_titles: Array = row.get("learned_titles", [])
	var learned_label := "本章领悟 %d｜已会 %d" % [learned_count, int(row.get("skill_count", 0))]
	if learned_count > 0:
		learned_label = "新：%s｜已会 %d" % [_join_strings(learned_titles, "、"), int(row.get("skill_count", 0))]
	draw_string(get_theme_default_font(), rect.position + Vector2(14, 56), learned_label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28, 10, Color("#dce6ff"))
	draw_string(get_theme_default_font(), rect.position + Vector2(14, 70), String(row.get("passive", "")), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 70, 9, Color("#b7caef"))
	draw_string(get_theme_default_font(), rect.position + Vector2(rect.size.x - 56, 70), "查看", HORIZONTAL_ALIGNMENT_RIGHT, 42, 9, Color(accent, 0.95))


func _draw_chapter_camp_detail(viewport_size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#030814", 0.28))
	var rect := Rect2(Vector2(viewport_size.x * 0.5 - 380, viewport_size.y * 0.5 - 268), Vector2(760, 536))
	draw_rect(Rect2(rect.position + Vector2(0, 6), rect.size), Color("#030814", 0.36))
	draw_rect(rect, Color("#061026", 0.94))
	draw_rect(rect.grow(-8), Color("#79d8ff", 0.28), false, 1.6)
	var member := state.chapter_camp_selected_member_row()
	var character_id := String(member.get("character_id", ""))
	var accent := _portrait_accent(character_id, 0.90)
	draw_rect(Rect2(rect.position + Vector2(24, 24), Vector2(6, 62)), accent)
	draw_string(get_theme_default_font(), rect.position + Vector2(42, 48), "%s｜%s T%d" % [String(member.get("name", "")), String(member.get("class", "")), int(member.get("tier", 1))], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 108, 22, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(42, 74), String(member.get("passive", "")), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 108, 12, Color("#dce6ff"))
	camp_close_rect = Rect2(rect.position + Vector2(rect.size.x - 82, 26), Vector2(54, 28))
	_draw_result_button(camp_close_rect, "关闭", Color("#18213a"), Color("#dce6ff"))
	camp_deploy_rect = Rect2(rect.position + Vector2(rect.size.x - 282, 66), Vector2(76, 28))
	var deploy_label := "调为候补" if bool(member.get("deployed", false)) else "设为出战"
	_draw_result_button(camp_deploy_rect, deploy_label, Color("#8fffd8") if bool(member.get("deployed", false)) else Color("#26344f"), Color("#101832") if bool(member.get("deployed", false)) else Color("#dce6ff"))
	camp_rest_rect = Rect2(rect.position + Vector2(rect.size.x - 198, 66), Vector2(170, 28))
	var rest_fill := Color("#f6d26b") if state.can_use_chapter_camp_rest() else Color("#26344f")
	var rest_text := Color("#101832") if state.can_use_chapter_camp_rest() else Color("#b7caef")
	_draw_result_button(camp_rest_rect, "休整", rest_fill, rest_text)
	draw_string(get_theme_default_font(), rect.position + Vector2(42, 98), state.chapter_camp_rest_summary(), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 84, 11, Color("#b7caef"))
	_draw_chapter_camp_events(Rect2(rect.position + Vector2(32, 122), Vector2(rect.size.x - 64, 96)))
	draw_string(get_theme_default_font(), rect.position + Vector2(32, 248), "领悟技能", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 64, 16, Color("#79d8ff"))
	var skills := state.chapter_camp_skill_rows()
	var y := rect.position.y + 272.0
	for i in range(mini(skills.size(), 6)):
		var row: Dictionary = skills[i]
		var skill_rect := Rect2(Vector2(rect.position.x + 32, y + float(i) * 34.0), Vector2(rect.size.x - 64, 28))
		camp_skill_rects.append(skill_rect)
		_draw_chapter_camp_skill_row(skill_rect, row)
	if skills.size() > 6:
		draw_string(get_theme_default_font(), rect.position + Vector2(32, rect.end.y - 28), "还有 %d 个技能未显示。" % (skills.size() - 6), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 64, 10, Color("#b7caef"))
	else:
		draw_string(get_theme_default_font(), rect.position + Vector2(32, rect.end.y - 28), "点击技能可设为出战技能；战斗内默认使用每名角色前 4 个技能。", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 64, 10, Color("#b7caef"))


func _draw_chapter_camp_events(rect: Rect2) -> void:
	draw_rect(rect, Color("#071126", 0.46))
	draw_rect(rect, Color("#f6d26b", 0.16), false, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(14, 22), "营地事件", HORIZONTAL_ALIGNMENT_LEFT, 82, 14, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(100, 22), state.chapter_camp_event_summary(), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 114, 11, Color("#b7caef"))
	var options := state.chapter_camp_event_options()
	var card_gap := 10.0
	var card_w := (rect.size.x - 28.0 - card_gap * 2.0) / 3.0
	for i in range(options.size()):
		var option: Dictionary = options[i]
		var option_rect := Rect2(rect.position + Vector2(14.0 + float(i) * (card_w + card_gap), 36), Vector2(card_w, 48))
		camp_event_rects.append(option_rect)
		_draw_chapter_camp_event_card(option_rect, option, state.can_choose_chapter_camp_event(i), String(option.get("id", "")) == state.selected_chapter_camp_event_id())


func _draw_chapter_camp_event_card(rect: Rect2, option: Dictionary, enabled: bool, selected: bool) -> void:
	var accent := Color("#8fffd8") if selected else (Color("#f6d26b") if enabled else Color("#778299"))
	draw_rect(rect, Color("#101832", 0.78))
	draw_rect(Rect2(rect.position, Vector2(4, rect.size.y)), Color(accent, 0.86))
	draw_rect(rect, Color(accent, 0.22), false, 1.0)
	var text_x := 12.0
	var icon_key := String(option.get("icon_key", ""))
	if assets != null and icon_key != "":
		var icon: Texture2D = assets.card_textures.get(icon_key, null) as Texture2D
		if icon != null:
			draw_texture_rect(icon, Rect2(rect.position + Vector2(12, 10), Vector2(26, 26)), false)
			draw_rect(Rect2(rect.position + Vector2(12, 10), Vector2(26, 26)), Color(accent, 0.38), false, 1.0)
			text_x = 46.0
	var title_prefix := "已选｜" if selected else ""
	draw_string(get_theme_default_font(), rect.position + Vector2(text_x, 15), "%s%s｜%s" % [title_prefix, String(option.get("speaker", "")), String(option.get("title", ""))], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - text_x - 12, 10, Color("#fff4ba") if enabled or selected else Color("#b7caef"))
	draw_string(get_theme_default_font(), rect.position + Vector2(text_x, 31), state.chapter_camp_event_impact(option), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - text_x - 12, 9, Color("#dce6ff") if enabled or selected else Color("#778299"))


func _draw_chapter_camp_skill_row(rect: Rect2, row: Dictionary) -> void:
	var accent := _reward_accent(String(row.get("kind", "")))
	draw_rect(rect, Color("#101832", 0.78))
	draw_rect(Rect2(rect.position, Vector2(5, rect.size.y)), accent)
	if bool(row.get("learned", false)):
		draw_rect(rect, Color("#f6d26b", 0.16), false, 1.0)
	else:
		draw_rect(rect, Color("#dce6ff", 0.10), false, 1.0)
	var left_label := "出战" if bool(row.get("equipped", false)) else "候补"
	if bool(row.get("learned", false)):
		left_label = "%s·新" % left_label
	draw_string(get_theme_default_font(), rect.position + Vector2(14, 19), left_label, HORIZONTAL_ALIGNMENT_LEFT, 54, 10, Color("#fff4ba") if bool(row.get("equipped", false)) else Color("#b7caef"))
	draw_string(get_theme_default_font(), rect.position + Vector2(72, 19), "%s  费%d" % [String(row.get("title", "")), int(row.get("cost", 0))], HORIZONTAL_ALIGNMENT_LEFT, 156, 11, Color("#f4f7ff"))
	draw_string(get_theme_default_font(), rect.position + Vector2(230, 19), String(row.get("text", "")), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 308, 10, Color("#b7caef"))
	draw_string(get_theme_default_font(), rect.position + Vector2(rect.size.x - 72, 19), "设为出战", HORIZONTAL_ALIGNMENT_RIGHT, 58, 9, Color(accent, 0.95))


func _draw_intro_panel(viewport_size: Vector2) -> void:
	_draw_intro_background(viewport_size)
	var line: Dictionary = state.current_dialogue_line()
	var portrait_id: String = state.current_dialogue_portrait_id()
	_draw_intro_portrait(viewport_size, portrait_id)
	var dialogue_w := minf(980.0, viewport_size.x - 140.0)
	var dialogue_h := dialogue_w * 0.24
	var dialogue_rect := Rect2(Vector2(viewport_size.x * 0.5 - dialogue_w * 0.5, viewport_size.y - dialogue_h - 18.0), Vector2(dialogue_w, dialogue_h))
	_draw_intro_dialogue(dialogue_rect, line)


func _draw_intro_background(viewport_size: Vector2) -> void:
	var bg_id := state.current_dialogue_background_id()
	var bg_texture := assets.dialogue_background_texture(bg_id) if assets != null else null
	if bg_texture != null:
		draw_texture_rect(bg_texture, Rect2(Vector2.ZERO, viewport_size), false)
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#071126", 0.26))
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#fff4ba", 0.02))
		return
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#071126"))
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#f6d26b", 0.025))
	var center := viewport_size * 0.5
	for i in range(5):
		var radius := viewport_size.x * (0.30 + float(i) * 0.13)
		draw_arc(center + Vector2(0, viewport_size.y * 0.03), radius, 0.0, TAU, 96, Color("#79d8ff", 0.10 - float(i) * 0.012), 1.2)
	for i in range(-8, 12):
		var x := center.x + float(i) * 76.0
		draw_line(Vector2(x, -40), Vector2(x - viewport_size.y * 0.36, viewport_size.y + 40), Color("#79d8ff", 0.055), 1.0)
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#030814", 0.18), false, 18.0)


func _draw_intro_title_panel(viewport_size: Vector2, chapter: Dictionary, active_id: String) -> void:
	var panel_w := minf(660.0, viewport_size.x - 180.0)
	var title_rect := Rect2(Vector2(viewport_size.x * 0.5 - panel_w * 0.5, 58.0), Vector2(panel_w, 110.0))
	draw_rect(Rect2(title_rect.position + Vector2(0, 5), title_rect.size), Color("#030814", 0.26))
	draw_rect(title_rect, Color("#071126", 0.78))
	draw_rect(title_rect.grow(-3), Color("#0d1a2d", 0.36))
	draw_rect(title_rect, Color("#090c12", 0.82), false, 2.0)
	draw_rect(title_rect.grow(-3), Color("#c79a46", 0.66), false, 1.2)
	draw_rect(title_rect.grow(-9), Color("#f6d26b", 0.18), false, 1.0)
	_draw_panel_corner(title_rect, Color("#f6d26b", 0.72), 24.0, 2.0)
	var line_y := title_rect.position.y + 16.0
	draw_line(title_rect.position + Vector2(32, line_y), title_rect.position + Vector2(title_rect.size.x * 0.36, line_y), Color("#f6d26b", 0.36), 1.0)
	draw_line(title_rect.position + Vector2(title_rect.size.x * 0.64, line_y), title_rect.position + Vector2(title_rect.size.x - 32, line_y), Color("#f6d26b", 0.36), 1.0)
	draw_string(get_theme_default_font(), title_rect.position + Vector2(0, 40), chapter.get("title", ""), HORIZONTAL_ALIGNMENT_CENTER, title_rect.size.x, 30, Color("#fff4ba"))
	draw_string(get_theme_default_font(), title_rect.position + Vector2(0, 72), chapter.get("place", ""), HORIZONTAL_ALIGNMENT_CENTER, title_rect.size.x, 14, Color("#dce6ff"))
	var enemy_rect := Rect2(title_rect.position + Vector2(116, 82), Vector2(title_rect.size.x - 232, 20))
	draw_rect(enemy_rect, Color("#030814", 0.24))
	draw_rect(enemy_rect, Color("#c79a46", 0.20), false, 1.0)
	draw_string(get_theme_default_font(), enemy_rect.position + Vector2(0, 15), "敌势  %s" % chapter.get("enemy", ""), HORIZONTAL_ALIGNMENT_CENTER, enemy_rect.size.x, 12, Color("#ffcfda"))
	_draw_intro_party_marks(viewport_size, active_id, title_rect.end.y + 22.0)


func _draw_intro_dialogue(dialogue_rect: Rect2, line: Dictionary) -> void:
	var dialogue_frame: Texture2D = null
	if assets != null:
		dialogue_frame = assets.ui_textures.get("dialogue_frame", null) as Texture2D
	if dialogue_frame != null:
		draw_texture_rect(dialogue_frame, dialogue_rect, false)
	else:
		draw_rect(dialogue_rect, Color("#071126", 0.86))
		draw_rect(dialogue_rect, Color("#f6d26b", 0.28), false, 2.0)
	var nameplate_rect := Rect2(dialogue_rect.position + Vector2(58.0, 12.0), Vector2(220.0, 38.0))
	draw_string(get_theme_default_font(), nameplate_rect.position + Vector2(0, 26), String(line.get("speaker", "")), HORIZONTAL_ALIGNMENT_CENTER, nameplate_rect.size.x, 18, Color("#fff4ba"))
	draw_string(get_theme_default_font(), dialogue_rect.position + Vector2(58, 122), String(line.get("text", "")), HORIZONTAL_ALIGNMENT_LEFT, dialogue_rect.size.x - 116, 20, Color("#f4f7ff"))


func _draw_intro_light_rays(_viewport_size: Vector2, _portrait_id: String) -> void:
	return


func _draw_intro_portrait(viewport_size: Vector2, portrait_id: String) -> void:
	if assets == null or portrait_id == "":
		return
	var portrait: Texture2D = assets.portrait_textures.get(portrait_id, null) as Texture2D
	if portrait == null:
		return
	var portrait_h: float = minf(viewport_size.y * 0.78, 548.0)
	var portrait_w: float = portrait_h * 0.677
	var right_side := portrait_id == "liora"
	var x := viewport_size.x - portrait_w - 76.0 if right_side else 76.0
	var y := viewport_size.y - portrait_h - 54.0
	var rect := Rect2(Vector2(x, y), Vector2(portrait_w, portrait_h))
	draw_texture_rect(portrait, rect, false)


func _draw_intro_party_marks(viewport_size: Vector2, active_id: String, y: float = 184.0) -> void:
	if assets == null:
		return
	var ids := ["astra", "liora", "kael"]
	var start_x := viewport_size.x * 0.5 - 70.0
	for i in range(ids.size()):
		var portrait_id: String = ids[i]
		var center := Vector2(start_x + float(i) * 70.0, y)
		var active := portrait_id == active_id
		var outer_radius := 19.0 if active else 15.0
		var inner_radius := 15.0 if active else 12.0
		draw_circle(center + Vector2(0, 2), outer_radius, Color("#030814", 0.32))
		draw_circle(center, outer_radius, Color("#071126", 0.82))
		draw_circle(center, outer_radius, Color("#c79a46", 0.58 if active else 0.28), false, 2.0)
		draw_circle(center, inner_radius, _portrait_accent(portrait_id, 0.16 if active else 0.08))
		var token: Texture2D = _intro_token_for_portrait(portrait_id)
		if token != null:
			var token_size := 30.0 if active else 23.0
			draw_texture_rect(token, Rect2(center - Vector2(token_size * 0.5, token_size * 0.62), Vector2(token_size, token_size)), false)


func _draw_panel_corner(rect: Rect2, color: Color, length: float, width: float) -> void:
	draw_line(rect.position + Vector2(8, 8), rect.position + Vector2(8 + length, 8), color, width)
	draw_line(rect.position + Vector2(8, 8), rect.position + Vector2(8, 8 + length), color, width)
	draw_line(rect.position + Vector2(rect.size.x - 8, 8), rect.position + Vector2(rect.size.x - 8 - length, 8), color, width)
	draw_line(rect.position + Vector2(rect.size.x - 8, 8), rect.position + Vector2(rect.size.x - 8, 8 + length), color, width)
	draw_line(rect.position + Vector2(8, rect.size.y - 8), rect.position + Vector2(8 + length, rect.size.y - 8), color, width)
	draw_line(rect.position + Vector2(8, rect.size.y - 8), rect.position + Vector2(8, rect.size.y - 8 - length), color, width)
	draw_line(rect.end - Vector2(8, 8), rect.end - Vector2(8 + length, 8), color, width)
	draw_line(rect.end - Vector2(8, 8), rect.end - Vector2(8, 8 + length), color, width)


func _intro_token_for_portrait(portrait_id: String) -> Texture2D:
	match portrait_id:
		"astra":
			return assets.token_textures.get("hero", null) as Texture2D
		"liora":
			return assets.token_textures.get("faith", null) as Texture2D
		"kael":
			return assets.token_textures.get("guard", null) as Texture2D
	return null


func _portrait_accent(portrait_id: String, alpha: float) -> Color:
	match portrait_id:
		"astra":
			return Color("#6ad7ff", alpha)
		"liora":
			return Color("#8fffd8", alpha)
		"kael":
			return Color("#f6d26b", alpha)
	return Color("#fff4ba", alpha)


func _draw_promotion_panel(viewport_size: Vector2) -> void:
	var rect := Rect2(Vector2(viewport_size.x * 0.5 - 390, viewport_size.y * 0.5 - 210), Vector2(780, 420))
	draw_rect(rect, Color("#061026", 0.92))
	if assets != null:
		var frame: Texture2D = assets.ui_textures.get("reward_panel")
		if frame != null:
			draw_texture_rect(frame, rect, false)
	draw_rect(rect.grow(-22), Color("#101832", 0.84))
	draw_rect(rect.grow(-12), Color("#f6d26b", 0.42), false, 2.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(0, 52), "转职选择", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 30, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(0, 80), "条件：Lv10 以上，并消耗 1 个转职纹章。剩余 %d" % state.promotion_seal_count(), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 15, Color("#dce6ff"))
	var card_size := Vector2(210, 150)
	var gap := 16.0
	var options: Array = state.promotion_options
	var columns := 3
	var option_count := mini(options.size(), 6)
	var total_w: float = card_size.x * float(columns) + gap * float(columns - 1)
	var start := Vector2(rect.position.x + (rect.size.x - total_w) * 0.5, rect.position.y + 112)
	for i in range(options.size()):
		if i >= option_count:
			break
		var column := i % columns
		var row := floori(float(i) / float(columns))
		var option_rect := Rect2(start + Vector2(float(column) * (card_size.x + gap), float(row) * (card_size.y + 8.0)), card_size)
		promotion_rects.append(option_rect)
		_draw_promotion_card(option_rect, options[i])


func _draw_promotion_card(rect: Rect2, option: Dictionary) -> void:
	var member := state._party_member_by_character_id(String(option.get("character_id", "")))
	var requirement := state.promotion_requirement_text(member)
	draw_rect(Rect2(rect.position + Vector2(0, 5), rect.size), Color("#030814", 0.34))
	draw_rect(rect, Color("#18213a"))
	draw_rect(rect.grow(-4), Color("#071126", 0.86))
	draw_rect(rect, Color("#f6d26b", 0.42), false, 1.6)
	draw_string(get_theme_default_font(), rect.position + Vector2(10, 22), state.character_name(option.get("character_id", "")), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, 12, Color("#b7caef"))
	draw_string(get_theme_default_font(), rect.position + Vector2(10, 45), option.get("name", ""), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, 16, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(10, 64), state.promotion_stat_summary(option), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, 11, Color("#dce6ff"))
	draw_string(get_theme_default_font(), rect.position + Vector2(10, 82), "定位：%s" % state.promotion_role_summary(option), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, 10, Color("#79d8ff"))
	draw_string(get_theme_default_font(), rect.position + Vector2(10, 100), "条件：%s" % requirement, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, 10, Color("#f6d26b"))
	draw_string(get_theme_default_font(), rect.position + Vector2(10, 118), "被动：%s" % option.get("passive", ""), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, 10, Color("#f4f7ff"))
	draw_string(get_theme_default_font(), rect.position + Vector2(0, rect.size.y - 13), "消耗纹章转职", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 12, Color("#fff4ba"))


func _draw_chapter_complete_panel(viewport_size: Vector2) -> void:
	var rect := Rect2(Vector2(viewport_size.x * 0.5 - 340, viewport_size.y * 0.5 - 174), Vector2(680, 348))
	draw_rect(rect, Color("#061026", 0.92))
	draw_rect(rect.grow(-8), Color("#f6d26b", 0.42), false, 2.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(0, 54), "章节完成", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 34, Color("#fff4ba"))
	var row_x := rect.position.x + 54
	var row_w := rect.size.x - 108
	var y := rect.position.y + 92
	_draw_chapter_summary_row(Rect2(Vector2(row_x, y), Vector2(row_w, 38)), "战斗", state.chapter_battle_summary(), Color("#79d8ff"))
	_draw_chapter_summary_row(Rect2(Vector2(row_x, y + 48), Vector2(row_w, 38)), "技能", state.chapter_reward_summary(), Color("#8fffd8"))
	_draw_chapter_summary_row(Rect2(Vector2(row_x, y + 96), Vector2(row_w, 38)), "营地", state.chapter_camp_summary(), Color("#f6d26b"))
	_draw_chapter_summary_row(Rect2(Vector2(row_x, y + 144), Vector2(row_w, 50)), "转职", state.promotion_confirmation_title(), Color("#fff4ba"), state.promotion_confirmation_note())
	if state.has_next_chapter():
		next_battle_rect = Rect2(rect.position + Vector2(rect.size.x * 0.5 - 76, rect.size.y - 46), Vector2(152, 30))
		_draw_result_button(next_battle_rect, "进入下一章", Color("#f6d26b"), Color("#101832"))
	else:
		draw_string(get_theme_default_font(), rect.position + Vector2(46, rect.size.y - 34), state.chapter_next_step_summary(), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 92, 13, Color("#b7caef"))


func _draw_chapter_summary_row(rect: Rect2, label: String, title: String, accent: Color, detail: String = "") -> void:
	draw_rect(rect, Color("#071126", 0.58))
	draw_rect(Rect2(rect.position, Vector2(5, rect.size.y)), Color(accent, 0.82))
	draw_rect(rect, Color(accent, 0.22), false, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(14, 23), label, HORIZONTAL_ALIGNMENT_LEFT, 46, 12, accent)
	draw_string(get_theme_default_font(), rect.position + Vector2(68, 22), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 82, 12, Color("#f4f7ff"))
	if detail != "":
		draw_string(get_theme_default_font(), rect.position + Vector2(68, 40), detail, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 82, 10, Color("#b7caef"))



func _draw_skill_panel(viewport_size: Vector2) -> void:
	var rect := Rect2(Vector2(viewport_size.x * 0.5 + 320, viewport_size.y * 0.5 - 138), Vector2(280, 276))
	if rect.end.x > viewport_size.x - 24:
		rect.position.x = viewport_size.x * 0.5 - 600
	draw_rect(rect, Color("#061026", 0.9))
	draw_rect(rect.grow(-4), Color("#101832", 0.72))
	draw_rect(rect.grow(-3), Color("#78d7ff", 0.28), false, 1.3)
	draw_string(get_theme_default_font(), rect.position + Vector2(18, 30), "领悟技能", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36, 18, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(18, 50), "角色成长", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36, 11, Color("#b7caef"))
	var rows := state.deck_card_counts()
	var y := rect.position.y + 76.0
	var max_rows := mini(rows.size(), 10)
	for i in range(max_rows):
		var row: Dictionary = rows[i]
		var row_rect := Rect2(Vector2(rect.position.x + 16, y + float(i * 18)), Vector2(rect.size.x - 32, 16))
		var accent := _reward_accent(String(row["kind"]))
		draw_rect(row_rect, Color("#071126", 0.5))
		draw_rect(Rect2(row_rect.position, Vector2(4, row_rect.size.y)), accent)
		draw_string(get_theme_default_font(), row_rect.position + Vector2(10, 12), "%s｜%s" % [String(row.get("owner", "")), String(row["title"])], HORIZONTAL_ALIGNMENT_LEFT, row_rect.size.x - 18, 10, Color("#dce6ff"))
	if rows.size() > max_rows:
		draw_string(get_theme_default_font(), rect.position + Vector2(18, rect.end.y - 20), "还有 %d 个技能。" % (rows.size() - max_rows), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36, 10, Color("#b7caef"))


func _draw_reward_panel(viewport_size: Vector2) -> void:
	var rect := Rect2(Vector2(viewport_size.x * 0.5 - 340, viewport_size.y * 0.5 - 180), Vector2(680, 360))
	draw_rect(rect, Color("#061026", 0.92))
	if assets != null:
		var frame: Texture2D = assets.ui_textures.get("reward_panel")
		if frame != null:
			draw_texture_rect(frame, rect, false)
	draw_rect(rect.grow(-24), Color("#101832", 0.86))
	draw_rect(rect.grow(-12), Color("#f6d26b", 0.5), false, 2.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(0, 52), "战后领悟", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 30, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(0, 80), "选择一种战斗心得，让对应角色学会新招式", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 15, Color("#dce6ff"))
	var card_size := Vector2(150, 206)
	var gap := 24.0
	var option_count := state.reward_options.size()
	var total_w := card_size.x * float(option_count) + gap * float(maxi(option_count - 1, 0))
	var start := Vector2(rect.position.x + (rect.size.x - total_w) * 0.5, rect.position.y + 112)
	for i in range(state.reward_options.size()):
		var card_rect := Rect2(start + Vector2(float(i) * (card_size.x + gap), 0), card_size)
		reward_rects.append(card_rect)
		_draw_reward_card(card_rect, state.reward_options[i])


func _draw_reward_card(rect: Rect2, card: Dictionary) -> void:
	var kind: String = card["kind"]
	var accent := _reward_accent(kind)
	var tier_color := _reward_tier_color(card.get("tier", "基础"))
	draw_rect(Rect2(rect.position + Vector2(0, 5), rect.size), Color("#030814", 0.36))
	draw_rect(rect, Color("#18213a"))
	draw_rect(rect.grow(-4), Color("#fff8d6"))
	draw_rect(Rect2(rect.position + Vector2(5, 5), Vector2(rect.size.x - 10, 31)), accent)
	draw_rect(Rect2(rect.position + Vector2(5, 5), Vector2(5, rect.size.y - 10)), tier_color)
	draw_rect(rect, Color("#101832"), false, 2.0)
	draw_rect(rect.grow(-5), Color("#f6d26b", 0.34), false, 1.0)
	if assets != null:
		var art_texture: Texture2D = assets.card_textures.get(kind)
		if art_texture != null:
			var art_rect := Rect2(rect.position + Vector2(12, 43), Vector2(rect.size.x - 24, 88))
			draw_texture_rect(art_texture, art_rect, false)
			draw_rect(art_rect, Color("#101832", 0.18), false, 1.2)
	draw_circle(rect.position + Vector2(24, 21), 15, Color("#101832"))
	draw_circle(rect.position + Vector2(24, 21), 15, Color("#f6d26b", 0.55), false, 1.8)
	draw_string(get_theme_default_font(), rect.position + Vector2(19, 27), str(card["cost"]), HORIZONTAL_ALIGNMENT_CENTER, 10, 16, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(46, 26), card["title"], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 60, 15, Color.WHITE)
	var owner_name := state.character_name(state.reward_owner_character_id(card)) if state != null else ""
	draw_rect(Rect2(rect.position + Vector2(12, 138), Vector2(rect.size.x - 24, 27)), Color("#071126", 0.64))
	draw_rect(Rect2(rect.position + Vector2(12, 138), Vector2(rect.size.x - 24, 27)), Color(accent, 0.22), false, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(18, 151), owner_name, HORIZONTAL_ALIGNMENT_LEFT, 52, 11, accent)
	draw_string(get_theme_default_font(), rect.position + Vector2(18, 162), state.reward_owner_reason(card), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36, 9, Color("#dce6ff"))
	draw_string(get_theme_default_font(), rect.position + Vector2(rect.size.x - 58, 150), card.get("tier", "基础"), HORIZONTAL_ALIGNMENT_RIGHT, 44, 11, tier_color)
	var text_rect := Rect2(rect.position + Vector2(12, rect.size.y - 48), Vector2(rect.size.x - 24, 34))
	draw_rect(text_rect, Color("#fff7cf", 0.88))
	draw_string(get_theme_default_font(), text_rect.position + Vector2(6, 21), card["text"], HORIZONTAL_ALIGNMENT_LEFT, text_rect.size.x - 12, 12, Color("#24304c"))


func _draw_result_button(rect: Rect2, label: String, fill: Color, text_color: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(0, 3), rect.size), Color("#030814", 0.28))
	draw_rect(rect, fill)
	draw_rect(rect.grow(-2), Color("#2a1b12", 0.32), false, 2.0)
	draw_rect(rect.grow(-5), Color("#fff4ba", 0.18), false, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(0, 23), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 14, text_color)


func _reward_accent(kind: String) -> Color:
	match kind:
		BattleAssets.CARD_STRIKE, BattleAssets.CARD_LANCE:
			return Color("#b83c4b")
		BattleAssets.CARD_DASH:
			return Color("#1b7772")
		BattleAssets.CARD_GUARD:
			return Color("#536d93")
		BattleAssets.CARD_ENGAGE:
			return Color("#247ec0")
		BattleAssets.CARD_HEAL:
			return Color("#328d5b")
	return Color("#26344f")


func _reward_tier_color(tier: String) -> Color:
	match tier:
		"精良":
			return Color("#f6d26b")
		"进阶":
			return Color("#79d8ff")
	return Color("#d6dee8")


func _join_strings(values: Array, separator: String) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(String(value))
	return separator.join(parts)


func _draw_chip(rect: Rect2, label: String, color: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(0, 3), rect.size), Color("#030814", 0.24))
	draw_rect(rect, Color("#071126", 0.64))
	draw_rect(rect.grow(-3), Color("#10233f", 0.46))
	draw_rect(rect, Color("#9ff0ff", 0.26), false, 1.2)
	draw_rect(rect.grow(-5), Color("#fff4ba", 0.08), false, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(0, 23), _shorten_to_width(label, rect.size.x - 12.0, 15), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 15, color)


func _draw_banners(viewport_size: Vector2) -> void:
	for visual_event in state.visual_events:
		if visual_event.get("kind", "") != "banner":
			continue
		var progress: float = clampf(float(visual_event["age"]) / float(visual_event["duration"]), 0.0, 1.0)
		var alpha := sin(progress * PI)
		if alpha <= 0.01:
			continue
		var rect := Rect2(Vector2(viewport_size.x * 0.5 - 170, 70), Vector2(340, 46))
		_draw_overlay_panel(rect, alpha, Color("#f6d26b", 0.34 * alpha))
		draw_string(get_theme_default_font(), rect.position + Vector2(0, 30), _shorten_to_width(visual_event.get("message", ""), rect.size.x - 32.0, 20), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 20, Color("#fff4ba", alpha))


func _draw_objective_cards(viewport_size: Vector2) -> void:
	if state.has_tutorial_step():
		return
	for visual_event in state.visual_events:
		if visual_event.get("kind", "") != "objective":
			continue
		var progress: float = clampf(float(visual_event["age"]) / float(visual_event["duration"]), 0.0, 1.0)
		var alpha := clampf(sin(progress * PI), 0.0, 1.0)
		if alpha <= 0.01:
			continue
		var rect_w := minf(340.0, viewport_size.x - 72.0)
		var rect := Rect2(Vector2(viewport_size.x - rect_w - 36.0, 24.0), Vector2(rect_w, 46.0))
		if layout != null and layout.sidebar_rect != Rect2():
			rect.position.x = minf(rect.position.x, layout.sidebar_rect.position.x - rect.size.x - 20.0)
			rect.position.x = maxf(36.0, rect.position.x)
		var texture: Texture2D = null
		if assets != null:
			texture = assets.ui_textures.get("objective_pill", null) as Texture2D
		if texture != null:
			draw_texture_rect(texture, rect.grow(4.0), false, Color(1.0, 1.0, 1.0, alpha))
		else:
			_draw_overlay_panel(rect, alpha, Color("#f6d26b", 0.24 * alpha))
		draw_string(get_theme_default_font(), rect.position + Vector2(18, 29), _shorten_to_width(visual_event.get("message", ""), rect.size.x - 36.0, 16), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36, 16, Color("#fff4ba", alpha))


func _draw_tutorial_feedback_cards(viewport_size: Vector2) -> void:
	var slot := 0
	for visual_event in state.visual_events:
		if not (visual_event.get("kind", "") in ["tutorial", "tutorial_feedback"]):
			continue
		var progress: float = clampf(float(visual_event["age"]) / float(visual_event["duration"]), 0.0, 1.0)
		var alpha := clampf(sin(progress * PI), 0.0, 1.0)
		if alpha <= 0.01:
			continue
		var tone := String(visual_event.get("tone", "info"))
		var accent := _tutorial_feedback_color(tone)
		var rect := Rect2(Vector2(viewport_size.x * 0.5 - 230, 238 + float(slot) * 68.0), Vector2(440, 58))
		if layout != null and layout.board_rect != Rect2():
			rect.size.x = minf(440.0, layout.board_rect.size.x * 0.72)
			rect.position.x = layout.board_rect.get_center().x - rect.size.x * 0.5
			rect.position.y = layout.board_rect.position.y + 14.0 + float(slot) * 66.0
		_draw_overlay_panel(rect, alpha, Color(accent, 0.28 * alpha))
		draw_rect(Rect2(rect.position + Vector2(5, 5), Vector2(4, rect.size.y - 10)), Color(accent, 0.78 * alpha))
		draw_string(get_theme_default_font(), rect.position + Vector2(18, 23), _shorten_to_width(String(visual_event.get("message", "")), rect.size.x - 36.0, 15), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36, 15, Color("#fff4ba", alpha))
		draw_string(get_theme_default_font(), rect.position + Vector2(18, 43), _shorten_to_width(String(visual_event.get("detail", "")), rect.size.x - 36.0, 11), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36, 11, Color("#dce6ff", alpha))
		slot += 1


func _draw_tutorial_panel(viewport_size: Vector2) -> void:
	if not state.has_tutorial_step():
		return
	var recommendation := state.tutorial_recommendation_text()
	var rect := Rect2(Vector2(36, 22), Vector2(minf(360.0, viewport_size.x - 72.0), 62 if recommendation == "" else 74))
	if layout != null and layout.board_rect != Rect2():
		rect.size.x = minf(380.0, maxf(300.0, layout.board_rect.size.x * 0.46))
		rect.size.y = minf(rect.size.y, maxf(58.0, layout.board_rect.position.y - 24.0))
		rect.position = Vector2(maxf(36.0, layout.board_rect.position.x - 90.0), maxf(12.0, layout.board_rect.position.y - rect.size.y - 14.0))
	_draw_prompt_panel(rect)
	draw_rect(Rect2(rect.position + Vector2(5, 5), Vector2(4, rect.size.y - 10)), Color("#f6d26b", 0.76))
	draw_string(get_theme_default_font(), rect.position + Vector2(18, 24), _shorten_to_width(state.tutorial_title(), rect.size.x - 80.0, 15), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 80, 15, Color("#fff4ba"))
	var detail := state.tutorial_constraint_text() if recommendation == "" else recommendation
	draw_string(get_theme_default_font(), rect.position + Vector2(18, 45), _shorten_to_width(detail, rect.size.x - 80.0, 10), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 80, 10, Color("#dce6ff"))
	var progress := "%d/%d" % [state.tutorial_step_index + 1, state.tutorial_steps.size()]
	draw_string(get_theme_default_font(), rect.position + Vector2(rect.size.x - 52, 24), progress, HORIZONTAL_ALIGNMENT_RIGHT, 38, 11, Color("#b7caef"))


func _shorten(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, maxi(0, max_chars - 1)) + "…"


func _shorten_to_width(text: String, width: float, font_size: int) -> String:
	var max_chars := maxi(4, int(width / maxf(6.0, float(font_size) * 0.72)))
	return _shorten(text, max_chars)


func _tutorial_feedback_color(tone: String) -> Color:
	match tone:
		"warn":
			return Color("#ff6685")
		"success":
			return Color("#8fffd8")
	return Color("#79d8ff")


func _draw_overlay_panel(rect: Rect2, alpha: float, accent: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color("#030814", 0.28 * alpha))
	draw_rect(rect, Color("#071126", 0.72 * alpha))
	draw_rect(rect.grow(-3), Color("#10233f", 0.64 * alpha))
	draw_rect(rect, Color("#9ff0ff", 0.22 * alpha), false, 2.0)
	draw_rect(rect.grow(-4), Color("#e5fbff", 0.14 * alpha), false, 1.2)
	draw_rect(rect.grow(-9), accent, false, 1.0)
	_draw_panel_corner(rect, Color("#f6d26b", 0.58 * alpha), 20.0, 1.4)


func _draw_prompt_panel(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color("#030814", 0.28))
	draw_rect(rect, Color("#071126", 0.80))
	draw_rect(rect.grow(-3), Color("#10233f", 0.52))
	draw_rect(rect, Color("#9ff0ff", 0.26), false, 2.0)
	draw_rect(rect.grow(-4), Color("#e5fbff", 0.10), false, 1.0)
	_draw_panel_corner(rect, Color("#f6d26b", 0.44), 18.0, 1.2)
