extends SceneTree

const BattleStateScript := preload("res://scripts/core/BattleState.gd")

var errors: Array[String] = []


func _init() -> void:
	_check_personal_skill_menus()
	_check_dialogue_background_ids()
	_check_battlefield_background_path()
	_check_isometric_projection_roundtrip()
	_check_move_undo()
	_check_range_two_attack()
	_check_normal_attack_ends_action()
	_check_skill_ends_action()
	_check_dash_skill_ends_action()
	_check_already_acted_unit_cannot_use_skill()
	_check_skill_ownership()
	_check_attack_prediction_matches_resolution()
	_check_blocked_attack_preview()
	_check_tutorial_progression()
	_check_second_battle_tutorial_skill_gate()
	_check_second_battle_tutorial_recommendations()
	_check_tutorial_invalid_target_feedback()
	_check_tutorial_completion_objective()
	_check_first_battle_followup_pacing()
	_check_first_battle_enemy_prefers_frontliner()
	_check_terrain_effects()
	_check_chapter_two_terrain_overrides()
	_check_enemy_terrain_movement_preferences()
	_check_block_damage_feedback()
	_check_enemy_hover_forecast()
	_check_enemy_hover_terrain_intents()
	_check_skill_action_hints()
	_check_level_exp_progression()
	_check_vfx_impact_timing()
	_check_skill_effect_impact_timing()
	_check_boss_action_sheet_key()
	_check_reward_pick_feedback()
	_check_permanent_death_rules()
	_check_active_skill_limit()
	_check_promotion_choice_feedback()
	_check_chapter_completion_summary()
	_check_chapter_map_party_rows()
	_check_chapter_one_mvp_loop()
	_check_start_second_chapter()
	_check_recruitment_survive_join()
	_check_reach_objective_victory()
	_print_result()
	quit(1 if not errors.is_empty() else 0)


func _fresh_state():
	var state = BattleStateScript.new()
	state.setup()
	_enter_first_battle(state)
	return state


func _enter_first_battle(state) -> void:
	state.advance_intro()
	state.advance_intro()
	state.advance_intro()
	if state.chapter_phase != "battle":
		_add_error("Expected first battle after intro.")


func _check_dialogue_background_ids() -> void:
	var state = BattleStateScript.new()
	state.setup()
	if state.current_dialogue_background_id() != "chapter1_sanctuary_terrace":
		_add_error("Chapter 1 dialogue background id is incorrect.")
	state.advance_intro()
	state.advance_intro()
	state.advance_intro()
	state.chapter_index = 2
	state.chapter_phase = "intro"
	state.intro_dialogue_index = 0
	if state.current_dialogue_background_id() != "chapter2_west_corridor":
		_add_error("Chapter 2 dialogue background id is incorrect.")


func _check_battlefield_background_path() -> void:
	var state = _fresh_state()
	if state.current_battlefield_background_path() != "res://assets/art/battlefield-japanese-oil-courtyard-v3-1280x720.png":
		_add_error("Chapter 1 battle background path is incorrect.")
	state.battle_in_chapter = 2
	state.battle_index = 2
	state._start_battle()
	if state.current_battlefield_background_path() != "res://assets/art/battlefield-japanese-oil-courtyard-v3-1280x720.png":
		_add_error("Chapter 1 second battle background path is incorrect.")
	_enter_second_chapter_first_battle(state)
	if state.current_battlefield_background_path() != "res://assets/art/battlefield-japanese-oil-west-corridor-v1-1280x720.png":
		_add_error("Chapter 2 battle background path is incorrect.")
	_force_win_current_battle(state)
	state.claim_reward(0)
	_continue_from_reward_to_chapter_map(state, "battlefield background chapter 2")
	state.start_next_battle()
	if state.current_battlefield_background_path() != "res://assets/art/battlefield-japanese-oil-west-corridor-v1-1280x720.png":
		_add_error("Chapter 2 second battle background path is incorrect.")


func _check_isometric_projection_roundtrip() -> void:
	var state = _fresh_state()
	var board_rect := Rect2(Vector2(64, 96), Vector2(720, 360))
	for y in range(BattleStateScript.GRID_H):
		for x in range(BattleStateScript.GRID_W):
			var tile := Vector2i(x, y)
			var center := state.tile_rect(tile, board_rect).get_center()
			var hit := state.screen_to_tile(center, board_rect)
			if hit != tile:
				_add_error("Isometric projection roundtrip failed for %s; got %s." % [str(tile), str(hit)])
				return
	var outside := state.screen_to_tile(Vector2(board_rect.position.x - 48.0, board_rect.position.y - 48.0), board_rect)
	if outside != Vector2i(-1, -1):
		_add_error("Isometric projection should reject points outside the board diamond.")


func _check_personal_skill_menus() -> void:
	var state = _fresh_state()
	if not _hand_has_exactly(state, ["crest_resonance"]):
		_add_error("Initial skill menu is not Astra's focused learned list.")
	state.cycle_character_panel(1)
	if state.active_card_character_id() != "liora":
		_add_error("Panel did not switch active skill menu to Liora.")
	if not _hand_has_exactly(state, ["mend_light"]):
		_add_error("Liora skill menu contains another character's skill.")
	var kael: Dictionary = _unit_by_character(state, "kael")
	if kael.is_empty() or not state.select_unit_at(kael["pos"]):
		_add_error("Could not select Kael.")
		return
	if state.active_card_character_id() != "kael":
		_add_error("Selected unit did not switch active skill menu.")
	if not _hand_has_exactly(state, ["guard_bloom"]):
		_add_error("Kael skill menu contains another character's skill.")


func _check_move_undo() -> void:
	var state = _fresh_state()
	var liora: Dictionary = _unit_by_character(state, "liora")
	if liora.is_empty():
		_add_error("Liora missing.")
		return
	var original_pos: Vector2i = liora["pos"]
	if not state.select_unit_at(original_pos):
		_add_error("Could not select Liora for undo check.")
		return
	var move_target := Vector2i(0, 4)
	if not state.act_on_tile(move_target, Rect2()):
		_add_error("Liora could not move to test tile.")
		return
	if not state.can_undo_selected_move():
		_add_error("Move undo was not enabled after movement.")
		return
	if not state.undo_selected_move(Rect2()):
		_add_error("Move undo failed.")
		return
	if liora["pos"] != original_pos:
		_add_error("Move undo did not restore position.")
	if state.action_mode != "move":
		_add_error("Move undo did not return to move selection.")


func _check_range_two_attack() -> void:
	var state = _fresh_state()
	var liora: Dictionary = _unit_by_character(state, "liora")
	var enemy: Dictionary = _first_enemy(state)
	if liora.is_empty() or enemy.is_empty():
		_add_error("Missing units for range check.")
		return
	liora["pos"] = Vector2i(5, 4)
	enemy["pos"] = Vector2i(7, 4)
	state.selected_unit_uid = liora["uid"]
	state.action_mode = "command"
	if not state.attack_tiles_for_selected().has(enemy["pos"]):
		_add_error("Range 2 attack did not include target at distance 2.")


func _check_normal_attack_ends_action() -> void:
	var state = _fresh_state()
	var astra: Dictionary = _unit_by_character(state, "astra")
	var enemy: Dictionary = _first_enemy(state)
	if astra.is_empty() or enemy.is_empty():
		_add_error("Missing units for normal attack check.")
		return
	astra["pos"] = enemy["pos"] + Vector2i.LEFT
	if not state.select_unit_at(astra["pos"]):
		_add_error("Could not select Astra for normal attack.")
		return
	state.act_on_tile(astra["pos"], Rect2())
	if not state.act_on_tile(enemy["pos"], Rect2()):
		_add_error("Normal attack did not resolve.")
		return
	if not bool(astra.get("acted", false)):
		_add_error("Normal attack did not mark unit acted.")
	if state.selected_unit_uid != "":
		_add_error("Normal attack did not clear selected unit.")
	if state.select_unit_at(astra["pos"]):
		_add_error("Already acted unit could be selected again after normal attack.")


func _check_skill_ends_action() -> void:
	var state = _fresh_state()
	var kael: Dictionary = _unit_by_character(state, "kael")
	if kael.is_empty():
		_add_error("Kael missing for skill action check.")
		return
	if not _enter_command_for_unit(state, kael):
		return
	if not _select_skill_by_id(state, "guard_bloom"):
		_add_error("Could not select Kael guard skill.")
		return
	if not state.handle_card_board_click(kael["pos"], Rect2()):
		_add_error("Guard skill did not resolve.")
		return
	if not bool(kael.get("acted", false)):
		_add_error("Skill did not mark unit acted.")
	if state.selected_unit_uid != "" or state.selected_card != -1:
		_add_error("Skill did not clear command selection.")


func _check_dash_skill_ends_action() -> void:
	var state = _fresh_state()
	var kael: Dictionary = _unit_by_character(state, "kael")
	var enemy: Dictionary = _first_enemy(state)
	if kael.is_empty() or enemy.is_empty():
		_add_error("Missing units for dash skill check.")
		return
	state.learn_skill_reward(state.content.create_card("aegis_step"))
	if not _enter_command_for_unit(state, kael):
		return
	if not _select_skill_by_id(state, "aegis_step"):
		_add_error("Could not select Aegis Step.")
		return
	var target_tile := Vector2i(2, 3)
	if not state.handle_card_board_click(target_tile, Rect2()):
		_add_error("Dash skill did not resolve.")
		return
	if kael["pos"] != target_tile:
		_add_error("Dash skill did not move the unit.")
	if not bool(kael.get("acted", false)):
		_add_error("Dash skill did not mark unit acted.")
	if state.select_unit_at(kael["pos"]):
		_add_error("Dash skill allowed unit to act again.")
	state.selected_unit_uid = kael["uid"]
	state.action_mode = "command"
	if state.act_on_tile(enemy["pos"], Rect2()):
		_add_error("Dash skill allowed a follow-up attack.")


func _check_already_acted_unit_cannot_use_skill() -> void:
	var state = _fresh_state()
	var astra: Dictionary = _unit_by_character(state, "astra")
	if astra.is_empty():
		_add_error("Astra missing for acted skill check.")
		return
	astra["acted"] = true
	state.selected_unit_uid = astra["uid"]
	state.action_mode = "command"
	state.select_skill(0)
	if state.selected_card != -1:
		_add_error("Already acted unit could select a skill.")


func _check_skill_ownership() -> void:
	var state = _fresh_state()
	var liora: Dictionary = _unit_by_character(state, "liora")
	if liora.is_empty():
		_add_error("Liora missing for ownership check.")
		return
	if not _enter_command_for_unit(state, liora):
		return
	state.selected_card_owner_id = "astra"
	state.select_skill(0)
	if state.selected_card != -1:
		_add_error("A unit could select a skill owned by another character.")


func _check_attack_prediction_matches_resolution() -> void:
	var state = _fresh_state()
	var astra: Dictionary = _unit_by_character(state, "astra")
	var enemy: Dictionary = _first_enemy(state)
	if astra.is_empty() or enemy.is_empty():
		_add_error("Missing units for prediction check.")
		return
	astra["pos"] = enemy["pos"] + Vector2i.LEFT
	enemy["block"] = 2
	if not state.select_unit_at(astra["pos"]):
		_add_error("Could not select Astra for prediction check.")
		return
	state.act_on_tile(astra["pos"], Rect2())
	var preview: Dictionary = state.normal_attack_preview(enemy["pos"])
	if preview.is_empty() or not bool(preview.get("valid", false)):
		_add_error("Normal attack prediction was not valid.")
		return
	var expected_hp: int = int(preview.get("after", -1))
	var expected_damage: int = int(preview.get("amount", -1))
	if not state.act_on_tile(enemy["pos"], Rect2()):
		_add_error("Predicted attack did not resolve.")
		return
	if int(enemy["hp"]) != expected_hp:
		_add_error("Attack prediction HP mismatch. Expected %d got %d." % [expected_hp, int(enemy["hp"])])
	if expected_damage != 2:
		_add_error("Attack prediction damage mismatch. Expected 2 got %d." % expected_damage)


func _check_blocked_attack_preview() -> void:
	var state = _fresh_state()
	var astra: Dictionary = _unit_by_character(state, "astra")
	var enemy: Dictionary = _first_enemy(state)
	if astra.is_empty() or enemy.is_empty():
		_add_error("Missing units for blocked preview check.")
		return
	astra["pos"] = enemy["pos"] + Vector2i.LEFT
	enemy["block"] = 20
	if not state.select_unit_at(astra["pos"]):
		_add_error("Could not select Astra for blocked preview check.")
		return
	state.act_on_tile(astra["pos"], Rect2())
	var preview: Dictionary = state.normal_attack_preview(enemy["pos"])
	if int(preview.get("raw_amount", 0)) <= 0:
		_add_error("Blocked preview did not include raw damage.")
	if int(preview.get("blocked", 0)) <= 0:
		_add_error("Blocked preview did not include blocked damage.")
	if int(preview.get("amount", -1)) != 0:
		_add_error("Fully blocked preview should show zero actual damage.")
	if not String(preview.get("summary", "")).contains("格挡吸收"):
		_add_error("Blocked preview summary should explain guard absorption.")


func _check_tutorial_progression() -> void:
	var state = _fresh_state()
	if state.tutorial_steps.size() != 4:
		_add_error("First battle tutorial should expose 4 steps.")
		return
	if state.tutorial_title() != "选择单位":
		_add_error("Tutorial did not start at unit selection.")
	var liora: Dictionary = _unit_by_character(state, "liora")
	if not liora.is_empty():
		if state.reject_tutorial_action("select_unit", {"character_id": "liora", "tile": liora["pos"]}):
			pass
		else:
			state.select_unit_at(liora["pos"])
	if state.tutorial_step_index != 0:
		_add_error("Tutorial advanced for the wrong character.")
	if not state.message.contains("阿斯特拉"):
		_add_error("Tutorial reject message did not explain the required character.")
	var astra: Dictionary = _unit_by_character(state, "astra")
	if state.reject_tutorial_action("select_unit", {"character_id": "astra", "tile": astra.get("pos", Vector2i.ZERO)}):
		_add_error("Tutorial rejected the correct character.")
	if astra.is_empty() or not state.select_unit_at(astra["pos"]):
		_add_error("Could not select Astra for tutorial.")
		return
	if state.tutorial_step_index != 1:
		_add_error("Tutorial did not advance after selecting Astra.")
	if not state.act_on_tile(astra["pos"], Rect2()):
		_add_error("Could not enter command mode for tutorial.")
		return
	if state.tutorial_step_index != 2:
		_add_error("Tutorial did not advance after move/wait.")
	if not state.reject_tutorial_action("attack_or_skill", {"skill_id": "swift_slash"}):
		_add_error("First battle tutorial should reject the wrong skill.")
	if state.reject_tutorial_action("attack_or_skill", {"skill_id": "crest_resonance"}):
		_add_error("First battle tutorial rejected Crest Resonance.")
	if state.tutorial_recommendation_text() == "":
		_add_error("First battle tutorial should expose a recommendation.")
	if not state.tutorial_recommended_tiles().is_empty():
		_add_error("First battle self skill should not expose board target markers.")


func _check_second_battle_tutorial_skill_gate() -> void:
	var state = _fresh_state()
	state.battle_in_chapter = 2
	state.battle_index = 2
	state._start_battle()
	if state.tutorial_steps.size() != 4:
		_add_error("Second battle tutorial should expose 4 steps.")
		return
	if state.tutorial_title() != "凯尔承伤":
		_add_error("Second battle tutorial did not start with Kael.")
	var kael: Dictionary = _unit_by_character(state, "kael")
	if kael.is_empty() or state.reject_tutorial_action("select_unit", {"character_id": "kael", "tile": kael.get("pos", Vector2i.ZERO)}):
		_add_error("Second battle tutorial rejected Kael selection.")
		return
	if not state.select_unit_at(kael["pos"]):
		_add_error("Could not select Kael for second tutorial.")
		return
	if not state.act_on_tile(kael["pos"], Rect2()):
		_add_error("Could not enter command mode for second tutorial.")
		return
	if not state.reject_tutorial_action("attack_or_skill", {"skill_id": "oath_wall"}):
		_add_error("Second battle tutorial should reject the wrong guard skill.")
	if state.reject_tutorial_action("attack_or_skill", {"skill_id": "guard_bloom"}):
		_add_error("Second battle tutorial rejected Guard Bloom.")


func _check_second_battle_tutorial_recommendations() -> void:
	var state = _fresh_state()
	state.battle_in_chapter = 2
	state.battle_index = 2
	state._start_battle()
	var kael: Dictionary = _unit_by_character(state, "kael")
	var liora: Dictionary = _unit_by_character(state, "liora")
	if kael.is_empty() or liora.is_empty():
		_add_error("Missing heroes for second battle recommendation check.")
		return
	if state.tutorial_recommended_tiles().is_empty():
		_add_error("Second battle first step should expose recommended tiles.")
	state.select_unit_at(kael["pos"])
	if state.tutorial_recommended_tiles().is_empty():
		_add_error("Second battle move step should expose recommended tiles.")
	state.act_on_tile(kael["pos"], Rect2())
	if not state.tutorial_recommendation_text().contains("守护绽放"):
		_add_error("Second battle guard step should recommend Guard Bloom.")
	if not state.tutorial_recommended_tiles().is_empty():
		_add_error("Second battle guard step should not expose board target markers.")
	if not _select_skill_by_id(state, "guard_bloom"):
		_add_error("Could not select Guard Bloom for second battle recommendation check.")
		return
	if not state.handle_card_board_click(kael["pos"], Rect2()):
		_add_error("Guard Bloom did not resolve for second battle recommendation check.")
		return
	if state.reject_tutorial_action("select_unit", {"character_id": "liora", "tile": liora["pos"]}):
		_add_error("Second battle tutorial rejected Liora support selection.")
	if not state.select_unit_at(liora["pos"]):
		_add_error("Could not select Liora for second battle recommendation check.")
		return
	if not state.tutorial_completed:
		_add_error("Second battle tutorial should complete after selecting Liora.")
	var objective := _first_visual_event_with_message(state, "objective", "最终目标")
	if objective.is_empty():
		_add_error("Second battle tutorial completion did not emit the post tutorial objective.")


func _check_tutorial_invalid_target_feedback() -> void:
	var state = _fresh_state()
	var astra: Dictionary = _unit_by_character(state, "astra")
	if astra.is_empty():
		_add_error("Astra missing for tutorial invalid target check.")
		return
	state.reject_invalid_tutorial_target("select_unit")
	var feedback := _first_visual_event(state, "tutorial_feedback", "")
	if feedback.is_empty():
		_add_error("Tutorial invalid target did not emit feedback.")
	elif String(feedback.get("tone", "")) != "warn":
		_add_error("Tutorial invalid target feedback should use warn tone.")
	if not state.message.contains("教学"):
		_add_error("Tutorial invalid target did not update the battle message.")


func _check_tutorial_completion_objective() -> void:
	var state = _fresh_state()
	var astra: Dictionary = _unit_by_character(state, "astra")
	if astra.is_empty():
		_add_error("Astra missing for tutorial completion check.")
		return
	state.select_unit_at(astra["pos"])
	state.act_on_tile(astra["pos"], Rect2())
	if not _select_skill_by_id(state, "crest_resonance"):
		_add_error("Could not select Crest Resonance for tutorial completion.")
		return
	if not state.handle_card_board_click(astra["pos"], Rect2()):
		_add_error("Crest Resonance did not resolve for tutorial completion.")
		return
	state.end_player_turn()
	if not state.tutorial_completed:
		_add_error("Tutorial did not complete after end turn.")
	var objective := _first_visual_event_with_message(state, "objective", "自由目标")
	if objective.is_empty():
		_add_error("Tutorial completion did not emit the post tutorial objective.")


func _check_first_battle_followup_pacing() -> void:
	var state = _fresh_state()
	var kael: Dictionary = _unit_by_character(state, "kael")
	var liora: Dictionary = _unit_by_character(state, "liora")
	var sword := _unit_by_key(state, "enemy_sword")
	var guard := _unit_by_key(state, "enemy_guard")
	if kael.is_empty() or liora.is_empty() or sword.is_empty() or guard.is_empty():
		_add_error("Missing units for first battle pacing check.")
		return
	var kael_anchor := Vector2i(3, 3)
	if not state.movement_tiles_for_unit(kael).has(kael_anchor):
		_add_error("Kael cannot reach the first battle anchor tile.")
	else:
		kael["pos"] = kael_anchor
		if not state.attack_tiles_for_unit(kael).has(sword["pos"]):
			_add_error("Kael cannot attack the first battle sword after reaching the anchor tile.")
	var liora_anchor := Vector2i(2, 5)
	if not state.movement_tiles_for_unit(liora).has(liora_anchor):
		_add_error("Liora cannot reach the first battle holy tile.")
	else:
		liora["pos"] = liora_anchor
		if not state.attack_tiles_for_unit(liora).has(guard["pos"]):
			_add_error("Liora cannot attack the first battle guard from the holy tile.")


func _check_first_battle_enemy_prefers_frontliner() -> void:
	var state = _fresh_state()
	var kael: Dictionary = _unit_by_character(state, "kael")
	var liora: Dictionary = _unit_by_character(state, "liora")
	var sword := _unit_by_key(state, "enemy_sword")
	if kael.is_empty() or liora.is_empty() or sword.is_empty():
		_add_error("Missing units for first battle enemy target check.")
		return
	kael["pos"] = Vector2i(3, 3)
	kael["block"] = 10
	liora["pos"] = Vector2i(2, 5)
	var target := state.enemy_target_unit(sword)
	if target.get("character_id", "") != "kael":
		_add_error("First battle sword should prefer Kael after the tutorial follow-up.")
	var before_hp := int(kael["hp"])
	state.run_enemy_step(sword, Rect2())
	if int(kael["hp"]) >= before_hp and int(kael["block"]) >= 10:
		_add_error("First battle sword did not spend its attack into Kael's guard.")


func _check_terrain_effects() -> void:
	var state = _fresh_state()
	var astra: Dictionary = _unit_by_character(state, "astra")
	var liora: Dictionary = _unit_by_character(state, "liora")
	var enemy: Dictionary = _first_enemy(state)
	if astra.is_empty() or liora.is_empty() or enemy.is_empty():
		_add_error("Missing units for terrain effects check.")
		return
	astra["pos"] = Vector2i(4, 3)
	enemy["pos"] = Vector2i(6, 3)
	enemy["block"] = 0
	if not state.select_unit_at(astra["pos"]):
		_add_error("Could not select high-ground Astra for terrain check.")
		return
	state.act_on_tile(astra["pos"], Rect2())
	var preview := state.normal_attack_preview(enemy["pos"])
	if int(preview.get("amount", 0)) != int(astra.get("atk", 0)) + 1:
		_add_error("High terrain should add +1 normal attack damage.")
	if not state.attack_tiles_for_selected().has(enemy["pos"]):
		_add_error("High terrain should extend attack range by 1.")
	liora["pos"] = Vector2i(2, 5)
	liora["hp"] = int(liora["max_hp"]) - 5
	astra["pos"] = Vector2i(7, 4)
	astra["hp"] = 10
	state.phase = "enemy"
	state.start_player_turn()
	if int(liora["hp"]) != int(liora["max_hp"]) - 2:
		_add_error("Holy terrain should heal 3 HP at player turn start.")
	if int(astra["hp"]) != 7:
		_add_error("Fire terrain should deal 3 damage at player turn start.")


func _check_chapter_two_terrain_overrides() -> void:
	var state = _fresh_state()
	_enter_second_chapter_first_battle(state)
	if state.terrain_kind(Vector2i(4, 2)) != "high":
		_add_error("Chapter 2-1 should place a high-ground choice on the north lane.")
	if state.terrain_kind(Vector2i(2, 4)) != "holy":
		_add_error("Chapter 2-1 should place the rescue target on a holy tile.")
	if state.terrain_kind(Vector2i(6, 4)) != "fire":
		_add_error("Chapter 2-1 should put a fire hazard in the center lane.")
	if state.terrain_kind(Vector2i(7, 4)) != "floor":
		_add_error("Chapter terrain overrides should be able to clear preset fire tiles.")
	var evelyn := _unit_by_key(state, "hero_evelyn")
	if evelyn.is_empty() or state.terrain_kind(evelyn["pos"]) != "holy":
		_add_error("Evelyn should begin the recruitment battle on the visible rescue tile: %s %s." % [str(evelyn.get("pos", Vector2i(-1, -1))), state.terrain_kind(evelyn.get("pos", Vector2i(-1, -1))) if not evelyn.is_empty() else "missing"])
	_force_win_current_battle(state)
	state.claim_reward(0)
	_continue_from_reward_to_chapter_map(state, "chapter 2 terrain override")
	state.start_next_battle()
	if state.current_encounter_id != "chapter2_2":
		_add_error("Could not advance to chapter 2-2 for terrain override check.")
		return
	if state.terrain_kind(Vector2i(5, 3)) != "high" or state.terrain_kind(Vector2i(6, 3)) != "fire" or state.terrain_kind(Vector2i(8, 4)) != "gate":
		_add_error("Chapter 2-2 should create a high-ground/fire-lane exit choice.")


func _check_enemy_terrain_movement_preferences() -> void:
	var state = _fresh_state()
	var sword := _unit_by_key(state, "enemy_sword")
	var guard := _unit_by_key(state, "enemy_guard")
	var astra: Dictionary = _unit_by_character(state, "astra")
	if sword.is_empty() or guard.is_empty() or astra.is_empty():
		_add_error("Missing units for enemy terrain movement preference check.")
		return
	state.terrain.clear()
	guard["role"] = "mage"
	guard["pos"] = Vector2i(2, 2)
	astra["pos"] = Vector2i(5, 2)
	state.terrain[Vector2i(3, 2)] = "high"
	state.terrain[Vector2i(2, 3)] = "floor"
	state.step_enemy_toward(guard, astra["pos"])
	if guard["pos"] != Vector2i(3, 2):
		_add_error("Enemy mage should prefer stepping onto high ground when advancing.")
	sword["pos"] = Vector2i(5, 4)
	astra["pos"] = Vector2i(7, 4)
	state.terrain.clear()
	state.terrain[Vector2i(6, 4)] = "fire"
	state.step_enemy_toward(sword, astra["pos"])
	if sword["pos"] == Vector2i(6, 4):
		_add_error("Enemy sword should avoid fire even when it is the shortest route.")
	guard["pos"] = Vector2i(2, 4)
	guard["role"] = "guard"
	astra["pos"] = Vector2i(6, 4)
	state.terrain.clear()
	state.terrain[Vector2i(3, 3)] = "pillar"
	state.terrain[Vector2i(3, 5)] = "pillar"
	state.step_enemy_toward(guard, astra["pos"])
	if guard["pos"] != Vector2i(3, 4):
		_add_error("Enemy guard should prefer stepping into a chokepoint.")


func _check_block_damage_feedback() -> void:
	var state = _fresh_state()
	var kael: Dictionary = _unit_by_character(state, "kael")
	var sword := _unit_by_key(state, "enemy_sword")
	if kael.is_empty() or sword.is_empty():
		_add_error("Missing units for block feedback check.")
		return
	kael["pos"] = Vector2i(3, 3)
	kael["block"] = 10
	state.run_enemy_step(sword, Rect2())
	if _first_effect(state, "guard", "格挡-").is_empty():
		_add_error("Blocked damage did not show a guard absorb effect.")
	if _first_effect(state, "guard", "未受伤").is_empty():
		_add_error("Fully blocked damage did not show a no-damage effect.")
	if int(kael["hp"]) != int(kael["max_hp"]):
		_add_error("Fully blocked damage should not reduce HP.")


func _check_enemy_hover_forecast() -> void:
	var state = _fresh_state()
	var kael: Dictionary = _unit_by_character(state, "kael")
	var sword := _unit_by_key(state, "enemy_sword")
	if kael.is_empty() or sword.is_empty():
		_add_error("Missing units for enemy hover forecast check.")
		return
	kael["pos"] = Vector2i(3, 3)
	kael["block"] = 3
	var forecast := state.enemy_hover_forecast(sword)
	if forecast.is_empty():
		_add_error("Enemy hover forecast is empty.")
		return
	if String(forecast.get("target_uid", "")) != String(kael.get("uid", "")):
		_add_error("Enemy hover forecast target does not match AI target.")
	if not bool(forecast.get("attacking", false)):
		_add_error("Enemy hover forecast should show an immediate attack.")
	if int(forecast.get("blocked", 0)) != 3 or int(forecast.get("damage", 0)) != 0:
		_add_error("Enemy hover forecast did not calculate guard absorption correctly.")


func _check_enemy_hover_terrain_intents() -> void:
	var state = _fresh_state()
	var sword := _unit_by_key(state, "enemy_sword")
	var guard := _unit_by_key(state, "enemy_guard")
	var astra: Dictionary = _unit_by_character(state, "astra")
	var liora: Dictionary = _unit_by_character(state, "liora")
	var kael: Dictionary = _unit_by_character(state, "kael")
	if sword.is_empty() or guard.is_empty() or astra.is_empty():
		_add_error("Missing units for enemy hover terrain intent check.")
		return
	if not liora.is_empty():
		liora["hp"] = 0
	if not kael.is_empty():
		kael["hp"] = 0
	state.terrain.clear()
	guard["role"] = "mage"
	guard["pos"] = Vector2i(2, 2)
	astra["pos"] = Vector2i(5, 2)
	state.terrain[Vector2i(3, 2)] = "high"
	var high_forecast := state.enemy_hover_forecast(guard)
	if String(high_forecast.get("movement_intent", "")) != "抢占高台":
		_add_error("Enemy hover forecast should explain high-ground preference.")
	sword["pos"] = Vector2i(5, 4)
	astra["pos"] = Vector2i(7, 4)
	state.terrain.clear()
	state.terrain[Vector2i(6, 4)] = "fire"
	var fire_forecast := state.enemy_hover_forecast(sword)
	if String(fire_forecast.get("movement_intent", "")) != "避开火焰":
		_add_error("Enemy hover forecast should explain fire avoidance.")
	guard["role"] = "guard"
	guard["pos"] = Vector2i(2, 4)
	astra["pos"] = Vector2i(6, 4)
	state.terrain.clear()
	state.terrain[Vector2i(3, 3)] = "pillar"
	state.terrain[Vector2i(3, 5)] = "pillar"
	var choke_forecast := state.enemy_hover_forecast(guard)
	if String(choke_forecast.get("movement_intent", "")) != "卡住窄道":
		_add_error("Enemy hover forecast should explain chokepoint preference.")


func _check_skill_action_hints() -> void:
	var state = _fresh_state()
	var kael: Dictionary = _unit_by_character(state, "kael")
	if kael.is_empty():
		_add_error("Kael missing for skill action hint check.")
		return
	if not _enter_command_for_unit(state, kael):
		return
	if not _select_skill_by_id(state, "guard_bloom"):
		_add_error("Could not select guard skill for action hint check.")
		return
	if not state.handle_card_board_click(kael["pos"], Rect2()):
		_add_error("Guard skill did not resolve for action hint check.")
		return
	var release_event := _first_visual_event(state, "skill_release", kael["uid"])
	if release_event.is_empty():
		_add_error("Skill release event was not emitted.")
	elif String(release_event.get("action_hint", "")) != "skill":
		_add_error("Guard skill release should use skill action hint.")
	elif float(release_event.get("duration", 0.0)) < 0.6:
		_add_error("Guard skill release should be long enough to show the skill action row.")


func _check_level_exp_progression() -> void:
	var state = _fresh_state()
	var astra: Dictionary = _unit_by_character(state, "astra")
	var enemy: Dictionary = _first_enemy(state)
	var member := _party_member_by_character(state, "astra")
	if astra.is_empty() or enemy.is_empty() or member.is_empty():
		_add_error("Missing units for level EXP progression check.")
		return
	member["xp"] = 90
	astra["xp"] = 90
	astra["pos"] = enemy["pos"] + Vector2i.LEFT
	enemy["hp"] = 1
	enemy["block"] = 0
	if not state.select_unit_at(astra["pos"]):
		_add_error("Could not select Astra for EXP check.")
		return
	state.act_on_tile(astra["pos"], Rect2())
	if not state.act_on_tile(enemy["pos"], Rect2()):
		_add_error("EXP check attack did not resolve.")
		return
	if int(member.get("level", 1)) != 2:
		_add_error("Kill EXP should level Astra from 90/100.")
	if int(member.get("xp", 0)) != 30:
		_add_error("Kill EXP should wrap to 30/100 after a 40 EXP kill.")
	if int(astra.get("level", 1)) != 2 or int(astra.get("max_hp", 0)) <= 30:
		_add_error("Level up should update the active unit stats.")
	if int(state.battle_stats.get("xp_gained", 0)) < 40:
		_add_error("Battle stats should record gained EXP.")
	if not state.battle_exp_summary().contains("阿斯特拉 +40"):
		_add_error("Battle EXP summary should include grouped EXP gain.")

	var support_state = _fresh_state()
	var kael: Dictionary = _unit_by_character(support_state, "kael")
	var kael_member := _party_member_by_character(support_state, "kael")
	if kael.is_empty() or kael_member.is_empty():
		_add_error("Missing Kael for support EXP check.")
		return
	if not _enter_command_for_unit(support_state, kael):
		return
	if not _select_skill_by_id(support_state, "guard_bloom"):
		_add_error("Could not select Guard Bloom for support EXP check.")
		return
	if not support_state.handle_card_board_click(kael["pos"], Rect2()):
		_add_error("Guard Bloom did not resolve for support EXP check.")
	if int(kael_member.get("xp", 0)) != BattleStateScript.EXP_SUPPORT:
		_add_error("Support skills should grant support EXP.")


func _check_vfx_impact_timing() -> void:
	var state = _fresh_state()
	var astra: Dictionary = _unit_by_character(state, "astra")
	var enemy: Dictionary = _first_enemy(state)
	if astra.is_empty() or enemy.is_empty():
		_add_error("Missing units for VFX timing check.")
		return
	astra["pos"] = enemy["pos"] + Vector2i.LEFT
	if not state.select_unit_at(astra["pos"]):
		_add_error("Could not select Astra for VFX timing check.")
		return
	state.act_on_tile(astra["pos"], Rect2())
	if not state.act_on_tile(enemy["pos"], Rect2()):
		_add_error("Normal attack did not resolve for VFX timing check.")
		return
	var attack_event := _first_visual_event(state, "attack", astra["uid"])
	if attack_event.is_empty():
		_add_error("Attack event missing for VFX timing check.")
	elif float(attack_event.get("impact_progress", 0.0)) <= 0.0:
		_add_error("Attack event missing impact_progress.")
	var damage_effect := _first_effect(state, "slash", "-")
	if damage_effect.is_empty():
		_add_error("Delayed damage effect missing.")
	elif float(damage_effect.get("start_delay", 0.0)) <= 0.0:
		_add_error("Damage effect should be delayed to the attack impact frame.")
	elif not _float_close(float(damage_effect.get("start_delay", 0.0)), state.visual_impact_delay("attack", float(attack_event.get("duration", 0.0)))):
		_add_error("Damage effect delay does not match the attack impact frame.")


func _check_skill_effect_impact_timing() -> void:
	var state = _fresh_state()
	var kael: Dictionary = _unit_by_character(state, "kael")
	if kael.is_empty():
		_add_error("Kael missing for skill impact timing check.")
		return
	if not _enter_command_for_unit(state, kael):
		return
	if not _select_skill_by_id(state, "guard_bloom"):
		_add_error("Could not select Guard Bloom for skill impact timing check.")
		return
	if not state.handle_card_board_click(kael["pos"], Rect2()):
		_add_error("Guard Bloom did not resolve for skill impact timing check.")
		return
	var release_event := _first_visual_event(state, "skill_release", kael["uid"])
	var guard_effect := _first_effect(state, "guard", "+")
	if release_event.is_empty() or guard_effect.is_empty():
		_add_error("Skill release or guard effect missing for impact timing check.")
		return
	var expected_delay := state.visual_impact_delay("skill_release", float(release_event.get("duration", 0.0)))
	if not _float_close(float(guard_effect.get("start_delay", 0.0)), expected_delay):
		_add_error("Guard skill effect delay does not match the skill release impact frame.")


func _check_boss_action_sheet_key() -> void:
	var state = _fresh_state()
	state.battle_in_chapter = 2
	state.battle_index = 2
	state._start_battle()
	var boss := {}
	for unit in state.units:
		if unit.get("unit_key", "") == "enemy_boss":
			boss = unit
			break
	if boss.is_empty():
		_add_error("Boss unit missing from final battle.")
	elif boss.get("unit_key", "") != "enemy_boss" or boss.get("role", "") != "sword":
		_add_error("Boss unit key/role data is not available for action sheet fallback.")


func _check_reward_pick_feedback() -> void:
	var state = _fresh_state()
	state.generate_reward_options()
	if state.reward_options.is_empty():
		_add_error("Reward options were not generated.")
		return
	var reward_index := 0
	var reward: Dictionary = state.reward_options[reward_index]
	var owner_id := state.reward_owner_character_id(reward)
	var reward_id := String(reward.get("id", ""))
	if state.reward_card_summary(reward) == "" or state.reward_owner_reason(reward) == "":
		_add_error("Reward card feedback text is missing.")
	state.claim_reward(reward_index)
	if not state.reward_claimed:
		_add_error("Reward was not marked claimed.")
	if not state.reward_confirmation_title().contains(String(reward.get("title", ""))):
		_add_error("Reward confirmation title does not include the learned skill.")
	if not state.reward_confirmation_note().contains(state.reward_owner_reason(reward)):
		_add_error("Reward confirmation note does not include the owner reason.")
	var owner := _party_member_by_character(state, owner_id)
	if owner.is_empty():
		_add_error("Reward owner member missing from party.")
		return
	if not owner.get("skill_ids", []).has(reward_id):
		_add_error("Reward skill was not added to the owner skill pool.")
	if not owner.get("learned_skills", []).has(reward_id):
		_add_error("Reward skill was not recorded as learned.")


func _check_permanent_death_rules() -> void:
	var state = _fresh_state()
	var liora: Dictionary = _unit_by_character(state, "liora")
	if liora.is_empty():
		_add_error("Liora missing for permanent death check.")
		return
	liora["hp"] = 0
	state.clear_dead_units()
	state.check_end_state()
	var member := _party_member_by_character(state, "liora")
	if member.is_empty() or not bool(member.get("fallen", false)):
		_add_error("Fallen ally was not marked permanently fallen in party.")
	if state.defeat:
		_add_error("Non-lord ally death should not immediately defeat the chapter.")
	_force_win_current_battle(state)
	state.claim_reward(0)
	state.start_next_battle()
	var rows := state.chapter_map_party_rows()
	for row in rows:
		if String(row.get("character_id", "")) == "liora":
			_add_error("Fallen ally should not appear in chapter camp rows.")
	var event_ids: Array[String] = []
	for option in state.chapter_camp_event_options():
		event_ids.append(String(option.get("id", "")))
	if event_ids.has("liora_prayer"):
		_add_error("Fallen ally camp event should be skipped.")
	state.start_next_battle()
	if not _unit_by_character(state, "liora").is_empty():
		_add_error("Fallen ally should not appear in the next battle.")
	if not state.chapter_camp_summary().contains("牺牲"):
		_add_error("Chapter camp summary should record fallen allies.")
	var lord_state = _fresh_state()
	var astra: Dictionary = _unit_by_character(lord_state, "astra")
	if astra.is_empty():
		_add_error("Astra missing for lord death check.")
		return
	astra["hp"] = 0
	lord_state.clear_dead_units()
	lord_state.check_end_state()
	if not lord_state.defeat:
		_add_error("Astra falling should immediately defeat the battle.")


func _check_active_skill_limit() -> void:
	var state = _fresh_state()
	state.learn_skill_reward(state.content.create_card("royal_order"))
	state.learn_skill_reward(state.content.create_card("silver_edge"))
	var astra := _unit_by_character(state, "astra")
	if astra.is_empty() or not state.select_unit_at(astra["pos"]):
		_add_error("Astra missing for active skill limit check.")
		return
	state.act_on_tile(astra["pos"], Rect2())
	state.sync_active_hand()
	if state.hand.size() != 2:
		_add_error("Battle skill hand should show exactly two equipped skills.")
	state.chapter_phase = "chapter_map"
	state.reward_claimed = true
	state.open_chapter_camp("astra")
	var equipped_count := 0
	for row in state.chapter_camp_skill_rows():
		if bool(row.get("equipped", false)):
			equipped_count += 1
	if equipped_count != 2:
		_add_error("Camp skill rows should mark exactly two equipped skills.")


func _check_promotion_choice_feedback() -> void:
	var state = _fresh_state()
	_grant_promotion_readiness(state)
	state.start_promotion()
	if state.chapter_phase != "promotion":
		_add_error("Promotion phase did not start.")
		return
	if state.promotion_options.size() < 6:
		_add_error("Promotion options should include two choices per hero.")
		return
	var option: Dictionary = state.promotion_options[0]
	if state.promotion_role_summary(option) == "" or state.promotion_stat_summary(option) == "":
		_add_error("Promotion option feedback text is missing.")
	var owner_id := String(option.get("character_id", ""))
	var class_id := String(option.get("class_id", ""))
	var passive_id := String(option.get("passive_id", ""))
	state.claim_promotion(0)
	if not state.promotion_claimed or state.chapter_phase != "complete":
		_add_error("Promotion choice did not complete the chapter.")
	if state.selected_promotion.is_empty() or String(state.selected_promotion.get("class_id", "")) != class_id:
		_add_error("Selected promotion was not recorded.")
	if not state.promotion_confirmation_title().contains(String(option.get("name", ""))):
		_add_error("Promotion confirmation title does not include the chosen class.")
	if not state.promotion_confirmation_note().contains(state.promotion_role_summary(option)):
		_add_error("Promotion confirmation note does not include the class role summary.")
	var member := _party_member_by_character(state, owner_id)
	if member.is_empty():
		_add_error("Promoted party member missing.")
		return
	if String(member.get("class_id", "")) != class_id:
		_add_error("Promoted member class_id was not updated.")
	if String(member.get("passive_id", "")) != passive_id:
		_add_error("Promoted member passive_id was not updated.")
	if int(member.get("class_tier", 0)) != int(option.get("tier", 0)):
		_add_error("Promoted member class tier was not updated.")


func _check_chapter_completion_summary() -> void:
	var state = _fresh_state()
	state.generate_reward_options()
	if state.reward_options.is_empty():
		_add_error("Reward options missing for chapter summary check.")
		return
	var reward: Dictionary = state.reward_options[0]
	state.claim_reward(0)
	if not state.chapter_reward_summary().contains(String(reward.get("title", ""))):
		_add_error("Chapter reward summary does not include learned reward.")
	_grant_promotion_readiness(state)
	state.start_promotion()
	if state.promotion_options.is_empty():
		_add_error("Promotion options missing for chapter summary check.")
		return
	var option: Dictionary = state.promotion_options[0]
	state.claim_promotion(0)
	if state.chapter_phase != "complete":
		_add_error("Chapter summary check did not reach complete phase.")
	if not state.chapter_battle_summary().contains("最终战评价"):
		_add_error("Chapter battle summary is missing final grade text.")
	if not state.promotion_confirmation_title().contains(String(option.get("name", ""))):
		_add_error("Chapter promotion summary does not include selected class.")
	if state.chapter_camp_summary() != "本章未触发羁绊或训练。":
		_add_error("Chapter camp summary should be empty when no camp action was used.")
	if not state.chapter_next_step_summary().contains("下一步"):
		_add_error("Chapter next step summary is missing.")


func _check_chapter_map_party_rows() -> void:
	var state = _fresh_state()
	_force_win_current_battle(state)
	if state.reward_options.is_empty():
		_add_error("Chapter map party row check did not generate rewards.")
		return
	var reward: Dictionary = state.reward_options[0]
	var owner_id := state.reward_owner_character_id(reward)
	state.claim_reward(0)
	if state.chapter_phase != "reward":
		_add_error("Chapter map party row check should show reward confirmation first.")
		return
	state.start_next_battle()
	if state.chapter_phase != "chapter_map":
		_add_error("Chapter map party row check did not enter map phase.")
		return
	var rows := state.chapter_map_party_rows()
	if rows.size() != 3:
		_add_error("Chapter map should summarize all three party members.")
		return
	var found_owner := false
	for row in rows:
		if String(row.get("name", "")) == "" or String(row.get("class", "")) == "":
			_add_error("Chapter map party row is missing name or class.")
		if String(row.get("passive", "")) == "":
			_add_error("Chapter map party row is missing passive text.")
		if int(row.get("skill_count", 0)) <= 0:
			_add_error("Chapter map party row should include a positive skill count.")
		if String(row.get("character_id", "")) == owner_id:
			found_owner = true
			if int(row.get("learned_count", 0)) <= 0:
				_add_error("Chapter map party row should show the claimed reward as learned.")
			if not row.get("learned_titles", []).has(String(reward.get("title", ""))):
				_add_error("Chapter map party row learned titles should include the claimed reward title.")
	if not found_owner:
		_add_error("Chapter map party rows did not include the reward owner.")
	state.open_chapter_camp(owner_id)
	if not state.camp_view_open:
		_add_error("Chapter camp detail did not open from map phase.")
	var selected := state.chapter_camp_selected_member_row()
	if String(selected.get("character_id", "")) != owner_id:
		_add_error("Chapter camp selected member does not match requested owner.")
	var skill_rows := state.chapter_camp_skill_rows()
	if skill_rows.is_empty():
		_add_error("Chapter camp skill rows should include the selected member skill pool.")
	var found_reward_skill := false
	for row in skill_rows:
		if String(row.get("title", "")) == String(reward.get("title", "")) and bool(row.get("learned", false)):
			found_reward_skill = true
	if not found_reward_skill:
		_add_error("Chapter camp skill rows should mark the claimed reward as newly learned.")
	var owner := _party_member_by_character(state, owner_id)
	var reward_id := String(reward.get("id", ""))
	var before_first := String(owner.get("skill_ids", [])[0])
	state.equip_chapter_camp_skill(reward_id)
	owner = _party_member_by_character(state, owner_id)
	if String(owner.get("skill_ids", [])[0]) != reward_id:
		_add_error("Chapter camp equip should move selected skill to the active front slot.")
	if state.chapter_camp_skill_rows().is_empty() or not bool(state.chapter_camp_skill_rows()[0].get("equipped", false)):
		_add_error("Chapter camp skill rows should mark front skills as equipped.")
	if before_first != reward_id and String(owner.get("skill_ids", [])[1]) != before_first:
		_add_error("Chapter camp equip should preserve the previous front skill after the equipped skill.")
	if not state.can_use_chapter_camp_rest():
		_add_error("Chapter camp rest should be available before use.")
	state.use_chapter_camp_rest()
	if not state.camp_rest_used or not state.camp_rest_bonus_pending:
		_add_error("Chapter camp rest should set a pending next-battle bonus.")
	if not state.chapter_camp_pending_summary().contains("训练"):
		_add_error("Chapter camp pending summary should include rest bonus.")
	if state.chapter_camp_event_options().size() != 3:
		_add_error("Chapter camp should expose three event choices.")
	var block_event: Dictionary = state.chapter_camp_event_options()[2]
	if int(block_event.get("amount", 0)) != 4 or String(block_event.get("icon_key", "")) != "guard":
		_add_error("Chapter camp event data should expose amount and icon key.")
	if state.chapter_camp_event_impact(block_event) != "全员开局格挡 +4":
		_add_error("Chapter camp event impact text is incorrect.")
	if not state.can_choose_chapter_camp_event(2):
		_add_error("Chapter camp event should be available before choice.")
	state.choose_chapter_camp_event(2)
	if not state.camp_event_used or state.camp_event_bonus != "block":
		_add_error("Chapter camp event should record the selected pending bonus.")
	if state.selected_chapter_camp_event_id() != "kael_watch":
		_add_error("Chapter camp event should expose the selected event id for UI feedback.")
	if not state.chapter_camp_pending_summary().contains("格挡 +4"):
		_add_error("Chapter camp pending summary should include selected event bonus.")
	if not state.chapter_camp_summary().contains("盾线夜话"):
		_add_error("Chapter camp summary should include the selected event title.")
	if state.can_choose_chapter_camp_event(0):
		_add_error("Chapter camp event should only be selectable once.")
	state.start_next_battle()
	if state.chapter_phase != "battle" or state.player_power != 1 or state.camp_rest_bonus_pending:
		_add_error("Chapter camp rest bonus should apply as +1 power on the next battle.")
	for unit in state.get_player_units():
		if int(unit.get("block", 0)) < 4:
			_add_error("Chapter camp block event should give every player unit starting block.")
	if state.camp_event_bonus != "":
		_add_error("Chapter camp event bonus should be consumed when the next battle starts.")
	var owner_unit := _unit_by_character(state, owner_id)
	if owner_unit.is_empty() or not state.select_unit_at(owner_unit.get("pos", Vector2i.ZERO)):
		_add_error("Could not select camp reward owner in next battle.")
	else:
		var has_reward_in_hand := false
		for skill in state.hand:
			if String(skill.get("id", "")) == reward_id:
				has_reward_in_hand = true
		if not has_reward_in_hand:
			_add_error("Equipped camp skill did not appear in the next battle skill menu.")
	state.close_chapter_camp()
	if state.camp_view_open:
		_add_error("Chapter camp detail did not close.")


func _check_chapter_one_mvp_loop() -> void:
	var state = _fresh_state()
	_grant_promotion_readiness(state)
	for expected_battle in [1, 2]:
		if state.chapter_phase != "battle" or state.battle_in_chapter != expected_battle:
			_add_error("Chapter loop expected battle %d but got phase %s battle %d." % [expected_battle, state.chapter_phase, state.battle_in_chapter])
			return
		_force_win_current_battle(state)
		if state.chapter_phase != "reward" or not state.victory:
			_add_error("Chapter loop battle %d did not reach reward phase." % expected_battle)
			return
		if state.reward_options.is_empty():
			_add_error("Chapter loop battle %d did not generate rewards." % expected_battle)
			return
		state.claim_reward(0)
		if not state.reward_claimed:
			_add_error("Chapter loop battle %d reward was not claimed." % expected_battle)
			return
		if expected_battle < 2:
			if state.chapter_phase != "reward":
				_add_error("Chapter loop battle %d should stay on reward confirmation after reward." % expected_battle)
				return
			state.start_next_battle()
			if state.chapter_phase != "chapter_map":
				_add_error("Chapter loop battle %d should enter chapter map from reward confirmation." % expected_battle)
				return
			if not state.can_enter_chapter_map_node(expected_battle + 1):
				_add_error("Chapter map did not unlock the next battle node after battle %d." % expected_battle)
				return
			state.start_next_battle()
		else:
			state.start_next_battle()
	if state.chapter_phase != "promotion":
		_add_error("Chapter loop did not enter promotion after the final reward.")
		return
	if state.chapter_reward_history.size() != 2:
		_add_error("Chapter loop should record two learned reward entries.")
	if state.promotion_options.is_empty():
		_add_error("Chapter loop did not provide promotion options.")
		return
	state.claim_promotion(0)
	if state.chapter_phase != "complete" or not state.promotion_claimed:
		_add_error("Chapter loop did not complete after promotion.")
	if state.chapter_reward_summary() == "本章尚未领悟新技能。":
		_add_error("Chapter loop summary did not retain learned rewards.")
	if state.selected_promotion.is_empty():
		_add_error("Chapter loop did not retain selected promotion.")


func _check_start_second_chapter() -> void:
	var state = _fresh_state()
	_grant_promotion_readiness(state)
	for expected_battle in [1, 2]:
		_force_win_current_battle(state)
		if state.reward_options.is_empty():
			_add_error("Second chapter setup battle %d did not generate rewards." % expected_battle)
			return
		state.claim_reward(0)
		if expected_battle < 2:
			_continue_from_reward_to_chapter_map(state, "second chapter setup battle %d" % expected_battle)
			state.start_next_battle()
		else:
			state.start_next_battle()
	if state.chapter_phase != "promotion":
		_add_error("Second chapter setup did not reach promotion.")
		return
	if state.promotion_options.is_empty():
		_add_error("Second chapter setup has no promotion options.")
		return
	state.claim_promotion(0)
	if state.chapter_phase != "complete" or not state.has_next_chapter():
		_add_error("Chapter one completion should expose a next chapter.")
		return
	state.start_next_chapter()
	if state.chapter_index != 2 or state.chapter_phase != "intro" or state.battle_in_chapter != 1:
		_add_error("Starting next chapter did not reset to chapter 2 intro.")
		return
	if not state.chapter_data().get("title", "").contains("符焰回廊"):
		_add_error("Chapter 2 data was not loaded.")
	state.advance_intro()
	state.advance_intro()
	state.advance_intro()
	if state.chapter_phase != "battle" or state.current_encounter_id != "chapter2_1":
		_add_error("Chapter 2 intro did not start the first chapter 2 encounter.")
	if state.chapter_camp_summary() != "本章未触发羁绊或训练。":
		_add_error("Chapter 2 should start with a clean camp summary.")


func _check_recruitment_survive_join() -> void:
	var state = _fresh_state()
	_enter_second_chapter_first_battle(state)
	if state.battle_recruitment().get("character_id", "") != "evelyn":
		_add_error("Chapter 2 first battle should expose Evelyn recruitment data.")
		return
	if state.is_character_recruited("evelyn"):
		_add_error("Evelyn should not be recruited before the recruitment battle ends.")
	_force_win_current_battle(state)
	if not state.is_character_recruited("evelyn"):
		_add_error("Evelyn should join after surviving chapter 2 first battle.")
	if state.is_character_deployed("evelyn"):
		_add_error("Recruited Evelyn should start as a reserve unit.")
	if not state.chapter_camp_summary().contains("招募伊芙琳"):
		_add_error("Recruitment should be recorded in chapter camp summary.")
	state.claim_reward(0)
	if state.chapter_phase != "reward":
		_add_error("Recruitment battle should show reward confirmation after reward.")
	state.start_next_battle()
	if state.chapter_phase != "chapter_map":
		_add_error("Recruitment battle should continue into chapter map from reward confirmation.")
	var rows := state.chapter_map_party_rows()
	var found_row := false
	for row in rows:
		if String(row.get("character_id", "")) == "evelyn":
			found_row = true
	if not found_row:
		_add_error("Chapter map party rows should include recruited Evelyn.")
	if state.deployed_count() != 3:
		_add_error("Deployment count should remain capped at three after recruitment.")
	state.open_chapter_camp("evelyn")
	state.toggle_chapter_camp_deployment("evelyn")
	if state.is_character_deployed("evelyn"):
		_add_error("Deployment should reject Evelyn while all three slots are full.")
	state.toggle_chapter_camp_deployment("kael")
	if state.is_character_deployed("kael"):
		_add_error("Kael should be moved to reserve for deployment test.")
	state.toggle_chapter_camp_deployment("evelyn")
	if not state.is_character_deployed("evelyn") or state.deployed_count() != 3:
		_add_error("Evelyn should be deployable after freeing one slot.")
	state.start_next_battle()
	if state.current_encounter_id != "chapter2_2":
		_add_error("Recruitment test did not advance to chapter 2 second battle.")
	var evelyn_unit := _unit_by_character(state, "evelyn")
	if evelyn_unit.is_empty():
		_add_error("Recruited Evelyn should appear in the next battle.")
	if not _unit_by_character(state, "kael").is_empty():
		_add_error("Reserve Kael should not appear in the next battle.")


func _check_reach_objective_victory() -> void:
	var state = _fresh_state()
	_enter_second_chapter_first_battle(state)
	_force_win_current_battle(state)
	state.claim_reward(0)
	_continue_from_reward_to_chapter_map(state, "reach objective setup")
	state.start_next_battle()
	if state.current_encounter_id != "chapter2_2":
		_add_error("Reach objective test did not enter chapter2_2.")
		return
	if state.objective_summary() != "目标：抵达回廊出口":
		_add_error("Reach objective summary is not shown.")
	var astra := _unit_by_character(state, "astra")
	if astra.is_empty():
		_add_error("Astra missing for reach objective test.")
		return
	astra["pos"] = Vector2i(8, 4)
	state.check_end_state()
	if not state.victory or state.chapter_phase != "reward":
		_add_error("Reach objective should trigger victory when a player reaches the exit.")


func _enter_second_chapter_first_battle(state) -> void:
	_grant_promotion_readiness(state)
	while state.chapter_index == 1 and state.chapter_phase == "battle":
		var was_final_battle: bool = state.battle_in_chapter >= state.chapter_encounter_count()
		_force_win_current_battle(state)
		state.claim_reward(0)
		if was_final_battle:
			state.start_next_battle()
		else:
			_continue_from_reward_to_chapter_map(state, "enter second chapter setup battle %d" % state.battle_in_chapter)
			state.start_next_battle()
	state.claim_promotion(0)
	state.start_next_chapter()
	state.advance_intro()
	state.advance_intro()
	state.advance_intro()


func _grant_promotion_readiness(state) -> void:
	for member in state.party:
		member["level"] = max(10, int(member.get("level", 1)))
	state.inventory["promotion_seal"] = 6


func _force_win_current_battle(state) -> void:
	for unit in state.units:
		if unit.get("team", "") == "enemy":
			unit["hp"] = 0
	state.clear_dead_units()
	state.check_end_state()


func _continue_from_reward_to_chapter_map(state, context: String = "") -> void:
	if state.chapter_phase != "reward" or not state.reward_claimed:
		_add_error("Expected to be on reward confirmation before entering chapter map%s." % _context_suffix(context))
		return
	state.start_next_battle()
	if state.chapter_phase != "chapter_map":
		_add_error("Expected reward confirmation to continue into chapter map%s." % _context_suffix(context))
		return


func _context_suffix(context: String) -> String:
	return " (%s)" % context if context != "" else ""


func _enter_command_for_unit(state, unit: Dictionary) -> bool:
	if unit.is_empty():
		_add_error("Cannot enter command for missing unit.")
		return false
	if not state.select_unit_at(unit["pos"]):
		_add_error("Could not select %s." % unit.get("name", "unit"))
		return false
	if not state.act_on_tile(unit["pos"], Rect2()):
		_add_error("Could not enter command mode for %s." % unit.get("name", "unit"))
		return false
	if state.action_mode != "command":
		_add_error("Unit did not enter command mode.")
		return false
	return true


func _select_skill_by_id(state, skill_id: String) -> bool:
	state.sync_active_hand()
	for i in range(state.hand.size()):
		if String(state.hand[i].get("id", "")) == skill_id:
			state.select_skill(i)
			return state.selected_card == i
	return false


func _hand_has_exactly(state, expected: Array) -> bool:
	state.sync_active_hand()
	if state.hand.size() != expected.size():
		return false
	var seen: Array = []
	for skill in state.hand:
		var skill_id: String = String(skill.get("id", ""))
		if seen.has(skill_id) or not expected.has(skill_id):
			return false
		seen.append(skill_id)
	return true


func _unit_by_character(state, character_id: String) -> Dictionary:
	for unit in state.units:
		if unit.get("character_id", "") == character_id:
			return unit
	return {}


func _first_enemy(state) -> Dictionary:
	for unit in state.units:
		if unit.get("team", "") == "enemy":
			return unit
	return {}


func _unit_by_key(state, unit_key: String) -> Dictionary:
	for unit in state.units:
		if unit.get("unit_key", "") == unit_key:
			return unit
	return {}


func _party_member_by_character(state, character_id: String) -> Dictionary:
	for member in state.party:
		if member.get("character_id", "") == character_id:
			return member
	return {}


func _first_visual_event(state, kind: String, uid: String) -> Dictionary:
	for event in state.visual_events:
		if event.get("kind", "") == kind and event.get("uid", "") == uid:
			return event
	return {}


func _first_visual_event_with_message(state, kind: String, message: String) -> Dictionary:
	for event in state.visual_events:
		if event.get("kind", "") == kind and String(event.get("message", "")) == message:
			return event
	return {}


func _first_effect(state, kind: String, text_prefix: String) -> Dictionary:
	for effect in state.effects:
		if effect.get("kind", "") == kind and String(effect.get("text", "")).begins_with(text_prefix):
			return effect
	return {}


func _float_close(a: float, b: float, epsilon: float = 0.01) -> bool:
	return absf(a - b) <= epsilon


func _add_error(message: String) -> void:
	errors.append(message)


func _print_result() -> void:
	for error in errors:
		push_error(error)
		print("ERROR: %s" % error)
	if errors.is_empty():
		print("State checks passed.")
	else:
		print("State checks failed. Errors: %d" % errors.size())
