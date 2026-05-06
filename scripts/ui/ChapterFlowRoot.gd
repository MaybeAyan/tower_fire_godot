@tool
class_name ChapterFlowRoot
extends Control

const BattleLayoutScript := preload("res://scripts/core/BattleLayout.gd")

signal chapter_node_requested(node_index: int)
signal camp_member_selected(character_id: String)
signal camp_close_requested
signal camp_rest_requested
signal camp_deploy_requested(character_id: String)
signal camp_event_requested(option_index: int)
signal camp_skill_requested(skill_id: String)
signal next_chapter_requested

@onready var chapter_map_layer: Control = $ChapterMapLayer
@onready var chapter_title_label: Label = $ChapterMapLayer/MapPanel/Margin/VBox/Title
@onready var chapter_subtitle_label: Label = $ChapterMapLayer/MapPanel/Margin/VBox/SubTitle
@onready var chapter_node_row: HBoxContainer = $ChapterMapLayer/MapPanel/Margin/VBox/Nodes
@onready var party_row: HBoxContainer = $ChapterMapLayer/MapPanel/Margin/VBox/PartyRow
@onready var reward_summary_label: Label = $ChapterMapLayer/MapPanel/Margin/VBox/Footer/RewardSummary
@onready var pending_summary_label: Label = $ChapterMapLayer/MapPanel/Margin/VBox/Footer/PendingSummary
@onready var camp_panel: PanelContainer = $ChapterMapLayer/CampPanel
@onready var camp_member_title_label: Label = $ChapterMapLayer/CampPanel/Margin/VBox/Header/MemberTitle
@onready var camp_member_passive_label: Label = $ChapterMapLayer/CampPanel/Margin/VBox/Header/Passive
@onready var camp_close_button: Button = $ChapterMapLayer/CampPanel/Margin/VBox/Header/Actions/Close
@onready var camp_deploy_button: Button = $ChapterMapLayer/CampPanel/Margin/VBox/Header/Actions/Deploy
@onready var camp_rest_button: Button = $ChapterMapLayer/CampPanel/Margin/VBox/Header/Actions/Rest
@onready var camp_rest_summary_label: Label = $ChapterMapLayer/CampPanel/Margin/VBox/RestSummary
@onready var camp_event_row: HBoxContainer = $ChapterMapLayer/CampPanel/Margin/VBox/EventCards
@onready var camp_skill_column: VBoxContainer = $ChapterMapLayer/CampPanel/Margin/VBox/SkillCards
@onready var complete_layer: Control = $CompleteLayer
@onready var complete_battle_label: Label = $CompleteLayer/CompletePanel/Margin/VBox/BattleSummary
@onready var complete_reward_label: Label = $CompleteLayer/CompletePanel/Margin/VBox/RewardSummary
@onready var complete_camp_label: Label = $CompleteLayer/CompletePanel/Margin/VBox/CampSummary
@onready var complete_promotion_label: Label = $CompleteLayer/CompletePanel/Margin/VBox/PromotionSummary
@onready var complete_note_label: Label = $CompleteLayer/CompletePanel/Margin/VBox/Note
@onready var next_chapter_button: Button = $CompleteLayer/CompletePanel/Margin/VBox/NextChapter

var state: BattleState
var assets: BattleAssets
var layout = BattleLayoutScript.new()
var _node_buttons: Array[Button] = []
var _party_buttons: Array[Button] = []
var _event_buttons: Array[Button] = []
var _skill_buttons: Array[Button] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_collect_buttons()
	_connect_buttons()
	_configure_text_constraints(self)


func sync() -> void:
	if state == null or assets == null or layout == null:
		visible = false
		return
	visible = state.chapter_phase in ["chapter_map", "complete"]
	if not visible:
		return
	_apply_layout()
	_sync_chapter_map()
	_sync_complete()


func _collect_buttons() -> void:
	_node_buttons.clear()
	for child in chapter_node_row.get_children():
		if child is Button:
			_node_buttons.append(child as Button)
	_party_buttons.clear()
	for child in party_row.get_children():
		if child is Button:
			_party_buttons.append(child as Button)
	_event_buttons.clear()
	for child in camp_event_row.get_children():
		if child is Button:
			_event_buttons.append(child as Button)
	_skill_buttons.clear()
	for child in camp_skill_column.get_children():
		if child is Button:
			_skill_buttons.append(child as Button)


func _connect_buttons() -> void:
	for i in range(_node_buttons.size()):
		var button := _node_buttons[i]
		var index := i + 1
		button.pressed.connect(func() -> void:
			chapter_node_requested.emit(index)
		)
	for party_index in range(_party_buttons.size()):
		var party_button := _party_buttons[party_index]
		party_button.pressed.connect(func() -> void:
			var character_id := String(party_button.get_meta("character_id", ""))
			if character_id != "":
				camp_member_selected.emit(character_id)
		)
	for event_index in range(_event_buttons.size()):
		var event_button := _event_buttons[event_index]
		var option_index := event_index
		event_button.pressed.connect(func() -> void:
			camp_event_requested.emit(option_index)
		)
	for skill_index in range(_skill_buttons.size()):
		var skill_button := _skill_buttons[skill_index]
		skill_button.pressed.connect(func() -> void:
			var skill_id := String(skill_button.get_meta("skill_id", ""))
			if skill_id != "":
				camp_skill_requested.emit(skill_id)
		)
	camp_close_button.pressed.connect(func() -> void: camp_close_requested.emit())
	camp_rest_button.pressed.connect(func() -> void: camp_rest_requested.emit())
	camp_deploy_button.pressed.connect(func() -> void:
		var character_id := String(camp_deploy_button.get_meta("character_id", ""))
		if character_id != "":
			camp_deploy_requested.emit(character_id)
	)
	next_chapter_button.pressed.connect(func() -> void: next_chapter_requested.emit())


func _apply_layout() -> void:
	var view_size := get_viewport_rect().size
	var map_rect: Rect2 = layout.modal_rect
	chapter_map_layer.position = Vector2.ZERO
	chapter_map_layer.size = view_size
	if state != null and state.camp_view_open and state.chapter_phase == "chapter_map":
		map_rect = Rect2(
			Vector2(view_size.x * 0.5 - 420.0, 42.0),
			Vector2(840.0, 228.0)
		)
	($ChapterMapLayer/MapPanel as Control).position = map_rect.position
	($ChapterMapLayer/MapPanel as Control).size = map_rect.size
	var camp_width := minf(860.0, view_size.x - 140.0)
	var camp_height := minf(390.0, view_size.y - map_rect.end.y - 40.0)
	var camp_rect := Rect2(
		Vector2(view_size.x * 0.5 - camp_width * 0.5, map_rect.end.y + 16.0),
		Vector2(camp_width, maxf(300.0, camp_height))
	)
	camp_panel.position = camp_rect.position
	camp_panel.size = camp_rect.size
	var complete_rect: Rect2 = Rect2(
		Vector2(view_size.x * 0.5 - 390.0, view_size.y * 0.5 - 210.0),
		Vector2(780.0, 420.0)
	)
	($CompleteLayer/CompletePanel as Control).position = complete_rect.position
	($CompleteLayer/CompletePanel as Control).size = complete_rect.size


func _sync_chapter_map() -> void:
	chapter_map_layer.visible = state.chapter_phase == "chapter_map"
	if not chapter_map_layer.visible:
		return
	chapter_title_label.text = "战间营地"
	chapter_subtitle_label.text = "整备幸存者、选择羁绊事件，然后推进下一处遭遇"
	var nodes := state.chapter_map_nodes()
	for i in range(_node_buttons.size()):
		var button := _node_buttons[i]
		if i >= nodes.size():
			button.visible = false
			button.disabled = true
			continue
		var node: Dictionary = nodes[i]
		button.visible = true
		button.disabled = not state.can_enter_chapter_map_node(i + 1)
		var node_status := _node_status_text(node)
		var node_detail := "Boss战" if bool(node.get("boss", false)) else "遭遇"
		button.custom_minimum_size = Vector2(172, 62)
		button.text = "%d. %s\n%s" % [
			int(node.get("index", i + 1)),
			String(node.get("name", "")),
			"%s｜%s" % [node_status, node_detail],
		]
		button.modulate = _node_status_color(String(node.get("status", "locked")), bool(node.get("boss", false)))
	var rows := state.chapter_map_party_rows()
	for party_idx in range(_party_buttons.size()):
		var party_button := _party_buttons[party_idx]
		if party_idx >= rows.size():
			party_button.visible = false
			party_button.disabled = true
			party_button.set_meta("character_id", "")
			continue
		var row: Dictionary = rows[party_idx]
		party_button.visible = true
		party_button.disabled = false
		party_button.set_meta("character_id", String(row.get("character_id", "")))
		var deploy_label := "出战" if bool(row.get("deployed", false)) else "候补"
		party_button.custom_minimum_size = Vector2(168, 76)
		party_button.text = "%s\n%s Lv%d\n%s · 出战技能%d/%d" % [
			String(row.get("name", "")),
			String(row.get("class", "")),
			int(row.get("level", 1)),
			deploy_label,
			int(row.get("active_count", 0)),
			int(row.get("equip_limit", 2)),
		]
		party_button.icon = assets.portrait_textures.get(String(row.get("character_id", "")), null) as Texture2D
		party_button.expand_icon = true
		party_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	reward_summary_label.text = state.chapter_reward_summary()
	pending_summary_label.text = state.chapter_camp_pending_summary()
	_sync_camp_panel()


func _sync_camp_panel() -> void:
	camp_panel.visible = state.camp_view_open
	if not camp_panel.visible:
		return
	var member := state.chapter_camp_selected_member_row()
	var character_id := String(member.get("character_id", ""))
	camp_member_title_label.text = "%s｜%s T%d" % [
		String(member.get("name", "")),
		String(member.get("class", "")),
		int(member.get("tier", 1)),
	]
	camp_member_passive_label.text = String(member.get("passive", ""))
	camp_deploy_button.set_meta("character_id", character_id)
	camp_deploy_button.text = "调为候补" if bool(member.get("deployed", false)) else "设为出战"
	camp_rest_button.disabled = not state.can_use_chapter_camp_rest()
	camp_rest_button.text = "训练"
	camp_rest_summary_label.text = state.chapter_camp_rest_summary()
	var events := state.chapter_camp_event_options()
	for i in range(_event_buttons.size()):
		var button := _event_buttons[i]
		if i >= events.size():
			button.visible = false
			button.disabled = true
			continue
		var option: Dictionary = events[i]
		button.visible = true
		button.disabled = not state.can_choose_chapter_camp_event(i)
		button.custom_minimum_size = Vector2(0, 64)
		button.text = "%s｜%s\n%s" % [
			String(option.get("speaker", "")),
			String(option.get("title", "")),
			_short_line(state.chapter_camp_event_impact(option), 22),
		]
		button.icon = assets.card_textures.get(String(option.get("icon_key", "")), null) as Texture2D
		button.expand_icon = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var skills := state.chapter_camp_skill_rows()
	for skill_idx in range(_skill_buttons.size()):
		var skill_button := _skill_buttons[skill_idx]
		if skill_idx >= skills.size():
			skill_button.visible = false
			skill_button.disabled = true
			skill_button.set_meta("skill_id", "")
			continue
		var row: Dictionary = skills[skill_idx]
		skill_button.visible = true
		skill_button.disabled = false
		skill_button.set_meta("skill_id", String(row.get("id", "")))
		var equip_label := "装备" if bool(row.get("equipped", false)) else "待选"
		var learned_label := "新领悟" if bool(row.get("learned", false)) else "已掌握"
		skill_button.custom_minimum_size = Vector2(0, 58)
		skill_button.text = "%s｜%s\n%s｜费%d" % [
			equip_label,
			String(row.get("title", "")),
			"%s · %s" % [learned_label, _short_line(String(row.get("text", "")), 26)],
			int(row.get("cost", 0)),
		]
		skill_button.icon = assets.card_textures.get(String(row.get("kind", "")), null) as Texture2D
		skill_button.expand_icon = true
		skill_button.alignment = HORIZONTAL_ALIGNMENT_LEFT


func _sync_complete() -> void:
	complete_layer.visible = state.chapter_phase == "complete"
	if not complete_layer.visible:
		return
	complete_battle_label.text = "战线｜%s" % state.chapter_battle_summary()
	complete_reward_label.text = "领悟｜%s" % state.chapter_reward_summary()
	complete_camp_label.text = "羁绊｜%s" % state.chapter_camp_summary()
	complete_promotion_label.text = "成长｜%s" % state.promotion_confirmation_title()
	complete_note_label.text = state.promotion_confirmation_note() if state.has_next_chapter() else state.chapter_next_step_summary()
	next_chapter_button.visible = state.has_next_chapter()


func _node_status_text(node: Dictionary) -> String:
	var status := String(node.get("status", "locked"))
	if status == "completed":
		return "已完成"
	if status == "current":
		return "当前目标"
	return "未解锁"


func _node_status_color(status: String, is_boss: bool) -> Color:
	if status == "completed":
		return Color("#8fffd8")
	if status == "current":
		return Color("#fff4ba")
	if is_boss:
		return Color("#ff6685")
	return Color("#b7caef")


func _short_line(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, maxi(1, max_chars - 1)) + "…"


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
	for child in node.get_children():
		_configure_text_constraints(child)
