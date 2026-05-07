class_name BattleState
extends RefCounted

const BattleProjectionScript := preload("res://scripts/core/BattleProjection.gd")
const BattleContentScript := preload("res://scripts/core/BattleContent.gd")
const SkillEffectsScript := preload("res://scripts/core/SkillEffects.gd")

const GRID_W := 10
const GRID_H := 8
const HAND_SIZE := 6
const ACTIVE_SKILL_LIMIT := 2
const DEFAULT_DEPLOYMENT_LIMIT := 3
const CHAPTER_DEPLOYMENT_LIMITS := {
	1: 3,
	2: 3,
	3: 4,
}
const START_ENERGY := 0
const ATTACK_EVENT_DURATION := 0.54
const MAGE_ATTACK_EVENT_DURATION := 0.66
const EXP_PER_LEVEL := 100
const EXP_DAMAGE := 10
const EXP_KILL := 30
const EXP_BOSS_BONUS := 20
const EXP_SUPPORT := 8

const CARD_STRIKE := BattleAssets.CARD_STRIKE
const CARD_LANCE := BattleAssets.CARD_LANCE
const CARD_DASH := BattleAssets.CARD_DASH
const CARD_GUARD := BattleAssets.CARD_GUARD
const CARD_ENGAGE := BattleAssets.CARD_ENGAGE
const CARD_HEAL := BattleAssets.CARD_HEAL

var content = BattleContentScript.new()
var skill_effects = SkillEffectsScript.new()
var rng := RandomNumberGenerator.new()
var energy := START_ENERGY
var turn := 1
var player_power := 0
var selected_card := -1
var selected_executor_uid := ""
var selected_card_owner_id := ""
var selected_unit_uid := ""
var action_mode := "select"
var moved_this_action := false
var pending_move_snapshot: Dictionary = {}
var character_panel_index := 0
var skill_page_index := 0
var active_hand_character_id := ""
var hover_card := -1
var hover_tile := Vector2i(-1, -1)
var hover_unit_uid := ""
var focused_enemy_uid := ""
var message := "选择未行动单位。"
var phase := "player"
var victory := false
var defeat := false
var effects: Array = []
var visual_events: Array = []
var unit_fx: Dictionary = {}
var battle_stats: Dictionary = {}
var battle_exp_events: Array = []
var battle_log: Array[String] = []
var log_expanded := false
var reward_options: Array = []
var reward_claimed := false
var selected_reward: Dictionary = {}
var selected_reward_owner := ""
var chapter_reward_history: Array = []
var recruitment_history: Array = []
var fallen_history: Array = []
var deck_view_open := false
var camp_view_open := false
var camp_selected_character_id := ""
var camp_rest_used := false
var camp_rest_bonus_pending := false
var camp_event_used := false
var camp_event_bonus := ""
var camp_event_choice: Dictionary = {}
var intro_dialogue_index := 0
var battle_index := 1
var chapter_index := 1
var battle_in_chapter := 1
var chapter_phase := "intro"
var run_deck_ids: Array = []
var party: Array = []
var promotion_options: Array = []
var promotion_claimed := false
var selected_promotion: Dictionary = {}
var current_encounter_id := ""
var battle_map_revision := 0
var tutorial_steps: Array = []
var tutorial_step_index := 0
var tutorial_completed := false
var post_tutorial_objective: Dictionary = {}
var battle_objective: Dictionary = {}
var inventory: Dictionary = {}

var draw_pile: Array = []
var discard_pile: Array = []
var hand: Array = []
var character_card_states: Dictionary = {}
var units: Array = []
var terrain: Dictionary = {}


func setup() -> void:
	rng.randomize()
	start_run()


func tick(delta: float) -> bool:
	var had_effects := effects.size() > 0
	var had_visual_events := visual_events.size() > 0
	for effect in effects:
		effect["age"] = effect["age"] + delta
	effects = effects.filter(func(effect): return effect["age"] < effect["duration"])
	for visual_event in visual_events:
		visual_event["age"] = visual_event["age"] + delta
	visual_events = visual_events.filter(func(visual_event): return visual_event["age"] < visual_event["duration"])
	var expired_unit_fx: Array = []
	for unit_id in unit_fx:
		unit_fx[unit_id]["age"] = unit_fx[unit_id]["age"] + delta
		if unit_fx[unit_id]["age"] >= unit_fx[unit_id]["duration"]:
			expired_unit_fx.append(unit_id)
	for unit_id in expired_unit_fx:
		unit_fx.erase(unit_id)
	var before_units := units.size()
	units = units.filter(func(u): return not bool(u.get("dead", false)) or unit_fx.has(u.get("uid", "")))
	return had_effects or had_visual_events or before_units != units.size() or not expired_unit_fx.is_empty() or not unit_fx.is_empty() or selected_card >= 0 or phase == "enemy" or hover_card >= 0


func start_run() -> void:
	battle_index = 1
	chapter_index = 1
	battle_in_chapter = 1
	chapter_phase = "intro"
	intro_dialogue_index = 0
	party = content.build_party()
	run_deck_ids = content.starter_deck_ids()
	promotion_options.clear()
	promotion_claimed = false
	selected_promotion.clear()
	current_encounter_id = ""
	tutorial_steps.clear()
	tutorial_step_index = 0
	tutorial_completed = false
	post_tutorial_objective.clear()
	battle_objective.clear()
	inventory = {"promotion_seal": 2}
	_reset_battle_shell()
	message = "苍纹圣庭遭袭。点击开始章节。"
	push_log(message)


func _reset_battle_shell() -> void:
	energy = START_ENERGY
	turn = 1
	player_power = 0
	selected_card = -1
	selected_executor_uid = ""
	selected_card_owner_id = ""
	selected_unit_uid = ""
	action_mode = "select"
	moved_this_action = false
	pending_move_snapshot.clear()
	character_panel_index = 0
	skill_page_index = 0
	active_hand_character_id = ""
	hover_card = -1
	hover_tile = Vector2i(-1, -1)
	hover_unit_uid = ""
	focused_enemy_uid = ""
	phase = "done"
	victory = false
	defeat = false
	effects.clear()
	visual_events.clear()
	unit_fx.clear()
	_reset_battle_stats()
	battle_log.clear()
	reward_options.clear()
	selected_reward.clear()
	selected_reward_owner = ""
	chapter_reward_history.clear()
	recruitment_history.clear()
	fallen_history.clear()
	deck_view_open = false
	camp_view_open = false
	camp_selected_character_id = ""
	camp_rest_used = false
	camp_rest_bonus_pending = false
	camp_event_used = false
	camp_event_bonus = ""
	camp_event_choice.clear()
	log_expanded = false
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	character_card_states.clear()
	units.clear()
	terrain.clear()
	current_encounter_id = ""
	tutorial_steps.clear()
	tutorial_step_index = 0
	tutorial_completed = false
	post_tutorial_objective.clear()
	battle_objective.clear()


func start_next_battle() -> void:
	if not victory or not reward_claimed:
		return
	close_chapter_camp()
	if chapter_phase == "reward" and battle_in_chapter < chapter_encounter_count():
		enter_chapter_map()
		return
	if battle_in_chapter >= chapter_encounter_count():
		start_promotion()
		return
	battle_index += 1
	battle_in_chapter += 1
	_start_battle()


func has_next_chapter() -> bool:
	return content.has_chapter(chapter_index + 1)


func start_next_chapter() -> void:
	if chapter_phase != "complete" or not has_next_chapter():
		return
	chapter_index += 1
	battle_in_chapter = 1
	battle_index = 1
	chapter_phase = "intro"
	intro_dialogue_index = 0
	promotion_options.clear()
	promotion_claimed = false
	selected_promotion.clear()
	_restore_surviving_party_deployment()
	_reset_battle_shell()
	message = "%s。点击开始章节。" % chapter_data().get("title", "下一章")
	push_log(message)


func enter_chapter_map() -> void:
	if not victory or not reward_claimed:
		return
	chapter_phase = "chapter_map"
	phase = "done"
	message = "选择下一处遭遇。"
	push_log(message)
	add_banner_event("章节地图")


func chapter_map_nodes() -> Array:
	var chapter := chapter_data()
	var encounters: Array = chapter.get("encounters", [])
	var nodes: Array = []
	for i in range(encounters.size()):
		var encounter_id := String(encounters[i])
		var battle_number := i + 1
		var status := "locked"
		if battle_number <= battle_in_chapter and reward_claimed:
			status = "completed"
		if battle_number == battle_in_chapter + 1 and reward_claimed:
			status = "current"
		if battle_number == battle_in_chapter and not reward_claimed:
			status = "current"
		if battle_number > battle_in_chapter + 1:
			status = "locked"
		nodes.append({
			"index": battle_number,
			"id": encounter_id,
			"name": content.encounter_name(encounter_id),
			"status": status,
			"boss": battle_number == encounters.size(),
		})
	return nodes


func chapter_map_current_node_index() -> int:
	return mini(battle_in_chapter + 1, chapter_data().get("encounters", []).size())


func chapter_encounter_count() -> int:
	return int(chapter_data().get("encounters", []).size())


func current_encounter_name() -> String:
	if current_encounter_id == "":
		return ""
	return content.encounter_name(current_encounter_id)


func current_battle_story_brief() -> String:
	if current_encounter_id == "":
		return ""
	return content.battle_story_brief(current_encounter_id)


func current_battle_objective_detail() -> String:
	if current_encounter_id == "":
		return ""
	var detail := content.battle_objective_detail(current_encounter_id)
	if detail != "":
		return detail
	var post_body := String(post_tutorial_objective.get("body", ""))
	if post_body != "":
		return post_body
	return tactical_tip()


func current_tilemap_scene_path() -> String:
	if current_encounter_id == "":
		return ""
	return content.battle_tilemap_scene_path(current_encounter_id)


func current_battlefield_background_path() -> String:
	if current_encounter_id == "":
		return ""
	return content.battle_background_path(current_encounter_id)


func battle_start_message() -> String:
	var name := current_encounter_name()
	var prefix := "第 %d/%d 战" % [battle_in_chapter, chapter_encounter_count()]
	var story := current_battle_story_brief()
	if name != "" and story != "":
		return "%s｜%s：%s" % [prefix, name, story]
	if name != "":
		return "%s｜%s。选择未行动单位。" % [prefix, name]
	return "%s开始。选择未行动单位。" % prefix


func can_enter_chapter_map_node(node_index: int) -> bool:
	return chapter_phase == "chapter_map" and reward_claimed and node_index == chapter_map_current_node_index()


func chapter_map_party_rows() -> Array:
	var rows: Array = []
	for member in party:
		if is_party_member_fallen(member):
			continue
		var skill_ids: Array = member.get("skill_ids", [])
		var learned_skills: Array = member.get("learned_skills", [])
		var learned_titles: Array[String] = []
		for skill_id in learned_skills:
			var card: Dictionary = content.create_card(String(skill_id))
			if not card.is_empty():
				learned_titles.append(String(card.get("title", skill_id)))
		rows.append({
			"character_id": member.get("character_id", ""),
			"name": member.get("name", ""),
			"class": class_name_for_member(member),
			"tier": int(member.get("class_tier", 1)),
			"level": int(member.get("level", 1)),
			"xp": int(member.get("xp", 0)),
			"passive": passive_text_for_member(member),
			"deployed": bool(member.get("deployed", false)),
			"skill_count": skill_ids.size(),
			"active_count": mini(skill_ids.size(), ACTIVE_SKILL_LIMIT),
			"equip_limit": ACTIVE_SKILL_LIMIT,
			"learned_count": learned_skills.size(),
			"learned_titles": learned_titles,
		})
	return rows


func deployed_character_ids() -> Array:
	var ids: Array = []
	for member in party:
		if bool(member.get("deployed", false)) and not is_party_member_fallen(member):
			ids.append(String(member.get("character_id", "")))
	return ids


func deployed_count() -> int:
	return deployed_character_ids().size()


func deployment_limit() -> int:
	return int(CHAPTER_DEPLOYMENT_LIMITS.get(chapter_index, DEFAULT_DEPLOYMENT_LIMIT))


func deployment_summary() -> String:
	return "出战 %d/%d" % [deployed_count(), deployment_limit()]


func is_character_deployed(character_id: String) -> bool:
	return deployed_character_ids().has(character_id)


func toggle_chapter_camp_deployment(character_id: String) -> void:
	if chapter_phase != "chapter_map" or character_id == "":
		return
	for member in party:
		if String(member.get("character_id", "")) != character_id:
			continue
		var currently_deployed := bool(member.get("deployed", false))
		if currently_deployed:
			if deployed_count() <= 1:
				message = "至少需要一名角色出战。"
				push_log(message)
				return
			member["deployed"] = false
			message = "%s调整为候补。" % member.get("name", character_id)
		else:
			if deployed_count() >= deployment_limit():
				message = "出战人数已满。先将一名角色调为候补。"
				push_log(message)
				return
			member["deployed"] = true
			message = "%s加入出战名单。" % member.get("name", character_id)
		push_log(message)
		return


func recruited_character_ids() -> Array:
	var ids: Array = []
	for member in party:
		if not is_party_member_fallen(member):
			ids.append(String(member.get("character_id", "")))
	return ids


func is_character_recruited(character_id: String) -> bool:
	return recruited_character_ids().has(character_id)


func battle_recruitment() -> Dictionary:
	return content.battle_recruitment(current_encounter_id)


func open_chapter_camp(character_id: String = "") -> void:
	if chapter_phase != "chapter_map":
		return
	if character_id == "":
		character_id = _first_party_character_id()
	camp_selected_character_id = character_id
	camp_view_open = true
	message = "查看营地整理。"


func close_chapter_camp() -> void:
	camp_view_open = false


func select_chapter_camp_member(character_id: String) -> void:
	if chapter_phase != "chapter_map":
		return
	camp_selected_character_id = character_id
	camp_view_open = true


func chapter_camp_selected_member_row() -> Dictionary:
	var selected_id := camp_selected_character_id
	if selected_id == "":
		selected_id = _first_party_character_id()
	for row in chapter_map_party_rows():
		if String(row.get("character_id", "")) == selected_id:
			return row
	return {}


func chapter_camp_skill_rows() -> Array:
	var selected_id := camp_selected_character_id
	if selected_id == "":
		selected_id = _first_party_character_id()
	var rows: Array = []
	for member in party:
		if String(member.get("character_id", "")) != selected_id:
			continue
		var learned_skills: Array = member.get("learned_skills", [])
		var index := 0
		for skill_id in member.get("skill_ids", []):
			var card: Dictionary = content.create_card(String(skill_id))
			rows.append({
				"id": String(skill_id),
				"title": card.get("title", skill_id),
				"kind": card.get("kind", ""),
				"tier": card.get("tier", "基础"),
				"cost": int(card.get("cost", 0)),
				"text": card.get("text", ""),
				"learned": learned_skills.has(skill_id),
				"equipped": index < ACTIVE_SKILL_LIMIT,
			})
			index += 1
		break
	return rows


func equip_chapter_camp_skill(skill_id: String) -> void:
	if chapter_phase != "chapter_map" or not camp_view_open or skill_id == "":
		return
	for member in party:
		if String(member.get("character_id", "")) != camp_selected_character_id:
			continue
		var skill_ids: Array = member.get("skill_ids", []).duplicate()
		if not skill_ids.has(skill_id):
			return
		skill_ids.erase(skill_id)
		skill_ids.push_front(skill_id)
		member["skill_ids"] = skill_ids
		message = "%s 将「%s」设为出战技能。" % [member.get("name", ""), content.create_card(skill_id).get("title", skill_id)]
		push_log(message)
		return


func can_use_chapter_camp_rest() -> bool:
	return chapter_phase == "chapter_map" and not camp_rest_used


func use_chapter_camp_rest() -> void:
	if not can_use_chapter_camp_rest():
		return
	camp_rest_used = true
	camp_rest_bonus_pending = true
	message = "队伍完成战术训练。下一场开局力量 +1。"
	push_log(message)
	add_banner_event("战术训练")


func chapter_camp_rest_summary() -> String:
	if camp_rest_bonus_pending:
		return "训练完成：下一场开局力量 +1"
	if camp_rest_used:
		return "本次营地训练已使用"
	return "可训练一次：下一场开局力量 +1"


func chapter_camp_pending_summary() -> String:
	var parts: Array[String] = []
	if camp_rest_bonus_pending:
		parts.append("训练：力量 +1")
	if camp_event_bonus != "" and not camp_event_choice.is_empty():
		parts.append("事件：%s" % chapter_camp_event_impact(camp_event_choice))
	if parts.is_empty():
		return "营地：可查看队伍、调整出战技能、休整或选择事件。"
	return "下一战加成｜%s" % " / ".join(parts)


func chapter_camp_summary() -> String:
	var parts: Array[String] = []
	if not fallen_history.is_empty():
		parts.append("牺牲：%s" % fallen_names_summary())
	if camp_rest_used:
		parts.append("完成训练")
	if camp_event_used and not camp_event_choice.is_empty():
		parts.append(String(camp_event_choice.get("title", "营地事件")))
	for entry in recruitment_history:
		parts.append("招募%s" % String(entry.get("name", "")))
	if parts.is_empty():
		return "本章未触发羁绊或训练。"
	return " / ".join(parts)


func chapter_camp_event_options() -> Array:
	var options: Array = []
	for option in content.chapter_camp_events(chapter_index):
		var speaker_id := portrait_id_for_speaker(String(option.get("speaker", "")))
		if speaker_id != "" and is_character_fallen(speaker_id):
			continue
		options.append(option)
	return options


func can_choose_chapter_camp_event(index: int) -> bool:
	return chapter_phase == "chapter_map" and camp_view_open and not camp_event_used and index >= 0 and index < chapter_camp_event_options().size()


func choose_chapter_camp_event(index: int) -> void:
	if not can_choose_chapter_camp_event(index):
		return
	var option: Dictionary = chapter_camp_event_options()[index]
	camp_event_used = true
	camp_event_bonus = String(option.get("bonus", ""))
	camp_event_choice = option.duplicate(true)
	message = "%s提出「%s」。" % [option.get("speaker", ""), option.get("title", "")]
	push_log(message)
	add_banner_event("营地事件")


func chapter_camp_event_summary() -> String:
	if camp_event_used and not camp_event_choice.is_empty():
		return String(camp_event_choice.get("summary", "营地事件已选择"))
	return "可选择一次营地事件，影响下一场开局。"


func chapter_camp_event_impact(option: Dictionary) -> String:
	var amount := int(option.get("amount", _default_camp_event_amount(String(option.get("bonus", "")))))
	match String(option.get("bonus", "")):
		"power":
			return "下一战力量 +%d" % amount
		"max_hp":
			return "全员生命上限 +%d" % amount
		"block":
			return "全员开局格挡 +%d" % amount
	return "下一战生效"


func selected_chapter_camp_event_id() -> String:
	return String(camp_event_choice.get("id", ""))


func _first_party_character_id() -> String:
	for member in party:
		if not is_party_member_fallen(member):
			return String(member.get("character_id", ""))
	return ""


func begin_chapter_battle() -> void:
	if chapter_phase != "intro":
		return
	battle_in_chapter = 1
	battle_index = 1
	_start_battle()


func advance_intro() -> void:
	var dialogue: Array = chapter_dialogue()
	if intro_dialogue_index < dialogue.size() - 1:
		intro_dialogue_index += 1
	else:
		begin_chapter_battle()


func start_promotion() -> void:
	victory = true
	phase = "done"
	reward_claimed = true
	close_chapter_camp()
	promotion_claimed = false
	promotion_options = []
	selected_promotion.clear()
	for member in party:
		if is_party_member_fallen(member):
			continue
		if can_member_promote(member):
			promotion_options.append_array(content.promotion_options(member))
	if promotion_options.is_empty():
		chapter_phase = "complete"
		message = "章节突破。当前无人满足转职条件，已进入章节结算。"
		push_log(message)
		add_banner_event("章节完成")
		return
	chapter_phase = "promotion"
	message = "章节突破。可消耗转职纹章，为10级以上角色转职。"
	push_log(message)
	add_banner_event("转职选择")


func claim_promotion(index: int) -> void:
	if promotion_claimed or index < 0 or index >= promotion_options.size():
		return
	if promotion_seal_count() <= 0:
		message = "没有转职纹章。"
		push_log(message)
		return
	var option: Dictionary = promotion_options[index]
	selected_promotion = option.duplicate(true)
	for member in party:
		if member.get("character_id", "") != option.get("character_id", ""):
			continue
		if not can_member_promote(member):
			message = "%s尚未满足转职条件。" % character_name(option.get("character_id", ""))
			push_log(message)
			return
		member["class_id"] = option["class_id"]
		member["class_tier"] = option["tier"]
		member["class_tags"] = option["tags"]
		member["passive_id"] = option["passive_id"]
		consume_promotion_seal()
		break
	promotion_claimed = true
	chapter_phase = "complete"
	message = "%s 消耗转职纹章，完成转职：%s。" % [character_name(option.get("character_id", "")), option["name"]]
	push_log(message)
	add_banner_event("章节完成")


func promotion_role_summary(option: Dictionary) -> String:
	var passive_id := String(option.get("passive_id", ""))
	match passive_id:
		"duel_flash":
			return "近战击破后续航，适合主动收割。"
		"royal_tactics":
			return "强化指挥增益，适合团队爆发。"
		"seraphic_grace":
			return "治疗量提升，适合稳定续航。"
		"rune_prayer":
			return "圣辉兼具指挥，适合支援节奏。"
		"iron_oath":
			return "开场自带格挡，适合前排承伤。"
		"sunlance_drive":
			return "枪术伤害提升，适合攻守转换。"
	return "二阶职业。"


func promotion_stat_summary(option: Dictionary) -> String:
	return "生命 +%d  攻击 +%d" % [int(option.get("hp_bonus", 0)), int(option.get("atk_bonus", 0))]


func promotion_confirmation_title() -> String:
	if selected_promotion.is_empty():
		return "章节完成"
	return "%s 转职为 %s" % [character_name(selected_promotion.get("character_id", "")), selected_promotion.get("name", "")]


func promotion_confirmation_note() -> String:
	if selected_promotion.is_empty():
		return "转职条件：10级以上，并消耗1个转职纹章。"
	return "%s｜%s｜剩余纹章 %d" % [promotion_stat_summary(selected_promotion), promotion_role_summary(selected_promotion), promotion_seal_count()]


func promotion_seal_count() -> int:
	return int(inventory.get("promotion_seal", 0))


func consume_promotion_seal() -> void:
	inventory["promotion_seal"] = maxi(0, promotion_seal_count() - 1)


func can_member_promote(member: Dictionary) -> bool:
	return int(member.get("class_tier", 1)) <= 1 and int(member.get("level", 1)) >= 10 and promotion_seal_count() > 0


func promotion_requirement_text(member: Dictionary) -> String:
	var level := int(member.get("level", 1))
	if int(member.get("class_tier", 1)) > 1:
		return "已完成转职"
	if level < 10:
		return "需要 Lv10"
	if promotion_seal_count() <= 0:
		return "缺少转职纹章"
	return "可转职"


func _start_battle() -> void:
	chapter_phase = "battle"
	current_encounter_id = content.encounter_for_battle(chapter_index, battle_in_chapter)
	battle_map_revision += 1
	energy = START_ENERGY
	turn = 1
	player_power = 0
	if camp_rest_bonus_pending:
		player_power = 1
		camp_rest_bonus_pending = false
	selected_card = -1
	selected_executor_uid = ""
	selected_card_owner_id = ""
	selected_unit_uid = ""
	action_mode = "select"
	moved_this_action = false
	pending_move_snapshot.clear()
	skill_page_index = 0
	active_hand_character_id = ""
	hover_card = -1
	hover_tile = Vector2i(-1, -1)
	hover_unit_uid = ""
	focused_enemy_uid = ""
	phase = "player"
	victory = false
	defeat = false
	effects.clear()
	visual_events.clear()
	unit_fx.clear()
	_reset_battle_stats()
	battle_log.clear()
	reward_options.clear()
	reward_claimed = false
	selected_reward.clear()
	selected_reward_owner = ""
	deck_view_open = false
	camp_view_open = false
	camp_selected_character_id = ""
	promotion_options.clear()
	selected_promotion.clear()
	log_expanded = false
	message = battle_start_message()
	push_log(message)
	tutorial_steps = content.battle_tutorial_steps(current_encounter_id)
	tutorial_step_index = 0
	tutorial_completed = tutorial_steps.is_empty()
	post_tutorial_objective = content.battle_post_tutorial_objective(current_encounter_id)
	battle_objective = content.battle_objective(current_encounter_id)
	units = content.build_encounter(current_encounter_id, party)
	_setup_battlefield_terrain(current_encounter_id)
	_remove_undeployed_party_units_from_battle()
	_add_missing_party_units_to_battle()
	_scale_encounter_for_battle()
	_apply_battle_start_passives()
	_apply_pending_camp_event()
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	character_card_states.clear()
	_setup_character_card_states()
	_clamp_character_panel_index()
	_sync_active_hand()
	add_banner_event("我方行动")
	add_objective_event()
	if has_tutorial_step():
		add_visual_event("tutorial", "", Vector2i.ZERO, 2.6, {"message": tutorial_title(), "detail": tutorial_body()})


func _apply_pending_camp_event() -> void:
	if camp_event_bonus == "":
		return
	var amount := int(camp_event_choice.get("amount", _default_camp_event_amount(camp_event_bonus)))
	match camp_event_bonus:
		"power":
			player_power += amount
		"max_hp":
			for unit in get_player_units():
				unit["max_hp"] = int(unit.get("max_hp", 0)) + amount
				unit["hp"] = int(unit.get("hp", 0)) + amount
		"block":
			for unit in get_player_units():
				unit["block"] = int(unit.get("block", 0)) + amount
	message = String(camp_event_choice.get("summary", "营地事件生效。"))
	push_log(message)
	camp_event_bonus = ""


func _default_camp_event_amount(bonus: String) -> int:
	match bonus:
		"power":
			return 1
		"max_hp":
			return 2
		"block":
			return 4
	return 0


func _add_missing_party_units_to_battle() -> void:
	var present_ids: Array = []
	for unit in units:
		var character_id := String(unit.get("character_id", ""))
		if character_id != "":
			present_ids.append(character_id)
	var spawn_index := units.size()
	for member in party:
		if is_party_member_fallen(member):
			continue
		var character_id := String(member.get("character_id", ""))
		if character_id == "" or present_ids.has(character_id) or not bool(member.get("deployed", false)):
			continue
		var spawn_tile := _next_party_spawn_tile()
		if spawn_tile == Vector2i(-1, -1):
			continue
		units.append(content.create_party_unit(member, spawn_tile, spawn_index))
		present_ids.append(character_id)
		spawn_index += 1


func _next_party_spawn_tile() -> Vector2i:
	for tile in [Vector2i(0, 4), Vector2i(0, 3), Vector2i(1, 5), Vector2i(2, 4), Vector2i(2, 3), Vector2i(2, 5)]:
		if in_bounds(tile) and is_walkable(tile) and unit_at(tile) == null:
			return tile
	return Vector2i(-1, -1)


func _remove_undeployed_party_units_from_battle() -> void:
	var recruitment_unit_key := String(battle_recruitment().get("unit", ""))
	var filtered_units: Array = []
	for unit in units:
		if String(unit.get("team", "")) != "player":
			filtered_units.append(unit)
			continue
		var character_id := String(unit.get("character_id", ""))
		if is_character_fallen(character_id):
			continue
		if String(unit.get("unit_key", "")) == recruitment_unit_key and not is_character_recruited(character_id):
			filtered_units.append(unit)
			continue
		if character_id == "" or is_character_deployed(character_id):
			filtered_units.append(unit)
	units = filtered_units


func _battle_deck_ids() -> Array:
	var ids := run_deck_ids.duplicate()
	for member in party:
		if is_party_member_fallen(member):
			continue
		for skill_id in member.get("skill_ids", []):
			if not ids.has(skill_id):
				ids.append(skill_id)
		for skill_id in member.get("learned_skills", []):
			if not ids.has(skill_id):
				ids.append(skill_id)
	return ids


func _setup_character_card_states() -> void:
	for unit in get_player_units():
		var character_id: String = unit.get("character_id", "")
		if character_id == "":
			continue
		character_card_states[character_id] = {
			"skills": _skill_cards_for_character(character_id),
			"draw_pile": [],
			"discard_pile": [],
			"hand": [],
		}
	_sync_active_hand()


func _refill_all_character_hands(show_events: bool = true) -> void:
	# Skills are fixed per character now; there is no in-battle draw/refill loop.
	if show_events:
		pass
	_sync_active_hand()


func _skill_ids_for_character(character_id: String) -> Array:
	if is_character_fallen(character_id):
		return []
	for member in party:
		if member.get("character_id", "") != character_id:
			continue
		var ids: Array = []
		for skill_id in member.get("skill_ids", []):
			if not ids.has(skill_id):
				ids.append(skill_id)
			if ids.size() >= ACTIVE_SKILL_LIMIT:
				break
		return ids
	var base_ids: Array = []
	for skill_id in content.base_skill_ids(character_id):
		if not base_ids.has(skill_id):
			base_ids.append(skill_id)
		if base_ids.size() >= ACTIVE_SKILL_LIMIT:
			break
	return base_ids


func _skill_cards_for_character(character_id: String) -> Array:
	var skills: Array = []
	for skill_id in _skill_ids_for_character(character_id):
		var skill := content.create_card(String(skill_id))
		if not skill.is_empty():
			skills.append(skill)
	return skills


func _scale_encounter_for_battle() -> void:
	if battle_index <= 1:
		return
	var hp_bonus := (battle_index - 1) * 3
	var atk_bonus := floori(float(battle_index - 1) * 0.5)
	for unit in units:
		if unit["team"] != "enemy":
			continue
		unit["max_hp"] = int(unit["max_hp"]) + hp_bonus
		unit["hp"] = int(unit["max_hp"])
		unit["atk"] = int(unit["atk"]) + atk_bonus
	message = "%s｜敌军阵线增强。" % current_encounter_name()
	push_log(message)


func _apply_battle_start_passives() -> void:
	for unit in get_player_units():
		unit["acted"] = false
		if unit.get("passive_id", "") == "iron_oath":
			unit["block"] = int(unit["block"]) + 4


func _setup_battlefield_terrain(encounter_id: String) -> void:
	terrain = content.battlefield_terrain(encounter_id)


func replace_battlefield_terrain(next_terrain: Dictionary) -> void:
	terrain = next_terrain.duplicate(true)
	battle_map_revision += 1


func draw_cards(count: int) -> void:
	if count > 0:
		message = "战斗中技能固定在角色身上。"
		push_log(message)
	_sync_active_hand()


func _draw_cards_for_character(character_id: String, count: int, show_event: bool = true) -> void:
	if character_id != "" and count > 0 and show_event:
		var unit := unit_for_character_id(character_id)
		if not unit.is_empty():
			add_visual_event("skill_refresh", unit.get("uid", ""), unit.get("pos", Vector2i.ZERO), 0.36, {"amount": 0, "message": "技能固定"})


func push_log(text: String) -> void:
	if text == "":
		return
	if battle_log.size() > 0 and battle_log[-1] == text:
		return
	battle_log.append(text)
	if battle_log.size() > 8:
		battle_log.pop_front()


func toggle_log() -> void:
	log_expanded = not log_expanded


func _reset_battle_stats() -> void:
	battle_stats = {
		"skills_used": 0,
		"enemies_defeated": 0,
		"damage_taken": 0,
		"highest_damage": 0,
		"xp_gained": 0,
		"turns_finished": 1,
	}
	battle_exp_events.clear()


func award_support_exp(unit: Dictionary, skill_kind: String, board_rect: Rect2 = Rect2()) -> void:
	if skill_kind in [CARD_STRIKE, CARD_LANCE]:
		return
	award_exp_for_unit(unit, EXP_SUPPORT, "支援", board_rect)


func award_exp_for_unit(unit: Dictionary, amount: int, reason: String, board_rect: Rect2 = Rect2()) -> int:
	if unit.is_empty():
		return 0
	return award_exp(String(unit.get("character_id", "")), amount, reason, unit, board_rect)


func award_exp(character_id: String, amount: int, reason: String, unit: Dictionary = {}, board_rect: Rect2 = Rect2()) -> int:
	if character_id == "" or amount <= 0:
		return 0
	var member := _party_member_by_character_id(character_id)
	if member.is_empty():
		return 0
	var before_level := int(member.get("level", 1))
	var before_xp := int(member.get("xp", 0))
	var next_xp := before_xp + amount
	var level_ups := 0
	while next_xp >= EXP_PER_LEVEL:
		next_xp -= EXP_PER_LEVEL
		level_ups += 1
	member["level"] = before_level + level_ups
	member["xp"] = next_xp
	if not unit.is_empty():
		unit["level"] = member["level"]
		unit["xp"] = member["xp"]
		if level_ups > 0:
			_apply_level_up_growth_to_unit(unit, before_level, level_ups)
			add_tile_effect(unit["pos"], "LV UP", Color("#fff4ba"), "guard", board_rect, 0.12, 0.95)
			add_visual_event("level_up", unit["uid"], unit["pos"], 1.15, {"message": "升级"})
		else:
			add_tile_effect(unit["pos"], "+%dEXP" % amount, Color("#79d8ff"), "guard", board_rect, 0.08, 0.62)
	var event := {
		"character_id": character_id,
		"name": member.get("name", character_id),
		"amount": amount,
		"reason": reason,
		"before_level": before_level,
		"before_xp": before_xp,
		"after_level": int(member.get("level", 1)),
		"after_xp": int(member.get("xp", 0)),
		"level_ups": level_ups,
	}
	battle_exp_events.append(event)
	battle_stats["xp_gained"] = int(battle_stats.get("xp_gained", 0)) + amount
	push_log("%s +%dEXP（%s）" % [member.get("name", character_id), amount, reason])
	return amount


func battle_exp_summary(max_rows: int = 3) -> String:
	if battle_exp_events.is_empty():
		return "经验：本战暂无成长。"
	var grouped: Dictionary = {}
	for event in battle_exp_events:
		var character_id := String(event.get("character_id", ""))
		if character_id == "":
			continue
		if not grouped.has(character_id):
			grouped[character_id] = event.duplicate(true)
		else:
			grouped[character_id]["amount"] = int(grouped[character_id].get("amount", 0)) + int(event.get("amount", 0))
			grouped[character_id]["after_level"] = int(event.get("after_level", grouped[character_id].get("after_level", 1)))
			grouped[character_id]["after_xp"] = int(event.get("after_xp", grouped[character_id].get("after_xp", 0)))
			grouped[character_id]["level_ups"] = int(grouped[character_id].get("level_ups", 0)) + int(event.get("level_ups", 0))
	var rows: Array[String] = []
	for character_id in grouped.keys():
		var event: Dictionary = grouped[character_id]
		var suffix := "Lv%d %d/%d" % [int(event.get("after_level", 1)), int(event.get("after_xp", 0)), EXP_PER_LEVEL]
		if int(event.get("level_ups", 0)) > 0:
			suffix = "升级至%s" % suffix
		rows.append("%s +%d → %s" % [String(event.get("name", character_id)), int(event.get("amount", 0)), suffix])
		if rows.size() >= max_rows:
			break
	return "经验：%s" % " / ".join(rows)


func _award_combat_exp(attacker: Dictionary, target: Dictionary, final_damage: int, defeated: bool, board_rect: Rect2) -> void:
	if attacker.is_empty() or target.is_empty():
		return
	if String(attacker.get("team", "")) != "player" or String(target.get("team", "")) != "enemy":
		return
	var amount := 0
	var reason := "命中"
	if final_damage > 0:
		amount += EXP_DAMAGE
	if defeated:
		amount += EXP_KILL
		reason = "击破"
		if String(target.get("unit_key", "")).contains("boss"):
			amount += EXP_BOSS_BONUS
			reason = "Boss击破"
	if amount > 0:
		award_exp_for_unit(attacker, amount, reason, board_rect)


func _apply_level_up_growth_to_unit(unit: Dictionary, before_level: int, level_ups: int) -> void:
	for i in range(level_ups):
		var new_level := before_level + i + 1
		var hp_gain := 2
		var atk_gain := 1 if new_level % 2 == 0 else 0
		var role := String(unit.get("role", ""))
		if role in ["lance", "guard"]:
			hp_gain += 1
		elif role == "faith":
			hp_gain = 1
			if new_level % 3 == 0:
				atk_gain += 1
		unit["max_hp"] = int(unit.get("max_hp", 0)) + hp_gain
		unit["hp"] = int(unit.get("hp", 0)) + hp_gain
		unit["atk"] = int(unit.get("atk", 0)) + atk_gain


func _party_member_by_character_id(character_id: String) -> Dictionary:
	for member in party:
		if String(member.get("character_id", "")) == character_id:
			return member
	return {}


func generate_reward_options() -> void:
	if reward_options.size() > 0:
		return
	var pool := []
	for skill_id in content.learning_reward_pool(chapter_index, battle_in_chapter):
		if _reward_owner_available(content.create_card(String(skill_id))) and not _party_has_skill_id(String(skill_id)):
			pool.append(String(skill_id))
	if pool.is_empty():
		for skill_id in content.learning_reward_pool(chapter_index, battle_in_chapter):
			if _reward_owner_available(content.create_card(String(skill_id))):
				pool.append(String(skill_id))
	pool.shuffle()
	for i in range(mini(2, pool.size())):
		reward_options.append(content.create_card(pool[i]))


func _reward_owner_available(reward: Dictionary) -> bool:
	return reward_owner_character_id(reward) != ""


func _party_has_skill_id(skill_id: String) -> bool:
	for member in party:
		if is_party_member_fallen(member):
			continue
		if member.get("skill_ids", []).has(skill_id) or member.get("learned_skills", []).has(skill_id):
			return true
	return false


func claim_reward(index: int) -> void:
	if reward_claimed or index < 0 or index >= reward_options.size():
		return
	var reward: Dictionary = reward_options[index]
	selected_reward_owner = learn_skill_reward(reward)
	selected_reward = reward.duplicate(true)
	chapter_reward_history.append({
		"owner": selected_reward_owner,
		"title": reward.get("title", ""),
		"reason": reward_owner_reason(reward),
	})
	reward_claimed = true
	deck_view_open = false
	message = "%s领悟「%s」。" % [selected_reward_owner, reward["title"]]
	push_log(message)
	add_banner_event("技能领悟")


func learn_skill_reward(reward: Dictionary) -> String:
	var owner_id := reward_owner_character_id(reward)
	for member in party:
		if is_party_member_fallen(member):
			continue
		if member.get("character_id", "") != owner_id:
			continue
		var learned: Array = member.get("learned_skills", [])
		var skill_ids: Array = member.get("skill_ids", []).duplicate()
		var reward_id: String = reward.get("id", "")
		if not learned.has(reward_id):
			learned.append(reward_id)
			member["learned_skills"] = learned
			if not skill_ids.has(reward_id):
				skill_ids.append(reward_id)
				member["skill_ids"] = skill_ids
			if not run_deck_ids.has(reward_id):
				run_deck_ids.append(reward_id)
		else:
			member["level"] = int(member.get("level", 1)) + 1
		return member.get("name", owner_id)
	return character_name(owner_id)


func reward_owner_character_id(reward: Dictionary) -> String:
	var tags: Array = reward.get("executor_tags", [])
	if tags.has("faith") and not is_character_fallen("liora"):
		return "liora"
	if tags.has("lance") and not is_character_fallen("kael"):
		return "kael"
	if not is_character_fallen("astra"):
		return "astra"
	return first_surviving_character_id()


func reward_owner_reason(reward: Dictionary) -> String:
	var owner_id := reward_owner_character_id(reward)
	match owner_id:
		"liora":
			return "圣辉/治疗定位"
		"kael":
			return "枪卫/格挡定位"
	return "剑术/指挥定位"


func reward_card_summary(reward: Dictionary) -> String:
	var owner_id := reward_owner_character_id(reward)
	return "%s可领悟｜%s" % [character_name(owner_id), reward_owner_reason(reward)]


func toggle_deck_view() -> void:
	if not victory or not reward_claimed:
		return
	deck_view_open = not deck_view_open


func run_deck_count() -> int:
	return run_deck_ids.size()


func reward_confirmation_title() -> String:
	if selected_reward.is_empty():
		return "技能已领悟"
	return "%s领悟「%s」" % [selected_reward_owner, selected_reward.get("title", "")]


func reward_confirmation_note() -> String:
	if selected_reward.is_empty():
		return "技能会保留在角色成长中。"
	return "%s。已加入领悟列表，营地可设为出战技能。" % reward_owner_reason(selected_reward)


func chapter_reward_summary() -> String:
	if chapter_reward_history.is_empty():
		return "本章尚未领悟新技能。"
	var parts: Array[String] = []
	for entry in chapter_reward_history:
		parts.append("%s「%s」" % [String(entry.get("owner", "")), String(entry.get("title", ""))])
	return " / ".join(parts)


func chapter_battle_summary() -> String:
	var loss_note := "无牺牲" if fallen_history.is_empty() else "牺牲：%s" % fallen_names_summary()
	return "最终战评价 %s｜%s｜%s" % [battle_grade(), battle_result_summary(), loss_note]


func chapter_next_step_summary() -> String:
	return "下一步：延展第二章角色羁绊、招募后的个人事件和更明确的章节目标。"


func deck_card_counts() -> Array:
	var rows: Array = []
	for member in party:
		if is_party_member_fallen(member):
			continue
		for skill_id in member.get("skill_ids", []):
			var card: Dictionary = content.create_card(String(skill_id))
			rows.append({
				"id": skill_id,
				"title": card["title"],
				"kind": card["kind"],
				"tier": card["tier"],
				"owner": member.get("name", ""),
				"count": 1,
			})
	rows.sort_custom(func(a, b): return String(a["owner"]) < String(b["owner"]))
	return rows


func chapter_data() -> Dictionary:
	return content.chapter_data(chapter_index)


func chapter_dialogue() -> Array:
	return chapter_data().get("dialogue", [])


func current_dialogue_line() -> Dictionary:
	var dialogue := chapter_dialogue()
	if dialogue.is_empty():
		return {"speaker": "", "text": ""}
	var index := clampi(intro_dialogue_index, 0, dialogue.size() - 1)
	return dialogue[index]


func current_dialogue_portrait_id() -> String:
	var line := current_dialogue_line()
	var explicit_id: String = String(line.get("portrait_id", ""))
	if explicit_id != "":
		return explicit_id
	return portrait_id_for_speaker(String(line.get("speaker", "")))


func current_dialogue_background_id() -> String:
	var line := current_dialogue_line()
	var explicit_id := String(line.get("bg", ""))
	if explicit_id != "":
		return explicit_id
	return String(chapter_data().get("dialogue_bg", ""))


func portrait_id_for_speaker(speaker: String) -> String:
	match speaker:
		"阿斯特拉":
			return "astra"
		"莉奥拉":
			return "liora"
		"凯尔":
			return "kael"
	return ""


func character_name(character_id: String) -> String:
	for member in party:
		if member.get("character_id", "") == character_id:
			return member.get("name", character_id)
	return character_id


func first_surviving_character_id() -> String:
	for member in party:
		if not is_party_member_fallen(member):
			return String(member.get("character_id", ""))
	return ""


func is_party_member_fallen(member: Dictionary) -> bool:
	return bool(member.get("fallen", false))


func is_character_fallen(character_id: String) -> bool:
	if character_id == "":
		return false
	for member in party:
		if String(member.get("character_id", "")) == character_id:
			return is_party_member_fallen(member)
	return false


func fallen_names_summary() -> String:
	var names: Array[String] = []
	for entry in fallen_history:
		var name := String(entry.get("name", ""))
		if name != "" and not names.has(name):
			names.append(name)
	return "、".join(names)


func living_party_count() -> int:
	var count := 0
	for member in party:
		if not is_party_member_fallen(member):
			count += 1
	return count


func _mark_party_member_fallen(character_id: String, source_unit: Dictionary = {}) -> void:
	if character_id == "" or is_character_fallen(character_id):
		return
	for member in party:
		if String(member.get("character_id", "")) != character_id:
			continue
		member["fallen"] = true
		member["deployed"] = false
		var name := String(member.get("name", source_unit.get("name", character_id)))
		fallen_history.append({
			"character_id": character_id,
			"name": name,
			"chapter": chapter_index,
			"battle": battle_in_chapter,
		})
		if character_id == "astra":
			message = "阿斯特拉倒下，战线崩溃。"
			push_log(message)
		else:
			message = "%s阵亡，后续章节将无法出战。" % name
			push_log(message)
			add_banner_event("%s阵亡" % name)
		return


func _sync_player_death_to_party(unit: Dictionary) -> void:
	if unit.is_empty() or String(unit.get("team", "")) != "player":
		return
	var character_id := String(unit.get("character_id", ""))
	if character_id == "":
		return
	_mark_party_member_fallen(character_id, unit)


func _restore_surviving_party_deployment() -> void:
	var deployed := 0
	for member in party:
		if is_party_member_fallen(member):
			member["deployed"] = false
			continue
		if deployed < deployment_limit():
			member["deployed"] = true
			deployed += 1
		else:
			member["deployed"] = false


func class_name_for_member(member: Dictionary) -> String:
	return content.get_class_name(member.get("class_id", ""))


func passive_text_for_member(member: Dictionary) -> String:
	return content.passive_text(member.get("passive_id", ""))


func select_card(index: int, rects: Array, rect_index: int = -1) -> void:
	select_skill(index, rects, rect_index)


func skill_page_count(visible_count: int) -> int:
	var count := maxi(1, visible_count)
	return maxi(1, ceili(float(hand.size()) / float(count)))


func skill_page_start(visible_count: int) -> int:
	var count := maxi(1, visible_count)
	var page_count := skill_page_count(count)
	skill_page_index = clampi(skill_page_index, 0, page_count - 1)
	return skill_page_index * count


func cycle_skill_page(step: int, visible_count: int) -> void:
	var page_count := skill_page_count(visible_count)
	if page_count <= 1:
		skill_page_index = 0
	else:
		skill_page_index = posmod(skill_page_index + step, page_count)
	hover_card = -1


func select_skill(index: int, rects: Array = [], rect_index: int = -1) -> void:
	_sync_active_hand()
	if index < 0 or index >= hand.size():
		return
	if chapter_phase != "battle" or phase != "player":
		return
	var unit := selected_unit()
	if unit.is_empty():
		message = "请先选择一名未行动单位。"
		push_log(message)
		return
	if bool(unit.get("acted", false)):
		message = "%s已经行动过。" % unit.get("name", "该单位")
		push_log(message)
		return
	if action_mode != "command":
		message = "先决定移动位置，再选择攻击、技能或待机。"
		push_log(message)
		return
	if selected_card == index:
		cancel_card_selection("取消技能。")
		return
	var skill: Dictionary = hand[index]
	if not _unit_owns_skill(unit, skill) or not can_unit_execute_card(unit, skill):
		message = "%s无法使用「%s」。" % [unit.get("name", "队员"), skill.get("title", "技能")]
		push_log(message)
		cancel_card_selection()
		hover_tile = Vector2i(-1, -1)
		return
	selected_card = index
	selected_card_owner_id = unit.get("character_id", "")
	selected_executor_uid = unit.get("uid", "")
	message = "%s准备「%s」，选择目标格。" % [unit.get("name", ""), skill.get("title", "")]
	push_log(message)
	var effect_rect_index := index if rect_index < 0 else rect_index
	if effect_rect_index >= 0 and effect_rect_index < rects.size():
		add_screen_effect(rects[effect_rect_index].get_center(), "技能", Color("#79f2c9"), "select")


func cancel_card_selection(log_message: String = "") -> void:
	selected_card = -1
	selected_executor_uid = ""
	selected_card_owner_id = ""
	hover_card = -1
	if log_message != "":
		message = log_message
		push_log(message)


func try_play_card(tile: Vector2i, board_rect: Rect2) -> bool:
	return skill_effects.apply_selected_skill(self, tile, board_rect)


func handle_card_board_click(tile: Vector2i, board_rect: Rect2) -> bool:
	if selected_card < 0 or selected_card >= hand.size():
		return false
	return try_play_card(tile, board_rect)


func get_valid_tiles() -> Array:
	if chapter_phase == "battle":
		if selected_card >= 0 and selected_card < hand.size():
			return skill_effects.valid_tiles(self)
		if action_mode == "move":
			var move_tiles := movement_tiles_for_selected()
			var unit := selected_unit()
			if not unit.is_empty() and not move_tiles.has(unit["pos"]):
				move_tiles.append(unit["pos"])
			return move_tiles
		if action_mode == "command":
			return attack_tiles_for_selected()
	return []


func select_unit_at(tile: Vector2i) -> bool:
	if phase != "player" or chapter_phase != "battle":
		return false
	var unit = unit_at(tile)
	if unit == null or unit["team"] != "player" or bool(unit.get("acted", false)):
		return false
	cancel_card_selection()
	selected_unit_uid = unit["uid"]
	focus_character_uid(selected_unit_uid)
	action_mode = "move"
	moved_this_action = false
	pending_move_snapshot.clear()
	_sync_active_hand()
	message = "选择%s的移动位置；点击自身格可原地行动。" % unit["name"]
	push_log(message)
	_advance_tutorial("select_unit", {"character_id": unit.get("character_id", ""), "tile": tile})
	return true


func act_on_tile(tile: Vector2i, board_rect: Rect2) -> bool:
	var unit := selected_unit()
	if unit.is_empty() or bool(unit.get("acted", false)):
		return false
	if action_mode == "move":
		if tile == unit["pos"]:
			action_mode = "command"
			moved_this_action = false
			pending_move_snapshot.clear()
			message = "%s原地待命，选择攻击、技能或待机。" % unit["name"]
			push_log(message)
			_advance_tutorial("move_or_wait", {"character_id": unit.get("character_id", ""), "tile": tile})
			return true
		if movement_tiles_for_selected().has(tile):
			var old_pos: Vector2i = unit["pos"]
			pending_move_snapshot = {
				"uid": unit["uid"],
				"from_pos": old_pos,
				"to_pos": tile,
				"hp": unit["hp"],
				"block": unit["block"],
			}
			unit["pos"] = tile
			moved_this_action = true
			action_mode = "command"
			message = "%s移动。选择攻击、技能或待机。" % unit["name"]
			push_log(message)
			_mark_unit_fx(unit, "move")
			add_visual_event("move", unit["uid"], tile, 0.36, {"from_tile": old_pos, "to_tile": tile, "message": "移动"})
			_apply_tile_end_effect(unit, board_rect)
			check_end_state()
			_advance_tutorial("move_or_wait", {"character_id": unit.get("character_id", ""), "tile": tile})
			return true
		var target = enemy_at(tile)
		if target != null and attack_tiles_for_unit(unit).has(tile):
			action_mode = "command"
			return unit_attack(unit, target, board_rect)
	elif action_mode == "command":
		var target = enemy_at(tile)
		if target != null and attack_tiles_for_selected().has(tile):
			return unit_attack(unit, target, board_rect)
	return false


func wait_selected_unit() -> void:
	var unit := selected_unit()
	if unit.is_empty():
		return
	finish_selected_unit_action(unit, "%s待机。" % unit["name"])


func selected_unit() -> Dictionary:
	if selected_unit_uid == "":
		return {}
	return unit_by_uid(selected_unit_uid)


func movement_tiles_for_selected() -> Array:
	return movement_tiles_for_unit(selected_unit())


func movement_tiles_for_unit(unit: Dictionary) -> Array:
	if unit.is_empty():
		return []
	var result: Array = []
	var frontier: Array = [{"tile": unit["pos"], "cost": 0}]
	var visited := {unit["pos"]: 0}
	var move_range: int = int(unit.get("move_range", 3))
	while not frontier.is_empty():
		var current: Dictionary = frontier.pop_front()
		var tile: Vector2i = current["tile"]
		var cost: int = current["cost"]
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next_tile: Vector2i = tile + d
			var next_cost := cost + terrain_move_cost(next_tile)
			if not in_bounds(next_tile) or not is_walkable(next_tile) or next_cost > move_range:
				continue
			var occupant = unit_at(next_tile)
			if occupant != null and occupant["uid"] != unit["uid"]:
				continue
			if visited.has(next_tile) and int(visited[next_tile]) <= next_cost:
				continue
			visited[next_tile] = next_cost
			frontier.append({"tile": next_tile, "cost": next_cost})
			if next_tile != unit["pos"] and not result.has(next_tile):
				result.append(next_tile)
	return result


func attack_tiles_for_selected() -> Array:
	return attack_tiles_for_unit(selected_unit())


func attack_tiles_for_unit(unit: Dictionary) -> Array:
	if unit.is_empty():
		return []
	var tiles: Array = []
	var attack_range: int = int(unit.get("attack_range", 1))
	if terrain_kind(unit["pos"]) == "high":
		attack_range += 1
	for enemy in get_enemy_units():
		var enemy_pos: Vector2i = enemy["pos"]
		if manhattan(unit["pos"], enemy_pos) <= attack_range:
			tiles.append(enemy_pos)
	return tiles


func unit_attack(attacker: Dictionary, target: Dictionary, board_rect: Rect2) -> bool:
	var damage: int = int(attacker.get("atk", 1)) + player_power + terrain_attack_bonus(attacker)
	damage_unit_from(attacker, target, damage, board_rect)
	if target["hp"] <= 0 and attacker.get("passive_id", "") == "duel_flash":
		attacker["block"] = int(attacker["block"]) + 2
		add_tile_effect(attacker["pos"], "+2格挡", Color("#8fffd8"), "guard", board_rect)
	_advance_tutorial("attack_or_skill", {"character_id": attacker.get("character_id", ""), "target": target.get("uid", "")})
	finish_selected_unit_action(attacker)
	return true


func finish_selected_unit_action(unit: Dictionary, final_message: String = "") -> void:
	if unit.is_empty():
		return
	unit["acted"] = true
	selected_unit_uid = ""
	action_mode = "select"
	moved_this_action = false
	pending_move_snapshot.clear()
	selected_card = -1
	selected_executor_uid = ""
	selected_card_owner_id = ""
	hover_card = -1
	if final_message != "":
		message = final_message
		push_log(message)
	_sync_active_hand()
	clear_dead_units()
	check_end_state()
	if not victory and not defeat and phase == "player" and _all_player_units_acted():
		end_player_turn()


func can_undo_selected_move() -> bool:
	return selected_unit_uid != "" and action_mode == "command" and moved_this_action and not pending_move_snapshot.is_empty() and pending_move_snapshot.get("uid", "") == selected_unit_uid


func undo_selected_move(_board_rect: Rect2) -> bool:
	if not can_undo_selected_move():
		return false
	var unit := selected_unit()
	if unit.is_empty():
		return false
	var current_pos: Vector2i = unit["pos"]
	var from_pos: Vector2i = pending_move_snapshot["from_pos"]
	unit["pos"] = from_pos
	unit["hp"] = pending_move_snapshot["hp"]
	unit["block"] = pending_move_snapshot["block"]
	unit["dead"] = false
	action_mode = "move"
	moved_this_action = false
	pending_move_snapshot.clear()
	message = "%s撤回移动，重新选择位置。" % unit["name"]
	push_log(message)
	_mark_unit_fx(unit, "move")
	add_visual_event("move", unit["uid"], from_pos, 0.28, {"from_tile": current_pos, "to_tile": from_pos, "message": "撤回"})
	return true


func sync_active_hand() -> void:
	_sync_active_hand()


func commit_active_card_state() -> void:
	_sync_active_hand()


func _sync_active_hand() -> void:
	var character_id := active_card_character_id()
	if character_id != active_hand_character_id:
		active_hand_character_id = character_id
		skill_page_index = 0
		hover_card = -1
	if character_id == "":
		draw_pile = []
		discard_pile = []
		hand = []
		return
	draw_pile = []
	discard_pile = []
	hand = _skill_cards_for_character(character_id)


func active_card_character_id() -> String:
	if selected_card_owner_id != "":
		return selected_card_owner_id
	var selected := selected_unit()
	if not selected.is_empty():
		return selected.get("character_id", "")
	var inspected := inspected_player_unit()
	if not inspected.is_empty():
		return inspected.get("character_id", "")
	var players := get_player_units()
	if not players.is_empty():
		return players[0].get("character_id", "")
	return ""


func active_hand_unit() -> Dictionary:
	return unit_for_character_id(active_card_character_id())


func hand_owner_name() -> String:
	var owner := active_hand_unit()
	if owner.is_empty():
		return "单位技能"
	return "%s技能" % owner.get("name", "")


func hand_owner_note() -> String:
	var owner := active_hand_unit()
	if owner.is_empty():
		return ""
	return "%s · %s" % [owner.get("class_name", ""), unit_weapon_label(owner)]


func active_hand_counts_text() -> String:
	var character_id := active_card_character_id()
	if character_id == "":
		return "0 个技能"
	return "%d 个技能" % _skill_cards_for_character(character_id).size()


func available_skills_for_selected() -> Array:
	var unit := selected_unit()
	if unit.is_empty():
		return []
	return skill_cards_for_unit(unit)


func skill_cards_for_unit(unit: Dictionary) -> Array:
	if unit.is_empty():
		return []
	return _skill_cards_for_character(unit.get("character_id", ""))


func selected_skill() -> Dictionary:
	_sync_active_hand()
	if selected_card < 0 or selected_card >= hand.size():
		return {}
	return hand[selected_card]


func unit_for_character_id(character_id: String) -> Dictionary:
	if character_id == "":
		return {}
	for unit in get_player_units():
		if unit.get("character_id", "") == character_id:
			return unit
	return {}


func terrain_kind(tile: Vector2i) -> String:
	return terrain.get(tile, "floor")


func terrain_move_cost(tile: Vector2i) -> int:
	match terrain_kind(tile):
		"pillar", "wall":
			return 99
		"high":
			return 2
	return 1


func terrain_attack_bonus(unit: Dictionary) -> int:
	if unit.is_empty():
		return 0
	return 1 if terrain_kind(unit.get("pos", Vector2i.ZERO)) == "high" else 0


func terrain_label(kind: String) -> String:
	match kind:
		"wall":
			return "墙体"
		"pillar":
			return "柱体"
		"high":
			return "高台"
		"holy":
			return "圣辉格"
		"fire":
			return "火焰格"
		"gate":
			return "目标点"
		"marker":
			return "标记点"
	return "地面"


func terrain_effect_text(kind: String) -> String:
	match kind:
		"wall", "pillar":
			return "不可通行。"
		"high":
			return "移动消耗2；站上后攻击+1、范围+1。"
		"holy":
			return "移动结束或玩家回合开始时恢复3生命。"
		"fire":
			return "移动结束或玩家回合开始时受到3点伤害。"
		"gate":
			return "关卡目标相关区域。"
		"marker":
			return "教学或战术提示区域。"
	return "移动消耗1。"


func terrain_hover_summary(tile: Vector2i) -> String:
	if not in_bounds(tile):
		return ""
	var kind := terrain_kind(tile)
	return "%s｜%s" % [terrain_label(kind), terrain_effect_text(kind)]


func terrain_start_turn_summary() -> String:
	return "高台攻击+1/范围+1，圣辉格恢复3，火焰格受到3点伤害。"


func is_walkable(tile: Vector2i) -> bool:
	return in_bounds(tile) and terrain_move_cost(tile) < 99


func _apply_tile_end_effect(unit: Dictionary, board_rect: Rect2) -> void:
	match terrain_kind(unit["pos"]):
		"holy":
			unit["hp"] = mini(int(unit["max_hp"]), int(unit["hp"]) + 3)
			add_tile_effect(unit["pos"], "+3生命", Color("#8fffd8"), "heal", board_rect)
		"fire":
			unit["hp"] = int(unit["hp"]) - 3
			add_tile_effect(unit["pos"], "-3", Color("#ff6685"), "hit", board_rect)
	if int(unit.get("hp", 0)) <= 0:
		clear_dead_units()
		check_end_state()


func _all_player_units_acted() -> bool:
	for unit in get_player_units():
		if not bool(unit.get("acted", false)):
			return false
	return true


func selected_executor() -> Dictionary:
	if selected_executor_uid == "":
		return selected_unit()
	return unit_by_uid(selected_executor_uid)


func can_unit_execute_card(unit: Dictionary, card: Dictionary) -> bool:
	if unit.is_empty() or unit["team"] != "player" or unit["hp"] <= 0:
		return false
	if bool(unit.get("acted", false)):
		return false
	var executor_tags: Array = card.get("executor_tags", [])
	if executor_tags.is_empty():
		return true
	for tag in unit.get("class_tags", []):
		if executor_tags.has(tag):
			return true
	return false


func _unit_owns_skill(unit: Dictionary, skill: Dictionary) -> bool:
	if unit.is_empty() or skill.is_empty():
		return false
	var character_id: String = unit.get("character_id", "")
	var skill_id: String = skill.get("id", "")
	return character_id != "" and skill_id != "" and _skill_ids_for_character(character_id).has(skill_id)


func unit_by_uid(uid: String) -> Dictionary:
	for unit in units:
		if unit.get("uid", "") == uid:
			return unit
	return {}


func set_hover_tile(tile: Vector2i) -> void:
	hover_tile = tile if in_bounds(tile) else Vector2i(-1, -1)
	var unit = unit_at(hover_tile)
	hover_unit_uid = unit["uid"] if unit != null else ""


func clear_hover_tile() -> void:
	hover_tile = Vector2i(-1, -1)
	hover_unit_uid = ""


func focus_enemy_at(tile: Vector2i) -> bool:
	var enemy = enemy_at(tile)
	if enemy == null:
		focused_enemy_uid = ""
		return false
	focused_enemy_uid = String(enemy.get("uid", ""))
	return focused_enemy_uid != ""


func clear_focused_enemy() -> void:
	focused_enemy_uid = ""


func focused_enemy() -> Dictionary:
	if focused_enemy_uid == "":
		return {}
	return unit_by_uid(focused_enemy_uid)


func focused_enemy_tiles() -> Array:
	var enemy := focused_enemy()
	if enemy.is_empty():
		return []
	return attack_area_tiles_for_unit(enemy)


func focused_enemy_forecast() -> Dictionary:
	var enemy := focused_enemy()
	if enemy.is_empty():
		return {}
	return enemy_hover_forecast(enemy)


func has_hover_tile() -> bool:
	return in_bounds(hover_tile)


func hovered_unit() -> Dictionary:
	if hover_unit_uid == "":
		return {}
	for unit in units:
		if unit.get("uid", "") == hover_unit_uid and unit["hp"] > 0:
			return unit
	return {}


func hovered_unit_summary() -> String:
	var unit := hovered_unit()
	if unit.is_empty():
		return ""
	var intent := enemy_intent_label(unit) if unit["team"] == "enemy" else "指挥单位"
	return "%s｜%s｜%s" % [
		unit["name"],
		_role_label(unit),
		intent,
	]


func hovered_unit_stats() -> String:
	var unit := hovered_unit()
	if unit.is_empty():
		return ""
	return "生命 %d/%d  格挡 %d  攻击 %d  范围 %d" % [
		unit["hp"],
		unit["max_hp"],
		unit["block"],
		unit["atk"],
		int(unit.get("attack_range", 1)),
	]


func hovered_unit_trait() -> String:
	var unit := hovered_unit()
	if unit.is_empty():
		return ""
	return unit_trait_label(unit)


func enemy_hover_forecast(enemy: Dictionary) -> Dictionary:
	if enemy.is_empty() or enemy.get("team", "") != "enemy":
		return {}
	var target := enemy_target_unit(enemy)
	if target.is_empty():
		return {}
	var distance := manhattan(enemy["pos"], target["pos"])
	var attack_range := int(enemy.get("attack_range", 1))
	var attacking := distance <= attack_range
	var amount := int(enemy.get("atk", 0))
	var blocked := mini(int(target.get("block", 0)), amount) if attacking else 0
	var damage := amount - blocked if attacking else 0
	var forecast := {
		"target_name": target.get("name", ""),
		"target_uid": target.get("uid", ""),
		"attacking": attacking,
		"distance": distance,
		"range": attack_range,
		"amount": amount,
		"blocked": blocked,
		"damage": damage,
	}
	if attacking:
		forecast["summary"] = _damage_result_text(_damage_result(target, amount, blocked, damage))
	else:
		var movement := enemy_movement_forecast(enemy, target)
		forecast["movement_intent"] = movement.get("intent", "")
		forecast["next_tile"] = movement.get("tile", Vector2i(-1, -1))
		forecast["summary"] = "将向%s靠近，距离%d / 范围%d。" % [target.get("name", "目标"), distance, attack_range]
	return forecast


func enemy_movement_forecast(enemy: Dictionary, target: Dictionary) -> Dictionary:
	if enemy.is_empty() or target.is_empty():
		return {}
	var target_pos: Vector2i = target.get("pos", Vector2i.ZERO)
	var options := _enemy_step_options(enemy, false, target_pos)
	if options.is_empty():
		return {}
	options.sort_custom(func(a, b): return _enemy_move_score(enemy, a, target_pos) < _enemy_move_score(enemy, b, target_pos))
	var chosen: Vector2i = options[0]
	return {
		"tile": chosen,
		"intent": _enemy_movement_intent_label(enemy, chosen, target_pos, options),
	}


func _enemy_movement_intent_label(enemy: Dictionary, tile: Vector2i, target: Vector2i, options: Array) -> String:
	var kind := terrain_kind(tile)
	var role := String(enemy.get("role", "sword"))
	if kind == "high" and role == "mage":
		return "抢占高台"
	if role == "guard" and _tile_is_chokepoint(tile):
		return "卡住窄道"
	if _enemy_is_avoiding_fire(tile, target, options):
		return "避开火焰"
	if kind == "holy" and int(enemy.get("hp", 0)) < int(enemy.get("max_hp", 0)):
		return "寻找恢复"
	return "逼近目标"


func _enemy_is_avoiding_fire(chosen: Vector2i, target: Vector2i, options: Array) -> bool:
	var chosen_distance := manhattan(chosen, target)
	for option in options:
		var option_tile: Vector2i = option
		if terrain_kind(option_tile) == "fire" and manhattan(option_tile, target) < chosen_distance:
			return true
	return false


func hovered_unit_tiles() -> Array:
	var unit := hovered_unit()
	if unit.is_empty():
		return []
	return attack_area_tiles_for_unit(unit)


func attack_area_tiles_for_unit(unit: Dictionary) -> Array:
	if unit.is_empty():
		return []
	var tiles: Array = []
	var attack_range: int = int(unit.get("attack_range", 1))
	if terrain_kind(unit["pos"]) == "high":
		attack_range += 1
	var unit_pos: Vector2i = unit["pos"]
	for y in range(GRID_H):
		for x in range(GRID_W):
			var p := Vector2i(x, y)
			if p != unit_pos and manhattan(unit_pos, p) <= attack_range:
				tiles.append(p)
	return tiles


func selected_card_preview(tile: Vector2i) -> Dictionary:
	if selected_card < 0 or selected_card >= hand.size():
		return {}
	var card: Dictionary = hand[selected_card]
	var card_id: String = card.get("id", "")
	var executor := selected_executor()
	if executor.is_empty():
		return {}
	var valid := get_valid_tiles().has(tile)
	var preview := {
		"valid": valid,
		"title": card["title"],
		"kind": card["kind"],
		"target": "目标",
		"summary": card["text"],
		"amount": 0,
		"after": 0,
	}
	match card["kind"]:
		CARD_STRIKE:
			var strike_damage := 10 if card_id == "silver_edge" else 7
			_fill_damage_preview(preview, tile, strike_damage + player_power + terrain_attack_bonus(executor))
			preview["target"] = "相邻敌人"
		CARD_LANCE:
			var lance_damage := 6 if card_id == "ember_thrust" else 9
			_fill_damage_preview(preview, tile, lance_damage + player_power + terrain_attack_bonus(executor))
			preview["target"] = "直线敌人"
		CARD_DASH:
			preview["target"] = "空白格"
			preview["summary"] = "移动至该格。" if valid else "不能移动到这里。"
			if card_id == "aegis_step":
				preview["summary"] = "移动，并获得3格挡。" if valid else "不能移动到这里。"
			elif card_id == "fleet_reposition":
				preview["summary"] = "移动1格并结束行动。" if valid else "不能移动到这里。"
		CARD_GUARD:
			var block_gain := 14 if card_id == "oath_wall" else 8
			preview["target"] = "自身"
			preview["amount"] = block_gain
			preview["after"] = int(executor["block"]) + block_gain
			preview["summary"] = "格挡 +%d，结算后为 %d。" % [block_gain, preview["after"]]
		CARD_ENGAGE:
			var power_gain := 1 if card_id in ["royal_order", "azure_command"] else 2
			preview["target"] = "自身"
			preview["amount"] = power_gain
			preview["after"] = player_power + power_gain
			preview["summary"] = "全队力量 +%d，使用后结束行动。" % power_gain
		CARD_HEAL:
			var heal := 6
			var bonus_block := 0
			if card_id == "sanctuary":
				heal = 10
			elif card_id == "seraphic_mend":
				heal = 8
				bonus_block = 4
			preview["target"] = "自身"
			preview["amount"] = heal
			var target = unit_at(tile)
			if target != null and target["team"] == "player":
				preview["target"] = "友军"
				preview["after"] = mini(int(target["max_hp"]), int(target["hp"]) + heal)
				preview["summary"] = "生命恢复到 %d/%d。" % [preview["after"], target["max_hp"]]
			else:
				preview["summary"] = "选择一名友军。"
			if bonus_block > 0:
				preview["summary"] += " 格挡 +%d。" % bonus_block
	return preview


func normal_attack_preview(tile: Vector2i) -> Dictionary:
	var attacker := selected_unit()
	if attacker.is_empty() or bool(attacker.get("acted", false)):
		return {}
	var valid := attack_tiles_for_unit(attacker).has(tile)
	var damage: int = int(attacker.get("atk", 1)) + player_power + terrain_attack_bonus(attacker)
	var preview := {
		"valid": valid,
		"title": "普通攻击",
		"kind": "normal_attack",
		"target": "敌人",
		"summary": "选择攻击范围内的敌人。",
		"amount": 0,
		"after": 0,
		"attacker_uid": attacker.get("uid", ""),
	}
	_fill_damage_preview(preview, tile, damage)
	if not valid:
		preview["summary"] = "目标不在武器范围内。"
	return preview


func selected_card_sidebar_summary() -> String:
	if selected_card < 0 or selected_card >= hand.size():
		return "未选择技能。"
	var card: Dictionary = hand[selected_card]
	if selected_executor_uid == "":
		return "当前单位｜%s" % selected_unit().get("name", "")
	var preview := selected_card_preview(selected_executor().get("pos", Vector2i.ZERO))
	if card["kind"] in [CARD_STRIKE, CARD_LANCE, CARD_DASH] and has_hover_tile():
		preview = selected_card_preview(hover_tile)
	if not preview.is_empty():
		return "%s｜%s" % [preview["target"], preview["summary"]]
	return card["text"]


func _fill_damage_preview(preview: Dictionary, tile: Vector2i, amount: int) -> void:
	var target = enemy_at(tile)
	preview["raw_amount"] = amount
	if target == null:
		preview["summary"] = "选择一个敌方目标。"
		preview["amount"] = 0
		preview["after"] = 0
		preview["kill"] = false
		return
	var blocked: int = mini(int(target["block"]), amount)
	var final_damage := amount - blocked
	var after_hp: int = maxi(0, int(target["hp"]) - final_damage)
	preview["blocked"] = blocked
	preview["amount"] = final_damage
	preview["after"] = after_hp
	preview["kill"] = after_hp <= 0
	if blocked > 0 and final_damage > 0:
		preview["summary"] = "总伤害%d，格挡吸收%d，实际%d；目标剩余 %d/%d。" % [amount, blocked, final_damage, after_hp, target["max_hp"]]
	elif blocked > 0:
		preview["summary"] = "总伤害%d，格挡吸收%d，目标不掉血。" % [amount, blocked]
	else:
		preview["summary"] = "造成%d点伤害，目标剩余 %d/%d。" % [final_damage, after_hp, target["max_hp"]]
	if after_hp <= 0 and final_damage > 0:
		preview["summary"] = "总伤害%d，格挡吸收%d，实际%d，可击破目标。" % [amount, blocked, final_damage] if blocked > 0 else "造成%d点伤害，可击破目标。" % final_damage


func end_player_turn() -> void:
	_advance_tutorial("end_turn")
	phase = "enemy"
	selected_card = -1
	selected_executor_uid = ""
	selected_card_owner_id = ""
	selected_unit_uid = ""
	action_mode = "select"
	moved_this_action = false
	pending_move_snapshot.clear()
	hover_tile = Vector2i(-1, -1)
	_sync_active_hand()
	message = "敌方行动。"
	push_log(message)
	add_banner_event("敌方行动")


func prepare_enemy_step(enemy: Dictionary) -> void:
	if enemy["team"] != "enemy" or enemy["hp"] <= 0:
		return
	var target := enemy_target_unit(enemy)
	var target_name := "目标" if target.is_empty() else String(target.get("name", "目标"))
	message = "%s 准备：%s → %s。" % [enemy["name"], enemy_intent_label(enemy), target_name]
	push_log(message)
	add_visual_event("prepare", enemy["uid"], enemy["pos"], 0.34, {"message": enemy_intent_label(enemy), "target_uid": target.get("uid", "")})


func run_enemy_step(enemy: Dictionary, board_rect: Rect2) -> void:
	if enemy["team"] != "enemy" or enemy["hp"] <= 0:
		return
	var target_unit := enemy_target_unit(enemy)
	if target_unit.is_empty():
		return
	var hero_pos: Vector2i = target_unit["pos"]
	var enemy_pos: Vector2i = enemy["pos"]
	var distance := manhattan(enemy_pos, hero_pos)
	var role: String = enemy.get("role", "sword")
	var attack_range: int = int(enemy.get("attack_range", 1))
	if role == "guard" and enemy["hp"] <= enemy["max_hp"] / 2 and enemy["block"] <= 0:
		var guard_gain := 7
		enemy["block"] = enemy["block"] + guard_gain
		message = "%s 架起誓盾。" % enemy["name"]
		push_log(message)
		_mark_unit_fx(enemy, "guard")
		add_tile_effect(enemy_pos, "+%d格挡" % guard_gain, Color("#8fffd8"), "guard", board_rect, 0.22)
		add_visual_event("guard", enemy["uid"], enemy_pos, 0.68, {"amount": guard_gain, "vfx_kind": "guard", "message": "架盾"})
	elif role == "mage" and distance <= 1 and step_enemy_away(enemy, hero_pos):
		message = "%s 后撤蓄法。" % enemy["name"]
		push_log(message)
		add_tile_effect(enemy["pos"], "后撤", Color("#79d8ff"), "guard", board_rect)
		add_visual_event("move", enemy["uid"], enemy["pos"], 0.36, {"from_tile": enemy_pos, "to_tile": enemy["pos"], "message": "后撤"})
	elif distance <= attack_range:
		var vfx_kind := "magic" if role == "mage" else "slash"
		var attack_duration := MAGE_ATTACK_EVENT_DURATION if role == "mage" else ATTACK_EVENT_DURATION
		add_visual_event("attack", enemy["uid"], hero_pos, attack_duration, {"from_tile": enemy_pos, "to_tile": hero_pos, "amount": int(enemy["atk"]), "vfx_kind": vfx_kind, "message": enemy_intent_label(enemy)})
		var result := hit_player_unit(target_unit, int(enemy["atk"]), board_rect, vfx_kind, visual_impact_delay("attack", attack_duration))
		message = "%s 攻击，%s。" % [enemy["name"], _damage_result_text(result)]
		push_log(message)
	else:
		var before_pos: Vector2i = enemy["pos"]
		step_enemy_toward(enemy, hero_pos)
		message = "%s 正在逼近。" % enemy["name"]
		push_log(message)
		add_tile_effect(enemy["pos"], "移动", Color("#ffd66e"), "guard", board_rect)
		add_visual_event("move", enemy["uid"], enemy["pos"], 0.36, {"from_tile": before_pos, "to_tile": enemy["pos"], "message": "移动"})


func enemy_step_pause(enemy: Dictionary) -> float:
	match String(enemy.get("role", "sword")):
		"mage":
			return 0.54
		"guard":
			return 0.46
	return 0.38


func finish_enemy_turn() -> void:
	check_end_state()
	if victory or defeat:
		return
	start_player_turn()


func start_player_turn() -> void:
	turn += 1
	battle_stats["turns_finished"] = turn
	phase = "player"
	energy = START_ENERGY
	if get_player_units().is_empty():
		check_end_state()
		return
	_apply_player_turn_terrain_effects()
	if victory or defeat:
		return
	for unit in get_player_units():
		unit["block"] = 0
		unit["acted"] = false
	selected_unit_uid = ""
	action_mode = "select"
	moved_this_action = false
	pending_move_snapshot.clear()
	selected_card = -1
	selected_executor_uid = ""
	selected_card_owner_id = ""
	_sync_active_hand()
	message = "我方行动。选择单位移动、攻击或待机。"
	push_log(message)
	add_banner_event("我方行动")


func _apply_player_turn_terrain_effects() -> void:
	for unit in get_player_units():
		_apply_tile_end_effect(unit, Rect2())
	clear_dead_units()
	check_end_state()


func damage_unit(unit: Dictionary, amount: int, board_rect: Rect2) -> bool:
	return damage_unit_from(selected_executor(), unit, amount, board_rect)


func damage_unit_from(attacker: Dictionary, unit: Dictionary, amount: int, board_rect: Rect2) -> bool:
	var was_alive := int(unit.get("hp", 0)) > 0 and not bool(unit.get("dead", false))
	var blocked: int = mini(unit["block"], amount)
	unit["block"] = unit["block"] - blocked
	var final_damage := amount - blocked
	unit["hp"] = unit["hp"] - final_damage
	battle_stats["highest_damage"] = maxi(int(battle_stats.get("highest_damage", 0)), final_damage)
	var result := _damage_result(unit, amount, blocked, final_damage)
	message = "%s %s。" % [unit["name"], _damage_result_text(result)]
	push_log(message)
	_mark_unit_fx(unit, "hit")
	var attacker_uid: String = attacker.get("uid", "")
	var attacker_pos: Vector2i = attacker.get("pos", unit["pos"])
	add_visual_event("attack", attacker_uid, unit["pos"], ATTACK_EVENT_DURATION, {"from_tile": attacker_pos, "to_tile": unit["pos"], "amount": final_damage, "vfx_kind": "slash", "message": "攻击"})
	_emit_damage_feedback(unit["pos"], result, "slash", board_rect, visual_impact_delay("attack", ATTACK_EVENT_DURATION))
	_award_combat_exp(attacker, unit, final_damage, was_alive and int(unit.get("hp", 0)) <= 0, board_rect)
	return true


func hit_hero(amount: int) -> void:
	var hero := get_player()
	hit_player_unit(hero, amount)


func hit_player_unit(hero: Dictionary, amount: int, board_rect: Rect2 = Rect2(), vfx_kind: String = "hit", start_delay: float = 0.0) -> Dictionary:
	if hero.is_empty():
		return {}
	var blocked: int = mini(hero["block"], amount)
	var final_damage := amount - blocked
	hero["block"] = hero["block"] - blocked
	hero["hp"] = hero["hp"] - final_damage
	battle_stats["damage_taken"] = int(battle_stats.get("damage_taken", 0)) + final_damage
	_mark_unit_fx(hero, "hit")
	var result := _damage_result(hero, amount, blocked, final_damage)
	add_visual_event("hit", hero["uid"], hero["pos"], 0.44, {"amount": final_damage, "blocked": blocked, "vfx_kind": vfx_kind})
	_emit_damage_feedback(hero["pos"], result, vfx_kind, board_rect, start_delay)
	if hero["hp"] <= 0 and not bool(hero.get("dead", false)):
		hero["dead"] = true
		_sync_player_death_to_party(hero)
		_mark_unit_fx(hero, "death")
		add_visual_event("death", hero["uid"], hero["pos"], 0.96, {"vfx_kind": "death", "message": "倒下"})
	return result


func _damage_result(unit: Dictionary, amount: int, blocked: int, final_damage: int) -> Dictionary:
	return {
		"target_uid": unit.get("uid", ""),
		"amount": amount,
		"blocked": blocked,
		"damage": final_damage,
	}


func _damage_result_text(result: Dictionary) -> String:
	var blocked := int(result.get("blocked", 0))
	var damage := int(result.get("damage", 0))
	if blocked > 0 and damage > 0:
		return "格挡吸收%d，受到%d点伤害" % [blocked, damage]
	if blocked > 0:
		return "格挡吸收%d，未受伤" % blocked
	return "受到%d点伤害" % damage


func _emit_damage_feedback(tile: Vector2i, result: Dictionary, vfx_kind: String, board_rect: Rect2, start_delay: float = 0.0) -> void:
	var blocked := int(result.get("blocked", 0))
	var damage := int(result.get("damage", 0))
	if blocked > 0:
		add_tile_effect(tile, "格挡-%d" % blocked, Color("#8fffd8"), "guard", board_rect, start_delay, 0.58)
	if damage > 0:
		var delay := start_delay + (0.18 if blocked > 0 else 0.0)
		add_tile_effect(tile, "-%d" % damage, Color("#ff6685"), vfx_kind, board_rect, delay, 0.70)
	elif blocked > 0:
		add_tile_effect(tile, "未受伤", Color("#fff4ba"), "guard", board_rect, start_delay + 0.18, 0.58)


func move_player(tile: Vector2i, board_rect: Rect2) -> bool:
	return move_unit(selected_executor(), tile, board_rect)


func move_unit(hero: Dictionary, tile: Vector2i, board_rect: Rect2) -> bool:
	if hero.is_empty():
		return false
	if unit_at(tile) != null:
		return false
	var old_pos: Vector2i = hero["pos"]
	hero["pos"] = tile
	message = "%s完成换位。" % hero["name"]
	push_log(message)
	_mark_unit_fx(hero, "move")
	add_tile_effect(tile, "移动", Color("#79f2c9"), "guard", board_rect)
	add_visual_event("move", hero["uid"], tile, 0.36, {"from_tile": old_pos, "to_tile": tile, "message": "移动"})
	check_end_state()
	return true


func step_enemy_toward(enemy: Dictionary, target: Vector2i) -> void:
	var options := _enemy_step_options(enemy, false, target)
	if options.is_empty():
		return
	options.sort_custom(func(a, b): return _enemy_move_score(enemy, a, target) < _enemy_move_score(enemy, b, target))
	enemy["pos"] = options[0]
	_mark_unit_fx(enemy, "move")


func step_enemy_away(enemy: Dictionary, target: Vector2i) -> bool:
	var options := _enemy_step_options(enemy, true, target)
	if options.is_empty():
		return false
	options.sort_custom(func(a, b): return _enemy_retreat_score(enemy, a, target) < _enemy_retreat_score(enemy, b, target))
	enemy["pos"] = options[0]
	_mark_unit_fx(enemy, "move")
	return true


func _enemy_step_options(enemy: Dictionary, retreat: bool, target: Vector2i) -> Array:
	var options: Array = []
	var enemy_pos: Vector2i = enemy["pos"]
	var current_distance := manhattan(enemy_pos, target)
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var p: Vector2i = enemy_pos + d
		if not in_bounds(p) or not is_walkable(p) or unit_at(p) != null:
			continue
		if retreat and manhattan(p, target) <= current_distance:
			continue
		options.append(p)
	return options


func _enemy_move_score(enemy: Dictionary, tile: Vector2i, target: Vector2i) -> int:
	var score := manhattan(tile, target) * 100
	var kind := terrain_kind(tile)
	var role := String(enemy.get("role", "sword"))
	if kind == "fire":
		score += 260
	elif kind == "holy" and int(enemy.get("hp", 0)) < int(enemy.get("max_hp", 0)):
		score -= 24
	if kind == "high":
		score -= 130 if role == "mage" else 28
	if role == "guard" and _tile_is_chokepoint(tile):
		score -= 85
	return score


func _enemy_retreat_score(enemy: Dictionary, tile: Vector2i, target: Vector2i) -> int:
	var score := -manhattan(tile, target) * 100
	var kind := terrain_kind(tile)
	var role := String(enemy.get("role", "sword"))
	if kind == "fire":
		score += 260
	if kind == "high":
		score -= 110 if role == "mage" else 20
	return score


func _tile_is_chokepoint(tile: Vector2i) -> bool:
	var exits := 0
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var p: Vector2i = tile + d
		if in_bounds(p) and is_walkable(p):
			exits += 1
	return exits <= 2


func clear_dead_units() -> void:
	for unit in units:
		if unit["hp"] <= 0 and not bool(unit.get("dead", false)):
			unit["dead"] = true
			if unit["team"] == "enemy":
				battle_stats["enemies_defeated"] = int(battle_stats.get("enemies_defeated", 0)) + 1
			elif unit["team"] == "player":
				_sync_player_death_to_party(unit)
			_mark_unit_fx(unit, "death")
			add_visual_event("death", unit["uid"], unit["pos"], 0.96, {"vfx_kind": "death", "message": "击破"})


func check_end_state() -> void:
	if not defeat and is_character_fallen("astra") and chapter_phase == "battle":
		defeat = true
		phase = "done"
		message = "战败。阿斯特拉倒下，战线崩溃。"
		push_log(message)
		add_banner_event("战败")
		return
	if not victory and (_objective_reached() or units.filter(func(u): return u["team"] == "enemy" and u["hp"] > 0).is_empty()):
		_complete_battle_victory()
	if not defeat and get_player_units().is_empty() and chapter_phase == "battle":
		defeat = true
		phase = "done"
		message = "战败。"
		push_log(message)
		add_banner_event("战败")


func _complete_battle_victory() -> void:
	victory = true
	phase = "done"
	chapter_phase = "reward"
	_resolve_recruitment()
	message = "胜利。"
	push_log(message)
	generate_reward_options()
	add_banner_event("胜利")


func _objective_reached() -> bool:
	if String(battle_objective.get("type", "rout")) != "reach":
		return false
	for unit in get_player_units():
		if battle_reach_tiles().has(unit.get("pos", Vector2i.ZERO)):
			return true
	return false


func battle_reach_tiles() -> Array:
	return battle_objective.get("reach_tiles", [])


func get_player() -> Dictionary:
	for unit in units:
		if unit["team"] == "player" and unit["hp"] > 0:
			return unit
	return {}


func get_player_units() -> Array:
	return units.filter(func(u): return u["team"] == "player" and u["hp"] > 0 and not bool(u.get("dead", false)) and not is_character_fallen(String(u.get("character_id", ""))))


func _resolve_recruitment() -> void:
	var recruitment := battle_recruitment()
	if recruitment.is_empty():
		return
	var condition := String(recruitment.get("condition", ""))
	if condition not in ["survive", "victory"]:
		return
	var character_id := String(recruitment.get("character_id", ""))
	if character_id == "" or is_character_recruited(character_id):
		return
	if condition == "survive":
		var recruit_unit := _recruitment_unit(recruitment)
		if recruit_unit.is_empty() or int(recruit_unit.get("hp", 0)) <= 0 or bool(recruit_unit.get("dead", false)):
			return
	var member := content.build_party_member(character_id)
	if member.is_empty():
		return
	member["deployed"] = bool(recruitment.get("deploy_on_join", false))
	party.append(member)
	recruitment_history.append({
		"character_id": character_id,
		"name": member.get("name", character_id),
		"title": recruitment.get("title", ""),
	})
	message = "%s加入队伍。" % member.get("name", character_id)
	push_log(message)
	add_banner_event("角色加入")


func _recruitment_unit(recruitment: Dictionary) -> Dictionary:
	var character_id := String(recruitment.get("character_id", ""))
	var unit_key := String(recruitment.get("unit", ""))
	for unit in units:
		if character_id != "" and String(unit.get("character_id", "")) == character_id:
			return unit
		if unit_key != "" and String(unit.get("unit_key", "")) == unit_key:
			return unit
	return {}


func cycle_character_panel(step: int) -> void:
	var count := _character_panel_count()
	if count <= 0:
		character_panel_index = 0
		return
	if selected_unit_uid != "" and moved_this_action:
		message = "请先攻击、待机，或撤回当前移动。"
		push_log(message)
		return
	cancel_card_selection()
	selected_unit_uid = ""
	action_mode = "select"
	moved_this_action = false
	pending_move_snapshot.clear()
	character_panel_index = posmod(character_panel_index + step, count)
	_sync_active_hand()


func focus_character_uid(uid: String) -> void:
	var players := get_player_units()
	for i in range(players.size()):
		if players[i].get("uid", "") == uid:
			character_panel_index = i
			_sync_active_hand()
			return


func inspected_player_unit() -> Dictionary:
	var players := get_player_units()
	if players.is_empty():
		return {}
	_clamp_character_panel_index()
	return players[character_panel_index]


func inspected_party_member() -> Dictionary:
	_clamp_character_panel_index()
	var living_members: Array = []
	for member in party:
		if not is_party_member_fallen(member):
			living_members.append(member)
	if living_members.is_empty():
		return {}
	return living_members[character_panel_index]


func character_panel_count_label() -> String:
	var count := _character_panel_count()
	if count <= 0:
		return "0/0"
	return "%d/%d" % [character_panel_index + 1, count]


func unit_weapon_label(unit: Dictionary) -> String:
	if unit.is_empty():
		return "-"
	return unit.get("weapon_name", _weapon_label_for_role(unit.get("role", "")))


func unit_skill_label(unit: Dictionary) -> String:
	if unit.is_empty():
		return "-"
	var skill: String = unit.get("skill_name", "")
	if skill != "":
		return skill
	return content.passive_text(unit.get("passive_id", ""))


func _character_panel_count() -> int:
	var players := get_player_units()
	if not players.is_empty():
		return players.size()
	return living_party_count()


func _clamp_character_panel_index() -> void:
	var count := _character_panel_count()
	if count <= 0:
		character_panel_index = 0
	else:
		character_panel_index = clampi(character_panel_index, 0, count - 1)


func _weapon_label_for_role(role: String) -> String:
	match role:
		"hero":
			return "苍纹剑"
		"faith", "mage":
			return "术杖"
		"lance":
			return "长枪"
		"guard":
			return "盾锤"
		"sword":
			return "短剑"
	return "武器"


func nearest_player_unit(from_tile: Vector2i) -> Dictionary:
	var players := get_player_units()
	if players.is_empty():
		return {}
	players.sort_custom(func(a, b): return manhattan(a["pos"], from_tile) < manhattan(b["pos"], from_tile))
	return players[0]


func enemy_target_unit(enemy: Dictionary) -> Dictionary:
	var players := get_player_units()
	if enemy.is_empty() or players.is_empty():
		return {}
	players.sort_custom(func(a, b): return _enemy_target_score(enemy, a) < _enemy_target_score(enemy, b))
	return players[0]


func _enemy_target_score(enemy: Dictionary, player: Dictionary) -> int:
	var distance := manhattan(enemy["pos"], player["pos"])
	var score := distance * 100
	var role := String(player.get("role", ""))
	if role in ["lance", "guard"]:
		score -= 120
	score -= mini(int(player.get("block", 0)), 18) * 3
	if role == "faith":
		score += 28
	if bool(player.get("acted", false)) and int(player.get("block", 0)) <= 0:
		score += 12
	return score


func unit_at(tile: Vector2i) -> Variant:
	for unit in units:
		if unit["pos"] == tile and unit["hp"] > 0 and not bool(unit.get("dead", false)):
			return unit
	return null


func enemy_at(tile: Vector2i) -> Variant:
	var unit = unit_at(tile)
	if unit != null and unit["team"] == "enemy":
		return unit
	return null


func enemies_left() -> int:
	return units.filter(func(u): return u["team"] == "enemy" and u["hp"] > 0).size()


func get_enemy_units() -> Array:
	return units.filter(func(u): return u["team"] == "enemy" and u["hp"] > 0)


func get_enemy_threat_tiles() -> Array:
	var tiles: Array = []
	for unit in units:
		if unit["team"] != "enemy" or unit["hp"] <= 0:
			continue
		for threat_pos in attack_area_tiles_for_unit(unit):
			if not tiles.has(threat_pos):
				tiles.append(threat_pos)
	return tiles


func get_player_threat_tiles() -> Array:
	var tiles: Array = []
	for unit in units:
		if unit["team"] != "player" or unit["hp"] <= 0 or bool(unit.get("dead", false)):
			continue
		for threat_pos in attack_area_tiles_for_unit(unit):
			if not tiles.has(threat_pos):
				tiles.append(threat_pos)
	return tiles


func add_tile_effect(tile: Vector2i, text: String, color: Color, kind: String, _board_rect: Rect2, start_delay: float = 0.0, active_duration: float = 0.78) -> void:
	effects.append({
		"tile": tile,
		"text": text,
		"color": color,
		"kind": kind,
		"age": 0.0,
		"duration": start_delay + active_duration,
		"start_delay": start_delay,
		"active_duration": active_duration,
	})


func add_screen_effect(pos: Vector2, text: String, color: Color, kind: String) -> void:
	effects.append({
		"pos": pos,
		"text": text,
		"color": color,
		"kind": kind,
		"age": 0.0,
		"duration": 0.78,
	})


func add_visual_event(kind: String, uid: String, tile: Vector2i, duration: float, extra: Dictionary = {}) -> void:
	var visual_event := {
		"kind": kind,
		"uid": uid,
		"tile": tile,
		"age": 0.0,
		"duration": duration,
		"impact_progress": _default_impact_progress(kind),
	}
	for key in extra:
		visual_event[key] = extra[key]
	if kind == "attack":
		_enrich_attack_event(visual_event)
	visual_events.append(visual_event)


func _enrich_attack_event(visual_event: Dictionary) -> void:
	var attacker: Dictionary = unit_by_uid(String(visual_event.get("uid", "")))
	var target = unit_at(visual_event.get("to_tile", visual_event.get("tile", Vector2i(-1, -1))))
	if attacker.is_empty() or target == null:
		return
	visual_event["attacker_name"] = attacker.get("name", "")
	visual_event["attacker_team"] = attacker.get("team", "")
	visual_event["attacker_role"] = attacker.get("role", "")
	visual_event["attacker_unit_id"] = attacker.get("id", "")
	visual_event["attacker_character_id"] = attacker.get("character_id", "")
	visual_event["attacker_unit_key"] = attacker.get("unit_key", "")
	visual_event["target_name"] = target.get("name", "")
	visual_event["target_team"] = target.get("team", "")
	visual_event["target_role"] = target.get("role", "")
	visual_event["target_unit_id"] = target.get("id", "")
	visual_event["target_character_id"] = target.get("character_id", "")
	visual_event["target_unit_key"] = target.get("unit_key", "")


func visual_impact_delay(kind: String, duration: float) -> float:
	return maxf(0.0, duration * _default_impact_progress(kind))


func _default_impact_progress(kind: String) -> float:
	match kind:
		"attack":
			return 0.46
		"skill_release", "guard", "heal", "engage":
			return 0.36
		"hit":
			return 0.18
		"death":
			return 0.72
	return 0.0


func add_banner_event(text: String) -> void:
	add_visual_event("banner", "", Vector2i.ZERO, 1.15, {"message": text})


func add_objective_event() -> void:
	add_visual_event("objective", "", Vector2i.ZERO, 3.2, {
		"message": objective_summary(),
		"detail": current_battle_objective_detail(),
	})


func add_tutorial_feedback(title: String, detail: String, tone: String = "info", duration: float = 1.65) -> void:
	add_visual_event("tutorial_feedback", "", Vector2i.ZERO, duration, {
		"message": title,
		"detail": detail,
		"tone": tone,
	})


func reject_invalid_tutorial_target(input_action: String = "") -> void:
	if not has_tutorial_step():
		return
	var detail := tutorial_constraint_text()
	if input_action == "attack_or_skill":
		detail = "目标不符合当前技能或普通攻击范围。%s" % detail
	elif input_action == "move_or_wait":
		detail = "只能移动到发光格，或点击自身格原地行动。"
	elif input_action == "select_unit":
		detail = "请点击教学高亮的我方单位。"
	message = "教学：%s" % detail
	push_log(message)
	add_tutorial_feedback("操作无效", detail, "warn")


func has_tutorial_step() -> bool:
	return chapter_phase == "battle" and not tutorial_completed and tutorial_step_index < tutorial_steps.size()


func current_tutorial_step() -> Dictionary:
	if not has_tutorial_step():
		return {}
	return tutorial_steps[tutorial_step_index]


func tutorial_title() -> String:
	return String(current_tutorial_step().get("title", "战术提示"))


func tutorial_body() -> String:
	return String(current_tutorial_step().get("body", ""))


func tutorial_constraint_text() -> String:
	var step := current_tutorial_step()
	var required_character := String(step.get("character_id", ""))
	var required_skill := String(step.get("required_skill_id", ""))
	match String(current_tutorial_step().get("action", "")):
		"select_unit":
			return "当前只接受：选择%s" % character_name(required_character) if required_character != "" else "当前只接受：选择指定单位"
		"move_or_wait":
			return "当前只接受：移动或原地行动"
		"attack_or_skill":
			if required_skill != "":
				var skill := content.create_card(required_skill)
				return "当前只接受：使用%s" % String(skill.get("title", required_skill))
			return "当前只接受：普通攻击或技能"
		"end_turn":
			return "当前目标：行动剩余角色或结束回合"
	return ""


func tutorial_recommendation_text() -> String:
	var step := current_tutorial_step()
	var recommended_skill := String(step.get("recommended_skill_id", ""))
	if recommended_skill != "":
		var skill := content.create_card(recommended_skill)
		return "推荐：使用%s" % String(skill.get("title", recommended_skill))
	var recommended_focus := tutorial_recommended_tiles()
	if not recommended_focus.is_empty():
		return "推荐：点击绿色标记格"
	return ""


func tutorial_focus_tiles() -> Array:
	var tiles: Array = []
	var step := current_tutorial_step()
	for raw_pos in step.get("focus", []):
		tiles.append(content._array_to_vector2i(raw_pos))
	return tiles


func tutorial_recommended_tiles() -> Array:
	var tiles: Array = []
	var step := current_tutorial_step()
	match String(step.get("action", "")):
		"end_turn":
			return tiles
		"attack_or_skill":
			var required_skill := String(step.get("required_skill_id", ""))
			if required_skill != "":
				var skill := content.create_card(required_skill)
				if String(skill.get("target_mode", "")) == "unit_self":
					return tiles
	for raw_pos in step.get("recommended_focus", []):
		tiles.append(content._array_to_vector2i(raw_pos))
	return tiles


func reject_tutorial_action(input_action: String, payload: Dictionary = {}) -> bool:
	if not has_tutorial_step():
		return false
	var expected_action := String(current_tutorial_step().get("action", ""))
	var reject_message := ""
	match expected_action:
		"select_unit":
			if input_action != "select_unit":
				var required := String(current_tutorial_step().get("character_id", ""))
				reject_message = "教学：先点击高亮的%s。" % character_name(required) if required != "" else "教学：先点击高亮单位。"
			else:
				var required_character := String(current_tutorial_step().get("character_id", ""))
				if required_character != "" and String(payload.get("character_id", "")) != required_character:
					reject_message = "教学：这一步请先选择%s。" % character_name(required_character)
		"move_or_wait":
			if input_action != "move_or_wait":
				reject_message = "教学：先点击发光格移动，或点击自身格原地行动。"
		"attack_or_skill":
			if input_action == "end_turn":
				reject_message = "教学：先完成一次普通攻击或技能，再结束回合。"
			else:
				var required_skill := String(current_tutorial_step().get("required_skill_id", ""))
				if required_skill != "" and String(payload.get("skill_id", "")) != required_skill:
					var skill := content.create_card(required_skill)
					reject_message = "教学：这一步请使用%s。" % String(skill.get("title", required_skill))
	if reject_message == "":
		return false
	message = reject_message
	push_log(message)
	add_tutorial_feedback("操作提示", reject_message, "warn")
	return true


func _advance_tutorial(action: String, payload: Dictionary = {}) -> void:
	if not has_tutorial_step():
		return
	var step := current_tutorial_step()
	if String(step.get("action", "")) != action:
		return
	var required_character := String(step.get("character_id", ""))
	if required_character != "" and String(payload.get("character_id", "")) != required_character:
		return
	var required_skill := String(step.get("required_skill_id", ""))
	if required_skill != "" and String(payload.get("skill_id", "")) != required_skill:
		return
	tutorial_step_index += 1
	if tutorial_step_index >= tutorial_steps.size():
		tutorial_completed = true
		var complete_title := String(post_tutorial_objective.get("title", "教学完成"))
		var complete_body := String(post_tutorial_objective.get("body", "继续完成战斗，验证完整回合循环。"))
		add_tutorial_feedback(complete_title, complete_body, "success", 2.4)
		if not post_tutorial_objective.is_empty():
			add_visual_event("objective", "", Vector2i.ZERO, 3.2, {
				"message": complete_title,
				"detail": complete_body,
			})
	else:
		add_tutorial_feedback("步骤完成", "下一步：%s" % tutorial_title(), "success", 1.25)
		add_visual_event("tutorial", "", Vector2i.ZERO, 2.4, {"message": tutorial_title(), "detail": tutorial_body()})


func objective_summary() -> String:
	if String(battle_objective.get("type", "rout")) == "reach":
		var title := String(battle_objective.get("title", "抵达目标格"))
		return "目标：%s" % title
	return "目标：击破所有敌人（%d/%d）" % [battle_in_chapter, chapter_encounter_count()]


func failure_summary() -> String:
	return "失败：全队倒下"


func tactical_tip() -> String:
	return "提示：利用走位避开法师2格术式范围。"


func battle_grade() -> String:
	if defeat:
		return "-"
	var score := 100
	score -= maxi(0, turn - 3) * 8
	score -= int(battle_stats.get("damage_taken", 0))
	if score >= 86:
		return "S"
	if score >= 68:
		return "A"
	return "B"


func battle_result_summary() -> String:
	return "回合 %d  击破 %d  受伤 %d  最高伤害 %d  经验 %d" % [
		turn,
		int(battle_stats.get("enemies_defeated", 0)),
		int(battle_stats.get("damage_taken", 0)),
		int(battle_stats.get("highest_damage", 0)),
		int(battle_stats.get("xp_gained", 0)),
	]


func battle_result_note() -> String:
	if defeat:
		return "失败原因：全队倒下。重试时优先用凯尔承伤、莉奥拉恢复。"
	for event in battle_exp_events:
		if int(event.get("level_ups", 0)) > 0:
			return "%s升级至 Lv%d。下一战生命与攻击成长会继续保留。" % [String(event.get("name", "")), int(event.get("after_level", 1))]
	match battle_grade():
		"S":
			return "评价 S：走位漂亮，损耗很低。"
		"A":
			return "评价 A：战术稳定，还有优化空间。"
	return "评价 B：已完成目标，可以尝试减少受伤和技能消耗。"


func enemy_intent_label(enemy: Dictionary) -> String:
	match String(enemy.get("role", "sword")):
		"mage":
			return "术式 %d" % int(enemy["atk"])
		"guard":
			if enemy["hp"] <= enemy["max_hp"] / 2 and enemy["block"] <= 0:
				return "架盾"
			return "盾击 %d" % int(enemy["atk"])
	return "追击 %d" % int(enemy["atk"])


func _role_label(unit: Dictionary) -> String:
	match String(unit.get("role", "")):
		"hero":
			return "纹章剑士"
		"faith":
			return "圣辉术士"
		"lance":
			return "誓盾枪卫"
		"sword":
			return "近战追击"
		"mage":
			return "远程术式"
		"guard":
			return "誓盾守卫"
	return "单位"


func unit_trait_label(unit: Dictionary) -> String:
	match String(unit.get("role", "")):
		"hero":
			return content.passive_text(unit.get("passive_id", "crest_edge"))
		"faith":
			return content.passive_text(unit.get("passive_id", "gentle_light"))
		"lance":
			return content.passive_text(unit.get("passive_id", "vow_guard"))
		"sword":
			return "会持续追击，贴近后进行近战攻击。"
		"mage":
			return "可在2格距离施法，贴脸时会尝试后撤。"
		"guard":
			return "半血以下且无格挡时会优先架盾。"
	return "无特殊特性。"


func _mark_unit_fx(unit: Dictionary, kind: String) -> void:
	var duration := 0.34
	if kind == "death":
		duration = 0.96
	elif kind == "guard":
		duration = 0.68
	elif kind == "hit":
		duration = 0.44
	unit_fx[unit["uid"]] = {"kind": kind, "age": 0.0, "duration": duration}


func tile_rect(tile: Vector2i, board_rect: Rect2) -> Rect2:
	return BattleProjectionScript.tile_ui_rect(tile, board_rect, GRID_W, GRID_H)


func screen_to_tile(pos: Vector2, board_rect: Rect2) -> Vector2i:
	return BattleProjectionScript.screen_to_tile(pos, board_rect, GRID_W, GRID_H)


func in_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < GRID_W and tile.y < GRID_H


func manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


func phase_name() -> String:
	if phase == "player":
		return "我方行动"
	if phase == "enemy":
		return "敌方行动"
	return "结算"


func _join_strings(values: Array, separator: String) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(String(value))
	return separator.join(parts)
