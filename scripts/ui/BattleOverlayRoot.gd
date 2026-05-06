@tool
class_name BattleOverlayRoot
extends Control

const BattleLayoutScript := preload("res://scripts/core/BattleLayout.gd")

signal intro_advance_requested
signal next_battle_requested
signal deck_toggle_requested
signal reward_claim_requested(index: int)
signal promotion_claim_requested(index: int)

@onready var intro_layer: Control = $IntroLayer
@onready var intro_background: TextureRect = $IntroLayer/Background
@onready var intro_portrait: TextureRect = $IntroLayer/Portrait
@onready var intro_dialogue_panel: PanelContainer = $IntroLayer/DialoguePanel
@onready var intro_name_label: Label = $IntroLayer/DialoguePanel/Margin/VBox/Speaker
@onready var intro_text_label: RichTextLabel = $IntroLayer/DialoguePanel/Margin/VBox/Text
@onready var intro_hint_label: Label = $IntroLayer/DialoguePanel/Margin/VBox/Hint
@onready var result_layer: Control = $ResultLayer
@onready var result_panel: PanelContainer = $ResultLayer/ResultPanel
@onready var result_title_label: Label = $ResultLayer/ResultPanel/Margin/VBox/Title
@onready var result_grade_label: Label = $ResultLayer/ResultPanel/Margin/VBox/Grade
@onready var result_summary_label: Label = $ResultLayer/ResultPanel/Margin/VBox/Summary
@onready var result_note_label: Label = $ResultLayer/ResultPanel/Margin/VBox/Note
@onready var result_exp_label: Label = $ResultLayer/ResultPanel/Margin/VBox/Exp
@onready var result_confirmation_panel: PanelContainer = $ResultLayer/ResultPanel/Margin/VBox/Confirmation
@onready var result_confirm_title_label: Label = $ResultLayer/ResultPanel/Margin/VBox/Confirmation/Margin/VBox/Title
@onready var result_confirm_note_label: Label = $ResultLayer/ResultPanel/Margin/VBox/Confirmation/Margin/VBox/Note
@onready var next_battle_button: Button = $ResultLayer/ResultPanel/Margin/VBox/Buttons/NextBattle
@onready var deck_toggle_button: Button = $ResultLayer/ResultPanel/Margin/VBox/Buttons/DeckToggle
@onready var reward_layer: Control = $RewardLayer
@onready var reward_panel: PanelContainer = $RewardLayer/RewardPanel
@onready var reward_cards: HBoxContainer = $RewardLayer/RewardPanel/Margin/VBox/Cards
@onready var reward_subtitle_label: Label = $RewardLayer/RewardPanel/Margin/VBox/Subtitle
@onready var promotion_layer: Control = $PromotionLayer
@onready var promotion_panel: PanelContainer = $PromotionLayer/PromotionPanel
@onready var promotion_seal_label: Label = $PromotionLayer/PromotionPanel/Margin/VBox/SealInfo
@onready var promotion_cards: GridContainer = $PromotionLayer/PromotionPanel/Margin/VBox/Cards

var state: BattleState
var assets: BattleAssets
var layout = BattleLayoutScript.new()
var _reward_buttons: Array[Button] = []
var _promotion_buttons: Array[Button] = []
const REWARD_CARD_SIZE := Vector2(292, 168)
const REWARD_CARD_CONTENT_INSET := Rect2(30, 22, 60, 44)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_connect_buttons()
	_collect_dynamic_buttons()
	_configure_text_constraints(self)


func sync() -> void:
	if state == null or assets == null or layout == null:
		visible = false
		return
	visible = true
	_apply_layout()
	_sync_intro()
	_sync_result()
	_sync_reward()
	_sync_promotion()


func _apply_layout() -> void:
	var view_size := get_viewport_rect().size
	var bottom_gap := clampf(view_size.y * 0.04, 22.0, 36.0)
	var dialogue_size := Vector2(
		minf(900.0, view_size.x - 120.0),
		clampf(view_size.y * 0.22, 136.0, 166.0)
	)
	_update_rect(
		intro_dialogue_panel,
		Rect2(Vector2((view_size.x - dialogue_size.x) * 0.5, view_size.y - dialogue_size.y - bottom_gap), dialogue_size)
	)
	var portrait_height := minf(560.0, view_size.y - bottom_gap - 52.0)
	var portrait_width := clampf(portrait_height * 0.62, 260.0, 360.0)
	_update_rect(
		intro_portrait,
		Rect2(Vector2(clampf(view_size.x * 0.055, 42.0, 82.0), maxf(56.0, intro_dialogue_panel.position.y - portrait_height + 54.0)), Vector2(portrait_width, portrait_height))
	)
	var result_size := Vector2(minf(560.0, view_size.x - 160.0), minf(318.0, view_size.y - 140.0))
	var reward_size := Vector2(minf(740.0, view_size.x - 150.0), minf(366.0, view_size.y - 132.0))
	var promotion_size := Vector2(minf(744.0, view_size.x - 140.0), minf(408.0, view_size.y - 118.0))
	_update_rect(result_panel, _center_rect(view_size, result_size))
	_update_rect(reward_panel, _center_rect(view_size, reward_size))
	_update_rect(promotion_panel, _center_rect(view_size, promotion_size))


func _center_rect(view_size: Vector2, size: Vector2) -> Rect2:
	return Rect2((view_size - size) * 0.5, size)


func _connect_buttons() -> void:
	intro_layer.gui_input.connect(_on_intro_gui_input)
	next_battle_button.pressed.connect(func() -> void: next_battle_requested.emit())
	deck_toggle_button.pressed.connect(func() -> void: deck_toggle_requested.emit())


func _collect_dynamic_buttons() -> void:
	_reward_buttons.clear()
	for child in reward_cards.get_children():
		if child is Button:
			var button := child as Button
			_reward_buttons.append(button)
			_configure_reward_card_button(button)
			var index := _reward_buttons.size() - 1
			button.pressed.connect(func() -> void:
				reward_claim_requested.emit(index)
			)
	_promotion_buttons.clear()
	for child in promotion_cards.get_children():
		if child is Button:
			var promotion_button := child as Button
			_promotion_buttons.append(promotion_button)
			var option_index := _promotion_buttons.size() - 1
			promotion_button.pressed.connect(func() -> void:
				promotion_claim_requested.emit(option_index)
			)


func _sync_intro() -> void:
	intro_layer.visible = state.chapter_phase == "intro"
	if not intro_layer.visible:
		return
	intro_background.texture = assets.dialogue_background_texture(state.current_dialogue_background_id())
	intro_portrait.texture = assets.portrait_textures.get(state.current_dialogue_portrait_id(), null) as Texture2D
	var line := state.current_dialogue_line()
	intro_name_label.text = String(line.get("speaker", ""))
	intro_text_label.text = String(line.get("text", ""))
	intro_hint_label.text = "点击继续"


func _sync_result() -> void:
	var show_result := (state.victory or state.defeat) and not (state.chapter_phase in ["promotion", "complete", "chapter_map", "intro"])
	if state.victory and not state.reward_claimed and state.reward_options.size() > 0:
		show_result = false
	result_layer.visible = show_result
	if not result_layer.visible:
		return
	result_title_label.text = "胜利" if state.victory else "战败"
	result_grade_label.text = "战斗评价  %s" % state.battle_grade()
	result_summary_label.text = state.battle_result_summary()
	result_note_label.text = state.battle_result_note()
	result_exp_label.text = state.battle_exp_summary()
	var confirmed := state.victory and state.reward_claimed and state.chapter_phase == "reward"
	result_confirmation_panel.visible = confirmed
	next_battle_button.visible = confirmed
	deck_toggle_button.visible = confirmed
	if confirmed:
		result_confirm_title_label.text = state.reward_confirmation_title()
		result_confirm_note_label.text = state.reward_confirmation_note()
		next_battle_button.text = "选择转职" if state.battle_in_chapter >= state.chapter_encounter_count() else "前往章节地图"
		deck_toggle_button.text = "收起技能" if state.deck_view_open else "查看技能"


func _sync_reward() -> void:
	reward_layer.visible = state.chapter_phase == "reward" and state.victory and not state.reward_claimed
	if not reward_layer.visible:
		return
	reward_subtitle_label.text = "选择一项战后收获，加入角色成长。"
	reward_cards.add_theme_constant_override("separation", 18)
	for i in range(_reward_buttons.size()):
		var button := _reward_buttons[i]
		_configure_reward_card_button(button)
		if i >= state.reward_options.size():
			button.visible = false
			button.disabled = true
			button.text = ""
			button.icon = null
			_set_reward_card_labels(button, {})
			continue
		var reward: Dictionary = state.reward_options[i]
		button.visible = true
		button.disabled = false
		var owner_id := state.reward_owner_character_id(reward)
		button.text = ""
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.icon = null
		button.expand_icon = false
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_contents = true
		_set_reward_card_labels(button, _reward_card_label_data(reward, owner_id))


func _sync_promotion() -> void:
	promotion_layer.visible = state.chapter_phase == "promotion"
	if not promotion_layer.visible:
		return
	promotion_seal_label.text = "条件：Lv10 以上，并消耗 1 个转职纹章。剩余 %d" % state.promotion_seal_count()
	for i in range(_promotion_buttons.size()):
		var button := _promotion_buttons[i]
		if i >= state.promotion_options.size():
			button.visible = false
			button.disabled = true
			button.text = ""
			continue
		var option: Dictionary = state.promotion_options[i]
		var member := state._party_member_by_character_id(String(option.get("character_id", "")))
		button.visible = true
		button.disabled = false
		var character_id := String(option.get("character_id", ""))
		button.text = "%s\n%s\n%s\n%s\n条件：%s" % [
			state.character_name(String(option.get("character_id", ""))),
			String(option.get("name", "")),
			state.promotion_stat_summary(option),
			state.promotion_role_summary(option),
			state.promotion_requirement_text(member),
		]
		button.icon = assets.portrait_textures.get(character_id, null) as Texture2D
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _short_line(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, maxi(1, max_chars - 1)) + "…"


func _reward_card_label_data(reward: Dictionary, owner_id: String) -> Dictionary:
	var school := String(reward.get("school", "战术"))
	var tier := String(reward.get("tier", "基础"))
	var cost := int(reward.get("cost", 0))
	return {
		"Source": "%s 领悟" % state.character_name(owner_id),
		"Title": String(reward.get("title", "")),
		"Meta": "%s · %s" % [school, tier],
		"Effect": String(reward.get("text", "")),
		"Footer": "消耗 %d · 选择此项" % cost,
	}


func _set_reward_card_labels(button: Button, data: Dictionary) -> void:
	var label_names := ["Source", "Title", "Meta", "Effect", "Footer"]
	for label_name in label_names:
		var label := button.get_node_or_null("Content/VBox/%s" % label_name) as Label
		if label == null:
			continue
		label.text = String(data.get(label_name, ""))


func _configure_reward_card_button(button: Button) -> void:
	button.custom_minimum_size = REWARD_CARD_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.clip_contents = true
	button.text = ""
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 1)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 0))
	button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0))
	var glow := button.get_node_or_null("OilButtonGlow") as TextureRect
	if glow != null:
		glow.modulate = Color(1, 1, 1, 0.075)
		glow.offset_left = 0.0
		glow.offset_top = 0.0
		glow.offset_right = 0.0
		glow.offset_bottom = 0.0
	var content := button.get_node_or_null("Content") as MarginContainer
	if content != null:
		content.offset_left = REWARD_CARD_CONTENT_INSET.position.x
		content.offset_top = REWARD_CARD_CONTENT_INSET.position.y
		content.offset_right = -REWARD_CARD_CONTENT_INSET.size.x + REWARD_CARD_CONTENT_INSET.position.x
		content.offset_bottom = -REWARD_CARD_CONTENT_INSET.size.y + REWARD_CARD_CONTENT_INSET.position.y
		content.add_theme_constant_override("margin_left", 0)
		content.add_theme_constant_override("margin_top", 0)
		content.add_theme_constant_override("margin_right", 0)
		content.add_theme_constant_override("margin_bottom", 0)
	var vbox := button.get_node_or_null("Content/VBox") as VBoxContainer
	if vbox != null:
		vbox.add_theme_constant_override("separation", 2)
	_configure_reward_label(button, "Source", 16, 11, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER)
	_configure_reward_label(button, "Title", 27, 18, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER)
	_configure_reward_label(button, "Meta", 16, 11, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER)
	_configure_reward_label(button, "Effect", 48, 12, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART)
	_configure_reward_label(button, "Footer", 18, 11, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER)
	for decor_name in ["AccentBrush", "FooterDivider"]:
		var decor := button.get_node_or_null(decor_name) as CanvasItem
		if decor != null:
			decor.visible = false


func _configure_reward_label(
	button: Button,
	label_name: String,
	min_height: float,
	font_size: int,
	horizontal: HorizontalAlignment,
	vertical: VerticalAlignment,
	wrap_mode: TextServer.AutowrapMode = TextServer.AUTOWRAP_OFF
) -> void:
	var label := button.get_node_or_null("Content/VBox/%s" % label_name) as Label
	if label == null:
		return
	label.custom_minimum_size = Vector2(0, min_height)
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = horizontal
	label.vertical_alignment = vertical
	label.autowrap_mode = wrap_mode
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS


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


func _on_intro_gui_input(event: InputEvent) -> void:
	if not intro_layer.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		intro_advance_requested.emit()


func _update_rect(node: Control, rect: Rect2) -> void:
	node.position = rect.position
	node.size = rect.size
