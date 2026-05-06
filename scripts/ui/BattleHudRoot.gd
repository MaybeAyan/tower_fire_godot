@tool
class_name BattleHudRoot
extends Control

const BattleLayoutScript := preload("res://scripts/core/BattleLayout.gd")

signal restart_requested
signal log_toggle_requested
signal cycle_character_requested(step: int)
signal undo_move_requested
signal end_turn_requested
signal skill_page_requested(step: int)
signal skill_selected(skill_index: int, skill_id: String)

@onready var tutorial_card: PanelContainer = $TutorialCard
@onready var tutorial_title_label: Label = $TutorialCard/Margin/VBox/Header/Title
@onready var tutorial_progress_label: Label = $TutorialCard/Margin/VBox/Header/Progress
@onready var tutorial_detail_label: Label = $TutorialCard/Margin/VBox/Detail
@onready var objective_card: PanelContainer = $ObjectiveCard
@onready var objective_message_label: Label = $ObjectiveCard/Margin/Message
@onready var banner_card: PanelContainer = $BannerCard
@onready var banner_message_label: Label = $BannerCard/Margin/Message
@onready var feedback_stack: VBoxContainer = $FeedbackStack
@onready var sidebar_panel: PanelContainer = $SidebarPanel
@onready var header_title_label: Label = $SidebarPanel/Margin/VBox/Header/TitleBlock/Title
@onready var header_subtitle_label: Label = $SidebarPanel/Margin/VBox/Header/TitleBlock/Subtitle
@onready var header_turn_label: Label = $SidebarPanel/Margin/VBox/Header/BadgeRow/TurnBadge
@onready var header_phase_label: Label = $SidebarPanel/Margin/VBox/Header/BadgeRow/PhaseBadge
@onready var character_prev_button: Button = $SidebarPanel/Margin/VBox/CharacterSection/Header/NavRow/PrevCharacter
@onready var character_index_label: Label = $SidebarPanel/Margin/VBox/CharacterSection/Header/NavRow/CharacterIndex
@onready var character_next_button: Button = $SidebarPanel/Margin/VBox/CharacterSection/Header/NavRow/NextCharacter
@onready var portrait_rect: TextureRect = $SidebarPanel/Margin/VBox/CharacterSection/Body/PortraitSlot/Portrait
@onready var portrait_status_label: Label = $SidebarPanel/Margin/VBox/CharacterSection/Body/PortraitSlot/PortraitStatus
@onready var unit_name_label: Label = $SidebarPanel/Margin/VBox/CharacterSection/Body/Info/Name
@onready var unit_class_label: Label = $SidebarPanel/Margin/VBox/CharacterSection/Body/Info/Class
@onready var hp_bar: ProgressBar = $SidebarPanel/Margin/VBox/CharacterSection/Body/Info/HpBlock/HpBar
@onready var hp_label: Label = $SidebarPanel/Margin/VBox/CharacterSection/Body/Info/HpBlock/HpLabel
@onready var stat_power_value: Label = $SidebarPanel/Margin/VBox/CharacterSection/Stats/PowerChip/Value
@onready var stat_move_value: Label = $SidebarPanel/Margin/VBox/CharacterSection/Stats/MoveChip/Value
@onready var stat_block_value: Label = $SidebarPanel/Margin/VBox/CharacterSection/Stats/BlockChip/Value
@onready var mission_summary_label: Label = $SidebarPanel/Margin/VBox/MissionSection/Summary
@onready var mission_failure_label: Label = $SidebarPanel/Margin/VBox/MissionSection/Failure
@onready var mission_metrics_row: HBoxContainer = $SidebarPanel/Margin/VBox/MissionSection/Metrics
@onready var metric_kill_value: Label = $SidebarPanel/Margin/VBox/MissionSection/Metrics/KillChip/Value
@onready var metric_damage_value: Label = $SidebarPanel/Margin/VBox/MissionSection/Metrics/DamageChip/Value
@onready var log_title_label: Label = $SidebarPanel/Margin/VBox/LogSection/Header/Title
@onready var log_toggle_button: Button = $SidebarPanel/Margin/VBox/LogSection/Header/ToggleLog
@onready var log_body_label: RichTextLabel = $SidebarPanel/Margin/VBox/LogSection/Body
@onready var end_turn_button: Button = $SidebarPanel/Margin/VBox/Footer/EndTurn
@onready var undo_button: Button = $SidebarPanel/Margin/VBox/Footer/UndoMove
@onready var restart_button: Button = $SidebarPanel/Margin/VBox/Footer/RestartRun
@onready var skill_dock: PanelContainer = $SkillDock
@onready var skill_title_label: Label = $SkillDock/Margin/VBox/Header/Title
@onready var skill_note_label: Label = $SkillDock/Margin/VBox/Header/Note
@onready var skill_status_label: Label = $SkillDock/Margin/VBox/Header/Status
@onready var prev_skill_page_button: Button = $SkillDock/Margin/VBox/SkillRow/PrevPage
@onready var skill_cards_row: HBoxContainer = $SkillDock/Margin/VBox/SkillRow/Cards
@onready var next_skill_page_button: Button = $SkillDock/Margin/VBox/SkillRow/NextPage
@onready var skill_page_label: Label = $SkillDock/Margin/VBox/PageInfo

var state: BattleState
var assets: BattleAssets
var layout = BattleLayoutScript.new()
var _skill_buttons: Array[Button] = []
var _feedback_cards: Array[PanelContainer] = []
var _skill_page_count := 1
var _visible_skill_count := 1
var _turn_transition: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_card.visible = false
	feedback_stack.visible = false
	_connect_signals()
	_collect_skill_buttons()
	_collect_feedback_cards()
	_configure_text_constraints(self)


func _draw() -> void:
	_draw_turn_transition()


func sync() -> void:
	if state == null or assets == null or layout == null:
		visible = false
		return
	visible = state.chapter_phase == "battle"
	if not visible:
		return
	_apply_layout()
	_sync_header()
	_sync_character_panel()
	_sync_mission_panel()
	_sync_log_panel()
	_sync_footer()
	_sync_tutorial_card()
	_sync_objective_card()
	_sync_banner_card()
	_sync_feedback_cards()
	_sync_skill_dock()
	queue_redraw()


func _connect_signals() -> void:
	character_prev_button.pressed.connect(func() -> void: cycle_character_requested.emit(-1))
	character_next_button.pressed.connect(func() -> void: cycle_character_requested.emit(1))
	log_toggle_button.pressed.connect(func() -> void: log_toggle_requested.emit())
	end_turn_button.pressed.connect(func() -> void: end_turn_requested.emit())
	undo_button.pressed.connect(func() -> void: undo_move_requested.emit())
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	prev_skill_page_button.pressed.connect(func() -> void: skill_page_requested.emit(-1))
	next_skill_page_button.pressed.connect(func() -> void: skill_page_requested.emit(1))


func _collect_skill_buttons() -> void:
	_skill_buttons.clear()
	for child in skill_cards_row.get_children():
		if child is Button:
			var button := child as Button
			_skill_buttons.append(button)
			button.pressed.connect(func() -> void:
				var skill_index := int(button.get_meta("skill_index", -1))
				var skill_id := String(button.get_meta("skill_id", ""))
				if skill_index >= 0:
					skill_selected.emit(skill_index, skill_id)
			)


func _collect_feedback_cards() -> void:
	_feedback_cards.clear()
	for child in feedback_stack.get_children():
		if child is PanelContainer:
			_feedback_cards.append(child as PanelContainer)


func visible_skill_count() -> int:
	return _visible_skill_count


func _apply_layout() -> void:
	_update_rect(sidebar_panel, layout.sidebar_rect)
	_update_rect(skill_dock, layout.hand_dock_rect)
	var tutorial_rect: Rect2 = layout.tutorial_rect
	var objective_rect: Rect2 = layout.objective_rect
	tutorial_card.position = tutorial_rect.position
	tutorial_card.size = tutorial_rect.size
	objective_card.position = objective_rect.position
	objective_card.size = objective_rect.size
	var banner_width := minf(230.0, layout.board_rect.size.x * 0.30)
	var banner_height := clampf(tutorial_rect.size.y * 0.68, 26.0, 32.0)
	banner_card.position = Vector2(layout.board_rect.get_center().x - banner_width * 0.5, maxf(10.0, tutorial_rect.position.y + 2.0))
	banner_card.size = Vector2(banner_width, banner_height)
	var feedback_width := minf(360.0, layout.board_rect.size.x * 0.46)
	feedback_stack.position = Vector2(layout.board_rect.position.x + 18.0, layout.board_rect.position.y + 18.0)
	feedback_stack.custom_minimum_size = Vector2(feedback_width, 0.0)
	feedback_stack.visible = false
	skill_cards_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	skill_cards_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for button in _skill_buttons:
		button.custom_minimum_size = _skill_button_size()
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _sync_header() -> void:
	header_title_label.text = "战术面板"
	header_subtitle_label.text = "第 %d 战" % state.battle_index
	header_turn_label.text = "回合 %d" % state.turn
	header_phase_label.text = state.phase_name()
	header_phase_label.modulate = _phase_color()


func _sync_character_panel() -> void:
	var unit := state.inspected_player_unit()
	var can_cycle := state._character_panel_count() > 1
	character_prev_button.disabled = not can_cycle
	character_next_button.disabled = not can_cycle
	character_index_label.text = state.character_panel_count_label()
	if unit.is_empty():
		portrait_rect.texture = null
		portrait_status_label.text = ""
		unit_name_label.text = "暂无角色"
		unit_class_label.text = ""
		hp_bar.max_value = 1.0
		hp_bar.value = 0.0
		hp_label.text = ""
		stat_power_value.text = "-"
		stat_move_value.text = "-"
		stat_block_value.text = "-"
		return
	var portrait_key := String(unit.get("character_id", ""))
	portrait_rect.texture = assets.portrait_textures.get(portrait_key, null) as Texture2D
	portrait_status_label.text = "待机" if bool(unit.get("acted", false)) else "可行动"
	portrait_status_label.modulate = Color("#b7caef") if bool(unit.get("acted", false)) else Color("#8fffd8")
	unit_name_label.text = String(unit.get("name", ""))
	unit_class_label.text = "%s Lv%d" % [String(unit.get("class_name", "")), int(unit.get("level", 1))]
	hp_bar.max_value = float(maxi(1, int(unit.get("max_hp", 1))))
	hp_bar.value = float(int(unit.get("hp", 0)))
	hp_label.text = "%d/%d" % [int(unit.get("hp", 0)), int(unit.get("max_hp", 0))]
	stat_power_value.text = str(int(unit.get("atk", 0)) + state.player_power)
	stat_move_value.text = str(int(unit.get("move_range", 0)))
	stat_block_value.text = str(int(unit.get("block", 0)))


func _sync_mission_panel() -> void:
	mission_summary_label.text = state.objective_summary()
	mission_failure_label.text = state.failure_summary()
	mission_failure_label.visible = false
	mission_metrics_row.visible = false
	metric_kill_value.text = str(int(state.battle_stats.get("enemies_defeated", 0)))
	metric_damage_value.text = str(int(state.battle_stats.get("damage_taken", 0)))


func _sync_log_panel() -> void:
	log_title_label.text = "战况" if state.log_expanded else "提示"
	log_toggle_button.text = "收起" if state.log_expanded else "展开"
	var lines: Array[String] = []
	if state.log_expanded:
		var logs: Array = state.battle_log.slice(maxi(0, state.battle_log.size() - 5), state.battle_log.size())
		for line in logs:
			lines.append(String(line))
		var focus := _focus_summary()
		if focus != "":
			lines.append("")
			lines.append(focus)
	else:
		var main_text := _focus_summary()
		if main_text == "":
			main_text = state.message
		lines.append(main_text)
	log_body_label.text = "\n".join(lines)


func _sync_footer() -> void:
	var can_end := state.phase == "player" and not state.victory and not state.defeat
	end_turn_button.disabled = not can_end
	end_turn_button.text = "待机" if state.selected_unit_uid != "" else "结束回合"
	undo_button.disabled = not state.can_undo_selected_move()


func _sync_tutorial_card() -> void:
	var should_show := state.has_tutorial_step()
	tutorial_card.visible = should_show
	if not should_show:
		return
	tutorial_title_label.text = state.tutorial_title()
	tutorial_detail_label.text = ""
	tutorial_progress_label.text = "%d/%d" % [state.tutorial_step_index + 1, state.tutorial_steps.size()]


func _sync_objective_card() -> void:
	var message := _active_objective_message()
	objective_card.visible = message != ""
	if not objective_card.visible:
		return
	objective_message_label.text = message


func _sync_banner_card() -> void:
	var banner := _latest_visual_event("banner")
	_turn_transition = banner
	banner_card.visible = false
	if banner.is_empty():
		return
	banner_message_label.text = String(banner.get("message", ""))


func _sync_feedback_cards() -> void:
	feedback_stack.visible = false
	var rows: Array[Dictionary] = []
	for visual_event in state.visual_events:
		var kind := String(visual_event.get("kind", ""))
		if kind in ["tutorial", "tutorial_feedback"]:
			rows.append(visual_event)
	for i in range(_feedback_cards.size()):
		var card := _feedback_cards[i]
		if i >= rows.size():
			card.visible = false
			continue
		var event: Dictionary = rows[i]
		card.visible = true
		card.modulate = Color(1.0, 1.0, 1.0, _event_alpha(event))
		var title := card.get_node("Margin/VBox/Title") as Label
		var detail := card.get_node("Margin/VBox/Detail") as Label
		title.text = String(event.get("message", ""))
		detail.text = String(event.get("detail", ""))
		var tone := String(event.get("tone", "info"))
		var accent := _feedback_color(tone)
		title.modulate = accent


func _sync_skill_dock() -> void:
	var unit := state.selected_unit()
	var can_choose := state.phase == "player" and state.action_mode == "command" and not unit.is_empty() and not bool(unit.get("acted", false))
	skill_title_label.text = "技能" if unit.is_empty() else "%s · 技能" % String(unit.get("name", ""))
	skill_note_label.text = _skill_note(unit, can_choose)
	skill_status_label.text = state.active_hand_counts_text()
	var skills := state.available_skills_for_selected()
	var buttons_available := maxi(1, mini(_skill_buttons.size(), 3))
	_visible_skill_count = buttons_available
	_skill_page_count = state.skill_page_count(_visible_skill_count)
	var start_index := state.skill_page_start(_visible_skill_count)
	prev_skill_page_button.disabled = _skill_page_count <= 1
	next_skill_page_button.disabled = _skill_page_count <= 1
	prev_skill_page_button.visible = _skill_page_count > 1
	next_skill_page_button.visible = _skill_page_count > 1
	skill_page_label.visible = _skill_page_count > 1
	skill_page_label.text = "%d/%d" % [state.skill_page_index + 1, _skill_page_count]
	for i in range(_skill_buttons.size()):
		var button := _skill_buttons[i]
		if i >= _visible_skill_count:
			button.visible = false
			button.disabled = true
			button.text = ""
			button.set_meta("skill_index", -1)
			button.set_meta("skill_id", "")
			continue
		var skill_index := start_index + i
		if unit.is_empty() or skill_index >= skills.size():
			button.visible = false
			button.disabled = true
			button.text = ""
			button.set_meta("skill_index", -1)
			button.set_meta("skill_id", "")
			continue
		var skill: Dictionary = skills[skill_index]
		var playable := can_choose and state.can_unit_execute_card(unit, skill)
		button.visible = true
		button.disabled = not playable
		button.custom_minimum_size = _skill_button_size()
		button.set_meta("skill_index", skill_index)
		button.set_meta("skill_id", String(skill.get("id", "")))
		button.text = "%s\n费%d · %s" % [
			String(skill.get("title", "")),
			int(skill.get("cost", 0)),
			_short_line(String(skill.get("text", "")), 12),
		]
		if state.selected_card == skill_index:
			button.modulate = Color("#fff4ba")
		elif playable:
			button.modulate = Color.WHITE
		else:
			button.modulate = Color(0.72, 0.78, 0.86, 1.0)


func _focus_summary() -> String:
	if state.selected_card >= 0:
		return "技能｜%s" % state.selected_card_sidebar_summary()
	if state.focused_enemy_uid != "":
		var forecast := state.focused_enemy_forecast()
		if not forecast.is_empty():
			return "敌意图｜%s" % String(forecast.get("summary", ""))
	if state.has_hover_tile():
		var terrain_summary := state.terrain_hover_summary(state.hover_tile)
		if terrain_summary != "":
			return terrain_summary
	return ""


func _active_objective_message() -> String:
	if state.has_tutorial_step():
		return ""
	var objective := _latest_visual_event("objective")
	if objective.is_empty():
		return ""
	return String(objective.get("message", ""))


func _latest_visual_event(kind: String) -> Dictionary:
	for i in range(state.visual_events.size() - 1, -1, -1):
		var visual_event: Dictionary = state.visual_events[i]
		if String(visual_event.get("kind", "")) == kind:
			return visual_event
	return {}


func _event_alpha(event: Dictionary) -> float:
	var duration := maxf(0.001, float(event.get("duration", 1.0)))
	var age := clampf(float(event.get("age", 0.0)) / duration, 0.0, 1.0)
	return clampf(sin(age * PI), 0.0, 1.0)


func _feedback_color(tone: String) -> Color:
	match tone:
		"warn":
			return Color("#ff6685")
		"success":
			return Color("#8fffd8")
	return Color("#79d8ff")


func _skill_note(unit: Dictionary, can_choose: bool) -> String:
	if unit.is_empty():
		return "选择单位后显示当前技能。"
	if bool(unit.get("acted", false)):
		return "该单位已行动"
	if state.action_mode == "move":
		return "先选择移动位置，或点击自身格原地行动"
	if can_choose:
		return "选择技能，或点击敌人普通攻击"
	return "当前不能使用技能"


func _short_line(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, maxi(1, max_chars - 1)) + "…"


func _skill_button_size() -> Vector2:
	return Vector2(clampf(layout.card_size.x, 196.0, 214.0), clampf(layout.card_size.y, 62.0, 66.0))


func _draw_turn_transition() -> void:
	if _turn_transition.is_empty():
		return
	var alpha := _event_alpha(_turn_transition)
	if alpha <= 0.01:
		return
	var view_size := get_viewport_rect().size
	var eased := _ease_in_out_sine(alpha)
	draw_rect(Rect2(Vector2.ZERO, view_size), Color("#060504", 0.18 * eased))
	var text := String(_turn_transition.get("message", ""))
	if text == "":
		return
	var font := get_theme_default_font()
	var font_size := 20
	var text_width := minf(320.0, view_size.x * 0.58)
	var text_size := Vector2(text_width + 52.0, 46.0)
	var lift := (1.0 - eased) * 8.0
	var text_rect := Rect2(Vector2((view_size.x - text_size.x) * 0.5, view_size.y * 0.43 - lift), text_size)
	draw_rect(text_rect, Color("#120c07", 0.46 * eased))
	draw_rect(text_rect, Color("#e0b15f", 0.15 * eased), false, 1.0)
	var hairline_y := text_rect.position.y + text_rect.size.y - 8.0
	draw_line(Vector2(text_rect.position.x + 24.0, hairline_y), Vector2(text_rect.end.x - 24.0, hairline_y), Color("#f0c66e", 0.22 * eased), 1.0)
	draw_string(font, text_rect.position + Vector2(26.0, 28.0), text, HORIZONTAL_ALIGNMENT_CENTER, text_width, font_size, Color("#fff0bc", eased))


func _ease_in_out_sine(value: float) -> float:
	return 0.5 - 0.5 * cos(clampf(value, 0.0, 1.0) * PI)


func _configure_text_constraints(node: Node) -> void:
	if node is Label:
		var label := node as Label
		label.clip_text = true
		if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		else:
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	elif node is Button:
		var button := node as Button
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	elif node is RichTextLabel:
		var rich_text := node as RichTextLabel
		rich_text.fit_content = false
		rich_text.scroll_active = false
	for child in node.get_children():
		_configure_text_constraints(child)


func _phase_color() -> Color:
	if state.phase == "player":
		return Color("#8fffd8")
	if state.phase == "enemy":
		return Color("#ff77a0")
	return Color("#f6d26b")


func _update_rect(node: Control, rect: Rect2) -> void:
	node.position = rect.position
	node.size = rect.size
