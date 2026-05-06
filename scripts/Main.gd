extends Control

const BattleAssetsScript := preload("res://scripts/core/BattleAssets.gd")
const BattleLayoutScript := preload("res://scripts/core/BattleLayout.gd")
const BattleStateScript := preload("res://scripts/core/BattleState.gd")
const BattleHudRootScript := preload("res://scripts/ui/BattleHudRoot.gd")
const BattleOverlayRootScript := preload("res://scripts/ui/BattleOverlayRoot.gd")
const ChapterFlowRootScript := preload("res://scripts/ui/ChapterFlowRoot.gd")
const BattleAtmosphereLayerScript := preload("res://scripts/views/BattleAtmosphereLayer.gd")

@onready var battlefield_layer: Control = $BattlefieldLayer
@onready var battlefield_backdrop_layer = $BattlefieldBackdropLayer
@onready var battle_atmosphere_layer: BattleAtmosphereLayerScript = $BattleAtmosphereLayer
@onready var terrain_tile_map_layer: Node = $TerrainTileMapLayer
@onready var board_layer: BoardLayer = $BoardLayer
@onready var mounted_ui_layer: Control = $MountedUiLayer
@onready var ui_canvas: Control = $UiCanvas
@onready var battle_hud_root: BattleHudRootScript = $UiCanvas/BattleHudRoot
@onready var battle_overlay_root: BattleOverlayRootScript = $UiCanvas/BattleOverlayRoot
@onready var chapter_flow_root: ChapterFlowRootScript = $UiCanvas/ChapterFlowRoot
@onready var vfx_layer: VfxLayer = $VfxLayer
@onready var side_combat_layer: SideCombatLayer = $SideCombatLayer
@onready var sidebar_layer: SidebarLayer = $SidebarLayer
@onready var hand_layer: HandLayer = $HandLayer
@onready var overlay_layer: OverlayLayer = $OverlayLayer

var assets = BattleAssetsScript.new()
var layout = BattleLayoutScript.new()
var state = BattleStateScript.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	assets.load_all()
	state.setup()
	_bind_layers()
	_connect_ui_signals()
	_redraw_all()


func _process(delta: float) -> void:
	board_layer.anim_time += delta
	battle_atmosphere_layer.anim_time += delta
	if state.tick(delta):
		_redraw_all()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover_card(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_click(event.position)


func _bind_layers() -> void:
	battlefield_backdrop_layer.state = state
	battlefield_backdrop_layer.assets = assets
	battle_atmosphere_layer.state = state
	battle_atmosphere_layer.assets = assets
	battlefield_layer.state = state
	battlefield_layer.assets = assets
	terrain_tile_map_layer.state = state
	board_layer.state = state
	board_layer.assets = assets
	mounted_ui_layer.state = state
	mounted_ui_layer.assets = assets
	battle_hud_root.state = state
	battle_hud_root.assets = assets
	battle_overlay_root.state = state
	battle_overlay_root.assets = assets
	chapter_flow_root.state = state
	chapter_flow_root.assets = assets
	vfx_layer.state = state
	vfx_layer.assets = assets
	side_combat_layer.state = state
	side_combat_layer.assets = assets
	sidebar_layer.state = state
	sidebar_layer.assets = assets
	hand_layer.state = state
	hand_layer.assets = assets
	overlay_layer.state = state
	overlay_layer.assets = assets
	battlefield_backdrop_layer.layout = layout
	battle_atmosphere_layer.layout = layout
	battlefield_layer.layout = layout
	terrain_tile_map_layer.layout = layout
	board_layer.layout = layout
	mounted_ui_layer.layout = layout
	battle_hud_root.layout = layout
	battle_overlay_root.layout = layout
	chapter_flow_root.layout = layout
	vfx_layer.layout = layout
	side_combat_layer.layout = layout
	sidebar_layer.layout = layout
	hand_layer.layout = layout
	overlay_layer.layout = layout
	overlay_layer.show_battle_prompt_cards = false
	overlay_layer.show_flow_panels = false


func _connect_ui_signals() -> void:
	battle_hud_root.restart_requested.connect(func() -> void:
		state.start_run()
		_redraw_all()
	)
	battle_hud_root.log_toggle_requested.connect(func() -> void:
		state.toggle_log()
		_redraw_all()
	)
	battle_hud_root.cycle_character_requested.connect(func(step: int) -> void:
		state.cycle_character_panel(step)
		_redraw_all()
	)
	battle_hud_root.undo_move_requested.connect(func() -> void:
		if state.undo_selected_move(board_layer.board_rect):
			_redraw_all()
	)
	battle_hud_root.end_turn_requested.connect(func() -> void:
		_on_end_turn_requested()
	)
	battle_hud_root.skill_page_requested.connect(func(step: int) -> void:
		state.cycle_skill_page(step, battle_hud_root.visible_skill_count())
		_redraw_all()
	)
	battle_hud_root.skill_selected.connect(func(skill_index: int, skill_id: String) -> void:
		if state.reject_tutorial_action("attack_or_skill", {"skill_id": skill_id}):
			_redraw_all()
			return
		state.select_card(skill_index, [], 0)
		_redraw_all()
	)
	battle_overlay_root.intro_advance_requested.connect(func() -> void:
		state.advance_intro()
		_redraw_all()
	)
	battle_overlay_root.next_battle_requested.connect(func() -> void:
		state.start_next_battle()
		_redraw_all()
	)
	battle_overlay_root.deck_toggle_requested.connect(func() -> void:
		state.toggle_deck_view()
		_redraw_all()
	)
	battle_overlay_root.reward_claim_requested.connect(func(index: int) -> void:
		state.claim_reward(index)
		_redraw_all()
	)
	battle_overlay_root.promotion_claim_requested.connect(func(index: int) -> void:
		state.claim_promotion(index)
		_redraw_all()
	)
	chapter_flow_root.chapter_node_requested.connect(func(node_index: int) -> void:
		if state.can_enter_chapter_map_node(node_index):
			state.start_next_battle()
			_redraw_all()
	)
	chapter_flow_root.camp_member_selected.connect(func(character_id: String) -> void:
		state.select_chapter_camp_member(character_id)
		_redraw_all()
	)
	chapter_flow_root.camp_close_requested.connect(func() -> void:
		state.close_chapter_camp()
		_redraw_all()
	)
	chapter_flow_root.camp_rest_requested.connect(func() -> void:
		state.use_chapter_camp_rest()
		_redraw_all()
	)
	chapter_flow_root.camp_deploy_requested.connect(func(character_id: String) -> void:
		state.toggle_chapter_camp_deployment(character_id)
		_redraw_all()
	)
	chapter_flow_root.camp_event_requested.connect(func(option_index: int) -> void:
		state.choose_chapter_camp_event(option_index)
		_redraw_all()
	)
	chapter_flow_root.camp_skill_requested.connect(func(skill_id: String) -> void:
		state.equip_chapter_camp_skill(skill_id)
		_redraw_all()
	)
	chapter_flow_root.next_chapter_requested.connect(func() -> void:
		state.start_next_chapter()
		_redraw_all()
	)


func _redraw_all() -> void:
	layout.update(get_viewport_rect().size, state.hand.size())
	battlefield_backdrop_layer.sync()
	battle_atmosphere_layer.sync()
	terrain_tile_map_layer.sync()
	mounted_ui_layer.sync()
	battle_hud_root.sync()
	battle_overlay_root.sync()
	chapter_flow_root.sync()
	sidebar_layer.visible = false
	hand_layer.visible = false
	overlay_layer.visible = false
	battlefield_layer.queue_redraw()
	battle_atmosphere_layer.queue_redraw()
	board_layer.queue_redraw()
	vfx_layer.queue_redraw()
	side_combat_layer.queue_redraw()
	if sidebar_layer.visible:
		sidebar_layer.queue_redraw()
	if hand_layer.visible:
		hand_layer.queue_redraw()


func _update_hover_card(pos: Vector2) -> void:
	var next_hover := -1
	var next_tile := Vector2i(-1, -1)
	if board_layer.board_rect.has_point(pos):
		next_tile = state.screen_to_tile(pos, board_layer.board_rect)
	if next_hover != state.hover_card:
		state.hover_card = next_hover
		_redraw_all()
	if next_tile != state.hover_tile:
		if next_tile.x >= 0:
			state.set_hover_tile(next_tile)
		else:
			state.clear_hover_tile()
		_redraw_all()


func _handle_click(pos: Vector2) -> void:
	if state.chapter_phase in ["intro", "reward", "promotion", "chapter_map", "complete"]:
		return
	if not battle_hud_root.visible and sidebar_layer.restart_rect.has_point(pos):
		state.start_run()
		_redraw_all()
		return
	if not battle_hud_root.visible and sidebar_layer.log_toggle_rect.has_point(pos):
		state.toggle_log()
		_redraw_all()
		return
	if not battle_hud_root.visible and sidebar_layer.character_prev_rect.has_point(pos):
		state.cycle_character_panel(-1)
		_redraw_all()
		return
	if not battle_hud_root.visible and sidebar_layer.character_next_rect.has_point(pos):
		state.cycle_character_panel(1)
		_redraw_all()
		return
	if state.victory or state.defeat or state.phase != "player":
		return
	if not battle_hud_root.visible and sidebar_layer.undo_move_rect.has_point(pos):
		if state.undo_selected_move(board_layer.board_rect):
			_redraw_all()
		return
	if not battle_hud_root.visible and hand_layer.prev_page_rect.has_point(pos):
		state.cycle_skill_page(-1, hand_layer.visible_skill_count)
		_redraw_all()
		return
	if not battle_hud_root.visible and hand_layer.next_page_rect.has_point(pos):
		state.cycle_skill_page(1, hand_layer.visible_skill_count)
		_redraw_all()
		return
	if not battle_hud_root.visible:
		for i in range(hand_layer.hand_rects.size()):
			if hand_layer.hand_rects[i].has_point(pos):
				var skill_index := hand_layer.skill_index_for_rect(i)
				var clicked_skill_id := ""
				if skill_index >= 0 and skill_index < state.hand.size():
					clicked_skill_id = String(state.hand[skill_index].get("id", ""))
				if state.reject_tutorial_action("attack_or_skill", {"skill_id": clicked_skill_id}):
					_redraw_all()
					return
				state.select_card(skill_index, hand_layer.hand_rects, i)
				_redraw_all()
				return
	if not battle_hud_root.visible and sidebar_layer.end_turn_rect.has_point(pos):
		if state.reject_tutorial_action("end_turn"):
			_redraw_all()
			return
		if state.selected_unit_uid != "":
			state.wait_selected_unit()
			_redraw_all()
			if state.phase == "enemy":
				await _continue_enemy_turn()
		else:
			await _end_player_turn()
		return
	if board_layer.board_rect.has_point(pos):
		var tile := state.screen_to_tile(pos, board_layer.board_rect)
		if tile.x < 0:
			state.clear_hover_tile()
			state.clear_focused_enemy()
			_redraw_all()
			return
		var clicked_enemy = state.enemy_at(tile)
		if clicked_enemy != null and state.selected_unit_uid == "" and state.selected_card < 0:
			state.focus_enemy_at(tile)
			state.set_hover_tile(tile)
			_redraw_all()
			return
		if clicked_enemy == null:
			state.clear_focused_enemy()
		if state.selected_card >= 0:
			var selected_skill_id := ""
			if state.selected_card < state.hand.size():
				selected_skill_id = String(state.hand[state.selected_card].get("id", ""))
			if state.reject_tutorial_action("attack_or_skill", {"tile": tile, "skill_id": selected_skill_id}):
				_redraw_all()
				return
			if not state.handle_card_board_click(tile, board_layer.board_rect):
				state.reject_invalid_tutorial_target("attack_or_skill")
		elif state.selected_unit_uid == "":
			var unit = state.unit_at(tile)
			var character_id := ""
			if unit != null:
				character_id = String(unit.get("character_id", ""))
			if state.reject_tutorial_action("select_unit", {"tile": tile, "character_id": character_id}):
				_redraw_all()
				return
			if not state.select_unit_at(tile):
				state.reject_invalid_tutorial_target("select_unit")
		else:
			var input_action := "attack_or_skill" if state.action_mode == "command" and state.enemy_at(tile) != null else "move_or_wait"
			if state.reject_tutorial_action(input_action, {"tile": tile}):
				_redraw_all()
				return
			if not state.act_on_tile(tile, board_layer.board_rect):
				state.reject_invalid_tutorial_target(input_action)
		state.clear_hover_tile()
		_redraw_all()
		if state.phase == "enemy":
			await _continue_enemy_turn()


func _on_end_turn_requested() -> void:
	if state.reject_tutorial_action("end_turn"):
		_redraw_all()
		return
	if state.selected_unit_uid != "":
		state.wait_selected_unit()
		_redraw_all()
		if state.phase == "enemy":
			await _continue_enemy_turn()
		return
	await _end_player_turn()


func _end_player_turn() -> void:
	state.end_player_turn()
	await _continue_enemy_turn()


func _continue_enemy_turn() -> void:
	_redraw_all()
	await get_tree().create_timer(0.35).timeout
	await _enemy_turn()


func _enemy_turn() -> void:
	if state.victory or state.defeat:
		return
	for enemy in state.get_enemy_units():
		if enemy["hp"] <= 0:
			continue
		state.prepare_enemy_step(enemy)
		_redraw_all()
		await get_tree().create_timer(0.26).timeout
		state.run_enemy_step(enemy, board_layer.board_rect)
		state.check_end_state()
		_redraw_all()
		if state.victory or state.defeat:
			return
		await get_tree().create_timer(state.enemy_step_pause(enemy)).timeout
	state.finish_enemy_turn()
	_redraw_all()
