class_name SkillEffects
extends RefCounted

const CARD_STRIKE := BattleAssets.CARD_STRIKE
const CARD_LANCE := BattleAssets.CARD_LANCE
const CARD_DASH := BattleAssets.CARD_DASH
const CARD_GUARD := BattleAssets.CARD_GUARD
const CARD_ENGAGE := BattleAssets.CARD_ENGAGE
const CARD_HEAL := BattleAssets.CARD_HEAL


func valid_tiles(state) -> Array:
	var tiles: Array = []
	var skill: Dictionary = state.selected_skill()
	if skill.is_empty():
		return tiles
	var executor: Dictionary = state.selected_unit()
	if executor.is_empty() or bool(executor.get("acted", false)):
		return tiles
	var origin: Vector2i = executor["pos"]
	var skill_id: String = skill.get("id", "")
	match skill["kind"]:
		CARD_STRIKE:
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var strike_pos: Vector2i = origin + d
				if state.in_bounds(strike_pos) and state.enemy_at(strike_pos) != null:
					tiles.append(strike_pos)
		CARD_LANCE:
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				for r in range(1, 4):
					var lance_pos: Vector2i = origin + d * r
					if not state.in_bounds(lance_pos):
						break
					var blocker = state.unit_at(lance_pos)
					if blocker != null:
						if blocker["team"] == "enemy":
							tiles.append(lance_pos)
						break
		CARD_DASH:
			var dash_range := 3
			if skill_id == "aegis_step":
				dash_range = 2
			elif skill_id == "fleet_reposition":
				dash_range = 1
			for y in range(BattleState.GRID_H):
				for x in range(BattleState.GRID_W):
					var dash_pos := Vector2i(x, y)
					if dash_pos != origin and state.is_walkable(dash_pos) and state.unit_at(dash_pos) == null and state.manhattan(origin, dash_pos) <= dash_range:
						tiles.append(dash_pos)
		CARD_GUARD, CARD_ENGAGE:
			tiles.append(origin)
		CARD_HEAL:
			for ally in state.get_player_units():
				tiles.append(ally["pos"])
	return tiles


func apply_selected_skill(state, tile: Vector2i, board_rect: Rect2) -> bool:
	var skill: Dictionary = state.selected_skill()
	if skill.is_empty():
		return false
	var executor: Dictionary = state.selected_unit()
	if executor.is_empty():
		state.message = "请选择执行技能的单位。"
		state.push_log(state.message)
		return false
	if bool(executor.get("acted", false)):
		state.message = "%s已经行动过。" % executor.get("name", "该单位")
		state.push_log(state.message)
		return false
	if not state._unit_owns_skill(executor, skill) or not state.can_unit_execute_card(executor, skill):
		state.message = "%s不能使用「%s」。" % [executor.get("name", "队员"), skill.get("title", "技能")]
		state.push_log(state.message)
		return false
	if not valid_tiles(state).has(tile):
		state.message = "目标不在范围内。"
		state.push_log(state.message)
		return false

	var played := false
	var target = state.unit_at(tile)
	var skill_id: String = skill.get("id", "")
	var release_duration := _skill_release_duration(skill["kind"])
	var impact_delay: float = state.visual_impact_delay("skill_release", release_duration)
	match skill["kind"]:
		CARD_STRIKE:
			var strike_damage := 10 if skill_id == "silver_edge" else 7
			if executor.get("passive_id", "") == "crest_edge":
				strike_damage += 1
			played = target != null and target["team"] == "enemy" and state.damage_unit_from(executor, target, strike_damage + state.player_power + state.terrain_attack_bonus(executor), board_rect)
			if played and target["hp"] <= 0 and executor.get("passive_id", "") == "duel_flash":
				executor["block"] = int(executor["block"]) + 2
				state.add_tile_effect(executor["pos"], "+2格挡", Color("#8fffd8"), "guard", board_rect, impact_delay)
		CARD_LANCE:
			var damage := 6 if skill_id == "ember_thrust" else 9
			if executor.get("passive_id", "") == "sunlance_drive":
				damage += 2
			played = target != null and target["team"] == "enemy" and state.damage_unit_from(executor, target, damage + state.player_power + state.terrain_attack_bonus(executor), board_rect)
		CARD_DASH:
			played = state.move_unit(executor, tile, board_rect)
			if played and skill_id == "aegis_step":
				executor["block"] = int(executor["block"]) + 3
				state.message = "%s守势换位，获得3点格挡。" % executor["name"]
				state.push_log(state.message)
				state.add_tile_effect(executor["pos"], "+3格挡", Color("#8fffd8"), "guard", board_rect, impact_delay)
				state.add_visual_event("guard", executor["uid"], executor["pos"], 0.68, {"amount": 3, "vfx_kind": "guard", "message": "格挡"})
			elif played and skill_id == "fleet_reposition":
				state.message = "%s疾令换阵。" % executor["name"]
				state.push_log(state.message)
		CARD_GUARD:
			var block_gain := 14 if skill_id == "oath_wall" else 8
			if executor.get("passive_id", "") == "vow_guard":
				block_gain += 2
			executor["block"] = int(executor["block"]) + block_gain
			state.message = "%s获得%d点格挡。" % [executor["name"], block_gain]
			state.push_log(state.message)
			state.add_tile_effect(executor["pos"], "+%d格挡" % block_gain, Color("#8fffd8"), "guard", board_rect, impact_delay)
			state.add_visual_event("guard", executor["uid"], executor["pos"], 0.68, {"amount": block_gain, "vfx_kind": "guard", "message": "格挡"})
			played = true
		CARD_ENGAGE:
			var power_gain := 2
			if skill_id in ["royal_order", "azure_command"]:
				power_gain = 1
			if executor.get("passive_id", "") == "royal_tactics":
				power_gain += 1
			state.player_power += power_gain
			state.message = "%s：全队力量+%d。" % [skill["title"], power_gain]
			state.push_log(state.message)
			state.add_tile_effect(executor["pos"], "力量+%d" % power_gain, Color("#f6d26b"), "guard", board_rect, impact_delay)
			state.add_visual_event("engage", executor["uid"], executor["pos"], 0.68, {"amount": power_gain, "vfx_kind": "guard", "message": "纹章"})
			played = true
		CARD_HEAL:
			if target != null and target["team"] == "player":
				var heal := 6
				var bonus_block := 0
				if skill_id == "sanctuary":
					heal = 10
				elif skill_id == "seraphic_mend":
					heal = 8
					bonus_block = 4
				if executor.get("passive_id", "") in ["gentle_light", "seraphic_grace"]:
					heal += 3 if executor.get("passive_id", "") == "seraphic_grace" else 1
				target["hp"] = mini(int(target["max_hp"]), int(target["hp"]) + heal)
				if bonus_block > 0:
					target["block"] = int(target["block"]) + bonus_block
					state.message = "%s为%s恢复%d生命，并赋予%d格挡。" % [executor["name"], target["name"], heal, bonus_block]
				else:
					state.message = "%s为%s恢复%d生命。" % [executor["name"], target["name"], heal]
				state.push_log(state.message)
				state.add_tile_effect(target["pos"], "+%d生命" % heal, Color("#8fffd8"), "heal", board_rect, impact_delay)
				state.add_visual_event("heal", target["uid"], target["pos"], 0.68, {"amount": heal, "vfx_kind": "heal", "message": "恢复"})
				played = true
	if played:
		state.add_visual_event("skill_release", executor["uid"], executor["pos"], release_duration, {
			"skill_kind": skill["kind"],
			"message": skill["title"],
			"action_hint": _action_hint_for_skill(skill["kind"]),
		})
		state.award_support_exp(executor, String(skill["kind"]), board_rect)
		state.battle_stats["skills_used"] = int(state.battle_stats.get("skills_used", 0)) + 1
		state._advance_tutorial("attack_or_skill", {"character_id": executor.get("character_id", ""), "skill_id": skill.get("id", "")})
		state.finish_selected_unit_action(executor)
	return played


func _action_hint_for_skill(skill_kind: String) -> String:
	match skill_kind:
		CARD_STRIKE, CARD_LANCE:
			return "attack"
		CARD_DASH:
			return "move"
	return "skill"


func _skill_release_duration(skill_kind: String) -> float:
	match skill_kind:
		CARD_STRIKE, CARD_LANCE:
			return 0.54
		CARD_DASH:
			return 0.42
	return 0.68
