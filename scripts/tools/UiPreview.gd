@tool
class_name UiPreview
extends Control

const BattleAssetsScript := preload("res://scripts/core/BattleAssets.gd")
const BattleLayoutScript := preload("res://scripts/core/BattleLayout.gd")
const BattleStateScript := preload("res://scripts/core/BattleState.gd")
const BattleHudRootScript := preload("res://scripts/ui/BattleHudRoot.gd")
const BattleOverlayRootScript := preload("res://scripts/ui/BattleOverlayRoot.gd")
const ChapterFlowRootScript := preload("res://scripts/ui/ChapterFlowRoot.gd")

@export_enum("battle", "intro", "reward", "result", "promotion", "chapter_map", "complete") var preview_phase := "battle":
	set(value):
		preview_phase = value
		_refresh_preview()

@export var show_camp_detail := true:
	set(value):
		show_camp_detail = value
		_refresh_preview()

@export_range(0, 2, 1) var selected_unit_index := 0:
	set(value):
		selected_unit_index = value
		_refresh_preview()

@onready var board_guide: ColorRect = $BoardGuide
@onready var board_label: Label = $BoardGuide/Label
@onready var phase_label: Label = $PhaseLabel
@onready var battle_hud_root: BattleHudRootScript = $UiCanvas/BattleHudRoot
@onready var battle_overlay_root: BattleOverlayRootScript = $UiCanvas/BattleOverlayRoot
@onready var chapter_flow_root: ChapterFlowRootScript = $UiCanvas/ChapterFlowRoot

var assets = BattleAssetsScript.new()
var layout = BattleLayoutScript.new()
var state = BattleStateScript.new()
var _assets_loaded := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not _assets_loaded:
		assets.load_all()
		_assets_loaded = true
	_refresh_preview()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_refresh_preview")


func _refresh_preview() -> void:
	if not is_inside_tree():
		return
	if battle_hud_root == null or battle_overlay_root == null or chapter_flow_root == null:
		return
	if not _assets_loaded:
		assets.load_all()
		_assets_loaded = true
	state = BattleStateScript.new()
	state.setup()
	match preview_phase:
		"intro":
			_prepare_intro_preview()
		"battle":
			_prepare_battle_preview()
		"reward":
			_prepare_reward_preview()
		"result":
			_prepare_result_preview()
		"promotion":
			_prepare_promotion_preview()
		"chapter_map":
			_prepare_chapter_map_preview()
		"complete":
			_prepare_complete_preview()
	layout.update(get_rect().size, state.hand.size())
	_bind_roots()
	_sync_guides()


func _prepare_intro_preview() -> void:
	state.start_run()


func _prepare_battle_preview() -> void:
	state.begin_chapter_battle()
	_select_preview_unit()


func _prepare_reward_preview() -> void:
	state.begin_chapter_battle()
	state.victory = true
	state.phase = "done"
	state.chapter_phase = "reward"
	state.generate_reward_options()


func _prepare_result_preview() -> void:
	state.begin_chapter_battle()
	state.battle_in_chapter = state.chapter_encounter_count()
	state.victory = true
	state.phase = "done"
	state.chapter_phase = "reward"
	state.generate_reward_options()
	if not state.reward_options.is_empty():
		state.claim_reward(0)


func _prepare_promotion_preview() -> void:
	state.begin_chapter_battle()
	for member in state.party:
		member["level"] = 10
	state.battle_in_chapter = state.chapter_encounter_count()
	state.start_promotion()


func _prepare_chapter_map_preview() -> void:
	state.begin_chapter_battle()
	state.generate_reward_options()
	if not state.reward_options.is_empty():
		state.claim_reward(0)
		state.start_next_battle()
	if show_camp_detail:
		state.open_chapter_camp()


func _prepare_complete_preview() -> void:
	state.begin_chapter_battle()
	for member in state.party:
		member["level"] = 10
	state.battle_in_chapter = state.chapter_encounter_count()
	state.start_promotion()
	if not state.promotion_options.is_empty():
		state.claim_promotion(0)


func _select_preview_unit() -> void:
	var players := state.get_player_units()
	if players.is_empty():
		return
	var index := clampi(selected_unit_index, 0, players.size() - 1)
	var unit: Dictionary = players[index]
	state.selected_unit_uid = String(unit.get("uid", ""))
	state.action_mode = "command"
	state.moved_this_action = true
	state.focus_character_uid(String(unit.get("uid", "")))
	state.sync_active_hand()


func _bind_roots() -> void:
	battle_hud_root.state = state
	battle_hud_root.assets = assets
	battle_hud_root.layout = layout
	battle_overlay_root.state = state
	battle_overlay_root.assets = assets
	battle_overlay_root.layout = layout
	chapter_flow_root.state = state
	chapter_flow_root.assets = assets
	chapter_flow_root.layout = layout
	battle_hud_root.sync()
	battle_overlay_root.sync()
	chapter_flow_root.sync()


func _sync_guides() -> void:
	board_guide.visible = preview_phase == "battle"
	if board_guide.visible:
		board_guide.position = layout.board_rect.position
		board_guide.size = layout.board_rect.size
		board_label.text = "棋盘参考区"
	phase_label.text = "UI 预览｜%s" % _phase_label()


func _phase_label() -> String:
	match preview_phase:
		"intro":
			return "开场对白"
		"reward":
			return "奖励选择"
		"result":
			return "战斗结算"
		"promotion":
			return "转职选择"
		"chapter_map":
			return "章节地图 / 营地"
		"complete":
			return "章节完成"
	return "战斗 HUD"
