class_name BattleContent
extends RefCounted

const CARD_STRIKE := BattleAssets.CARD_STRIKE
const CARD_LANCE := BattleAssets.CARD_LANCE
const CARD_DASH := BattleAssets.CARD_DASH
const CARD_GUARD := BattleAssets.CARD_GUARD
const CARD_ENGAGE := BattleAssets.CARD_ENGAGE
const CARD_HEAL := BattleAssets.CARD_HEAL

const CARD_LIBRARY := {
	"swift_slash": {"title": "迅捷斩", "kind": CARD_STRIKE, "cost": 1, "text": "对相邻敌人造成7点伤害。", "target_mode": "enemy", "executor_tags": ["sword", "command"], "bonus_tags": ["sword"]},
	"silver_edge": {"title": "银锋断袭", "kind": CARD_STRIKE, "cost": 2, "text": "对相邻敌人造成10点伤害。", "target_mode": "enemy", "executor_tags": ["sword", "command"], "bonus_tags": ["sword"]},
	"radiant_lance": {"title": "辉光枪", "kind": CARD_LANCE, "cost": 2, "text": "直线3格内造成9点伤害。", "target_mode": "line", "executor_tags": ["lance", "faith"], "bonus_tags": ["lance"]},
	"tactical_step": {"title": "战术步", "kind": CARD_DASH, "cost": 1, "text": "移动至3格内空位。", "target_mode": "tile", "executor_tags": ["sword", "lance", "faith", "command"], "bonus_tags": []},
	"fleet_reposition": {"title": "疾令换阵", "kind": CARD_DASH, "cost": 0, "text": "移动1格并结束行动。", "target_mode": "tile", "executor_tags": ["sword", "lance", "faith", "command"], "bonus_tags": ["command"]},
	"guard_bloom": {"title": "守护绽放", "kind": CARD_GUARD, "cost": 1, "text": "执行者获得8点格挡。", "target_mode": "unit_self", "executor_tags": ["lance", "command"], "bonus_tags": ["lance"]},
	"oath_wall": {"title": "誓约壁垒", "kind": CARD_GUARD, "cost": 2, "text": "执行者获得14点格挡。", "target_mode": "unit_self", "executor_tags": ["lance", "command"], "bonus_tags": ["lance"]},
	"crest_resonance": {"title": "纹章共鸣", "kind": CARD_ENGAGE, "cost": 2, "text": "全队力量+2。", "target_mode": "unit_self", "executor_tags": ["command"], "bonus_tags": ["command"]},
	"azure_command": {"title": "苍翼号令", "kind": CARD_ENGAGE, "cost": 2, "text": "全队力量+1。", "target_mode": "unit_self", "executor_tags": ["command"], "bonus_tags": ["command"]},
	"mend_light": {"title": "愈光", "kind": CARD_HEAL, "cost": 1, "text": "恢复一名友军6点生命。", "target_mode": "ally", "executor_tags": ["faith"], "bonus_tags": ["faith"]},
	"seraphic_mend": {"title": "圣辉庇愈", "kind": CARD_HEAL, "cost": 2, "text": "恢复友军8点生命，并获得4格挡。", "target_mode": "ally", "executor_tags": ["faith"], "bonus_tags": ["faith"]},
	"ember_thrust": {"title": "烬火突刺", "kind": CARD_LANCE, "cost": 1, "text": "直线3格内造成6点伤害。", "target_mode": "line", "executor_tags": ["lance"], "bonus_tags": ["lance"]},
	"royal_order": {"title": "王令整备", "kind": CARD_ENGAGE, "cost": 1, "text": "全队力量+1。", "target_mode": "unit_self", "executor_tags": ["command"], "bonus_tags": ["command"]},
	"sanctuary": {"title": "圣域祷言", "kind": CARD_HEAL, "cost": 2, "text": "恢复一名友军10点生命。", "target_mode": "ally", "executor_tags": ["faith"], "bonus_tags": ["faith"]},
	"aegis_step": {"title": "守势换位", "kind": CARD_DASH, "cost": 1, "text": "移动至2格内，并获得3格挡。", "target_mode": "tile", "executor_tags": ["lance", "command"], "bonus_tags": ["lance"]},
}

const DECK_STARTER := [
	"swift_slash",
	"crest_resonance",
	"mend_light",
	"radiant_lance",
	"guard_bloom",
	"ember_thrust",
]

const CHARACTER_SKILL_POOLS := {
	"astra": [
		"crest_resonance",
	],
	"liora": [
		"mend_light",
	],
	"kael": [
		"guard_bloom",
	],
	"evelyn": [
		"swift_slash",
	],
}

const LEARNING_REWARD_POOLS := {
	1: {
		1: ["royal_order", "sanctuary", "aegis_step"],
		2: ["silver_edge", "oath_wall", "seraphic_mend", "azure_command"],
	},
	2: {
		1: ["fleet_reposition", "sanctuary", "aegis_step"],
		2: ["silver_edge", "oath_wall", "seraphic_mend", "azure_command"],
	},
}

const UNIT_LIBRARY := {
	"hero_astra": {"id": "hero", "name": "阿斯特拉", "team": "player", "role": "hero", "hp": 30, "max_hp": 30, "atk": 4, "move_range": 3, "attack_range": 1, "weapon_name": "苍纹剑", "skill_name": "纹章斩", "intent_kind": "command"},
	"hero_liora": {"id": "faith", "name": "莉奥拉", "team": "player", "role": "faith", "hp": 24, "max_hp": 24, "atk": 3, "move_range": 3, "attack_range": 2, "weapon_name": "圣辉杖", "skill_name": "愈光术式", "intent_kind": "mend"},
	"hero_kael": {"id": "guard", "name": "凯尔", "team": "player", "role": "lance", "hp": 34, "max_hp": 34, "atk": 4, "move_range": 2, "attack_range": 1, "weapon_name": "誓盾枪", "skill_name": "护卫架势", "intent_kind": "hold"},
	"hero_evelyn": {"id": "hero", "name": "伊芙琳", "team": "player", "role": "scout", "character_id": "evelyn", "hp": 26, "max_hp": 26, "atk": 4, "move_range": 3, "attack_range": 2, "weapon_name": "回廊短弓", "skill_name": "斥候标记", "intent_kind": "scout"},
	"enemy_sword": {"id": "sword", "name": "赤刃侍从", "team": "enemy", "role": "sword", "hp": 12, "max_hp": 12, "atk": 3, "move_range": 1, "attack_range": 1, "weapon_name": "赤刃短剑", "skill_name": "追击", "intent_kind": "chase"},
	"enemy_mage": {"id": "mage", "name": "符焰术士", "team": "enemy", "role": "mage", "hp": 10, "max_hp": 10, "atk": 4, "move_range": 1, "attack_range": 2, "weapon_name": "符焰法杖", "skill_name": "二格术式", "intent_kind": "cast"},
	"enemy_guard": {"id": "guard", "name": "誓盾卫士", "team": "enemy", "role": "guard", "hp": 16, "max_hp": 16, "atk": 3, "move_range": 1, "attack_range": 1, "weapon_name": "誓盾锤", "skill_name": "架盾", "intent_kind": "shield"},
	"enemy_boss": {"id": "sword", "name": "赤刃队长", "team": "enemy", "role": "sword", "hp": 24, "max_hp": 24, "atk": 5, "move_range": 1, "attack_range": 1, "weapon_name": "队长长剑", "skill_name": "强袭", "intent_kind": "chase"},
}

const ENCOUNTERS := {
	"chapter1_1": [
		{"unit": "hero_astra", "pos": Vector2i(1, 4)},
		{"unit": "hero_liora", "pos": Vector2i(0, 5)},
		{"unit": "hero_kael", "pos": Vector2i(1, 3)},
		{"unit": "enemy_sword", "pos": Vector2i(7, 3)},
		{"unit": "enemy_guard", "pos": Vector2i(8, 5)},
	],
	"chapter1_2": [
		{"unit": "hero_astra", "pos": Vector2i(1, 4)},
		{"unit": "hero_liora", "pos": Vector2i(0, 5)},
		{"unit": "hero_kael", "pos": Vector2i(1, 3)},
		{"unit": "enemy_boss", "pos": Vector2i(6, 3)},
		{"unit": "enemy_mage", "pos": Vector2i(8, 2)},
		{"unit": "enemy_guard", "pos": Vector2i(8, 5)},
	],
	"chapter1_3": [
		{"unit": "hero_astra", "pos": Vector2i(1, 4)},
		{"unit": "hero_liora", "pos": Vector2i(0, 5)},
		{"unit": "hero_kael", "pos": Vector2i(1, 3)},
		{"unit": "enemy_boss", "pos": Vector2i(7, 4)},
		{"unit": "enemy_mage", "pos": Vector2i(8, 1)},
		{"unit": "enemy_guard", "pos": Vector2i(8, 6)},
	]
}

const CHAPTERS := {
	1: {
		"title": "苍纹圣庭遭袭",
		"place": "苍纹圣庭 · 晨辉露台",
		"enemy": "赤刃佣兵与符焰术士",
		"dialogue_bg": "chapter1_sanctuary_terrace",
		"encounters": ["chapter1_1", "chapter1_2"],
		"dialogue": [
			{"speaker": "阿斯特拉", "portrait_id": "astra", "text": "晨祷钟被刀声截断。外庭已经失守，我们只剩中庭这一道线。"},
			{"speaker": "莉奥拉", "portrait_id": "liora", "text": "平民还在圣辉门后撤离。别让符焰术式越过喷泉。"},
			{"speaker": "凯尔", "portrait_id": "kael", "text": "那我把盾插在中线。队长露头时，阿斯特拉，斩断他的旗。"},
		],
	}
}

const CHARACTER_LIBRARY := {
	"astra": {"unit": "hero_astra", "name": "阿斯特拉", "class_id": "lord_sword", "level": 1, "xp": 0},
	"liora": {"unit": "hero_liora", "name": "莉奥拉", "class_id": "saint_mage", "level": 1, "xp": 0},
	"kael": {"unit": "hero_kael", "name": "凯尔", "class_id": "oath_lancer", "level": 1, "xp": 0},
	"evelyn": {"unit": "hero_evelyn", "name": "伊芙琳", "class_id": "corridor_scout", "level": 1, "xp": 0},
}

const CLASS_LIBRARY := {
	"lord_sword": {"name": "苍纹剑士", "tier": 1, "tags": ["sword", "command"], "passive_id": "crest_edge", "hp_bonus": 0, "atk_bonus": 0, "promotes_to": ["azure_duelist", "crest_commander"]},
	"saint_mage": {"name": "圣辉术士", "tier": 1, "tags": ["faith"], "passive_id": "gentle_light", "hp_bonus": 0, "atk_bonus": 0, "promotes_to": ["seraphic_sage", "rune_bishop"]},
	"oath_lancer": {"name": "誓盾枪卫", "tier": 1, "tags": ["lance"], "passive_id": "vow_guard", "hp_bonus": 0, "atk_bonus": 0, "promotes_to": ["fortress_vow", "sunlance_knight"]},
	"corridor_scout": {"name": "回廊斥候", "tier": 1, "tags": ["sword", "command"], "passive_id": "scout_mark", "hp_bonus": 0, "atk_bonus": 0, "promotes_to": ["crest_commander", "azure_duelist"]},
	"azure_duelist": {"name": "苍翼决斗者", "tier": 2, "tags": ["sword", "command"], "passive_id": "duel_flash", "hp_bonus": 4, "atk_bonus": 2, "promotes_to": []},
	"crest_commander": {"name": "纹章统领", "tier": 2, "tags": ["sword", "command"], "passive_id": "royal_tactics", "hp_bonus": 6, "atk_bonus": 1, "promotes_to": []},
	"seraphic_sage": {"name": "圣翼贤者", "tier": 2, "tags": ["faith"], "passive_id": "seraphic_grace", "hp_bonus": 4, "atk_bonus": 1, "promotes_to": []},
	"rune_bishop": {"name": "符文司祭", "tier": 2, "tags": ["faith", "command"], "passive_id": "rune_prayer", "hp_bonus": 2, "atk_bonus": 2, "promotes_to": []},
	"fortress_vow": {"name": "誓壁卫将", "tier": 2, "tags": ["lance"], "passive_id": "iron_oath", "hp_bonus": 8, "atk_bonus": 1, "promotes_to": []},
	"sunlance_knight": {"name": "辉枪骑士", "tier": 2, "tags": ["lance", "sword"], "passive_id": "sunlance_drive", "hp_bonus": 5, "atk_bonus": 2, "promotes_to": []},
}

const PASSIVE_LIBRARY := {
	"crest_edge": "使用剑术或指挥技能时伤害+1。",
	"gentle_light": "治疗技能额外恢复1点生命。",
	"vow_guard": "格挡技能额外获得2点格挡。",
	"duel_flash": "近战击破敌人时获得2点格挡。",
	"royal_tactics": "指挥技能额外提供1点力量。",
	"seraphic_grace": "治疗技能额外恢复3点生命。",
	"rune_prayer": "圣辉技能可触发指挥标签。",
	"iron_oath": "每场战斗开始获得4点格挡。",
	"sunlance_drive": "枪术技能伤害+2。",
	"scout_mark": "攻击范围为2，适合牵制与侧翼支援。",
}

const LEVEL_DATA_PATH := "res://assets/data/levels/chapter1_battles.json"
const TILEMAP_TERRAIN_BY_ATLAS := {
	Vector2i(0, 0): "floor",
	Vector2i(1, 0): "wall",
	Vector2i(2, 0): "pillar",
	Vector2i(3, 0): "gate",
	Vector2i(4, 0): "floor",
	Vector2i(5, 0): "floor",
	Vector2i(6, 0): "floor",
	Vector2i(7, 0): "floor",
	Vector2i(0, 1): "high",
	Vector2i(1, 1): "holy",
	Vector2i(2, 1): "fire",
	Vector2i(3, 1): "marker",
	Vector2i(4, 1): "floor",
	Vector2i(5, 1): "floor",
	Vector2i(6, 1): "floor",
	Vector2i(7, 1): "floor",
	Vector2i(0, 2): "wall",
	Vector2i(1, 2): "wall",
	Vector2i(2, 2): "wall",
	Vector2i(3, 2): "wall",
	Vector2i(4, 2): "wall",
	Vector2i(5, 2): "wall",
	Vector2i(6, 2): "pillar",
	Vector2i(7, 2): "floor",
	Vector2i(0, 3): "pillar",
	Vector2i(1, 3): "wall",
	Vector2i(2, 3): "wall",
	Vector2i(3, 3): "pillar",
	Vector2i(4, 3): "floor",
	Vector2i(5, 3): "pillar",
	Vector2i(6, 3): "high",
	Vector2i(7, 3): "wall",
	Vector2i(0, 4): "fire",
	Vector2i(1, 4): "fire",
	Vector2i(2, 4): "holy",
	Vector2i(3, 4): "marker",
	Vector2i(4, 4): "pillar",
	Vector2i(5, 4): "high",
	Vector2i(6, 4): "floor",
	Vector2i(7, 4): "wall",
	Vector2i(0, 5): "floor",
	Vector2i(1, 5): "floor",
	Vector2i(2, 5): "floor",
	Vector2i(3, 5): "floor",
	Vector2i(4, 5): "holy",
	Vector2i(5, 5): "marker",
	Vector2i(6, 5): "floor",
	Vector2i(7, 5): "wall",
}

var level_data_cache: Dictionary = {}


func build_deck(deck_id: String = "starter") -> Array:
	var recipe: Array = DECK_STARTER
	match deck_id:
		"starter":
			recipe = DECK_STARTER
	return build_deck_from_ids(recipe)


func starter_deck_ids() -> Array:
	return DECK_STARTER.duplicate()


func base_skill_ids(character_id: String) -> Array:
	return CHARACTER_SKILL_POOLS.get(character_id, []).duplicate()


func learning_reward_pool(chapter_index: int, battle_in_chapter: int) -> Array:
	var chapter_pools: Dictionary = LEARNING_REWARD_POOLS.get(chapter_index, {})
	var pool: Array = chapter_pools.get(battle_in_chapter, [])
	if pool.is_empty():
		pool = ["royal_order", "sanctuary", "aegis_step", "silver_edge", "oath_wall", "seraphic_mend", "azure_command"]
	return pool.duplicate()


func build_deck_from_ids(card_ids: Array) -> Array:
	var cards: Array = []
	for card_id in card_ids:
		cards.append(create_card(card_id))
	return cards


func create_card(card_id: String) -> Dictionary:
	var template: Dictionary = CARD_LIBRARY.get(card_id, {})
	var card := template.duplicate(true)
	card["id"] = card_id
	card["tier"] = _card_tier(card_id)
	card["school"] = _card_school(card["kind"])
	card["owner_role"] = _owner_role(card.get("executor_tags", []))
	return card


func _card_tier(card_id: String) -> String:
	if card_id in ["silver_edge", "oath_wall", "azure_command", "seraphic_mend", "sanctuary"]:
		return "精良"
	if card_id in ["crest_resonance", "radiant_lance", "aegis_step"]:
		return "进阶"
	return "基础"


func _card_school(kind: String) -> String:
	match kind:
		CARD_STRIKE, CARD_LANCE:
			return "锋刃"
		CARD_DASH:
			return "阵步"
		CARD_GUARD:
			return "誓盾"
		CARD_ENGAGE:
			return "纹章"
		CARD_HEAL:
			return "圣辉"
	return "战术"


func build_party() -> Array:
	var party: Array = []
	for character_id in ["astra", "liora", "kael"]:
		var member := build_party_member(character_id)
		member["deployed"] = true
		party.append(member)
	return party


func build_party_member(character_id: String) -> Dictionary:
	var template: Dictionary = CHARACTER_LIBRARY.get(character_id, {})
	var class_data: Dictionary = CLASS_LIBRARY.get(template.get("class_id", ""), {})
	var member := template.duplicate(true)
	member["character_id"] = character_id
	member["class_tier"] = class_data.get("tier", 1)
	member["class_tags"] = class_data.get("tags", []).duplicate()
	member["passive_id"] = class_data.get("passive_id", "")
	member["skill_ids"] = base_skill_ids(character_id)
	member["learned_skills"] = []
	member["deployed"] = false
	return member


func chapter_data(chapter_index: int) -> Dictionary:
	var loaded_chapter := _loaded_chapter_data(chapter_index)
	if not loaded_chapter.is_empty():
		return loaded_chapter
	return CHAPTERS.get(chapter_index, CHAPTERS[1]).duplicate(true)


func has_chapter(chapter_index: int) -> bool:
	return not _loaded_chapter_data(chapter_index).is_empty() or CHAPTERS.has(chapter_index)


func encounter_for_battle(chapter_index: int, battle_in_chapter: int) -> String:
	var chapter := chapter_data(chapter_index)
	var encounters: Array = chapter["encounters"]
	var index := clampi(battle_in_chapter - 1, 0, encounters.size() - 1)
	return encounters[index]


func build_encounter(encounter_id: String = "chapter1_1", party: Array = []) -> Array:
	var recipe: Array = _encounter_recipe(encounter_id)
	var units: Array = []
	var index := 0
	for entry in recipe:
		var unit_id: String = entry["unit"]
		var unit := create_unit(unit_id, entry["pos"], index)
		if unit["team"] == "player":
			_apply_party_data(unit, party)
		units.append(unit)
		index += 1
	return units


func battlefield_terrain(encounter_id: String = "chapter1_1") -> Dictionary:
	var level := _level_recipe(encounter_id)
	var tilemap_scene := String(level.get("tilemap_scene", ""))
	if tilemap_scene != "":
		var scene_terrain := _terrain_from_tilemap_scene(tilemap_scene)
		if not scene_terrain.is_empty():
			return scene_terrain
	var terrain_map := _terrain_recipe(encounter_id)
	if not terrain_map.is_empty():
		return terrain_map
	return _default_terrain()


func battle_tilemap_scene_path(encounter_id: String = "chapter1_1") -> String:
	var level := _level_recipe(encounter_id)
	return String(level.get("tilemap_scene", ""))


func battle_background_path(encounter_id: String = "chapter1_1") -> String:
	var level := _level_recipe(encounter_id)
	return String(level.get("battlefield_background", ""))


func battle_tutorial_steps(encounter_id: String = "chapter1_1") -> Array:
	var level := _level_recipe(encounter_id)
	return level.get("tutorial_steps", []).duplicate(true)


func battle_post_tutorial_objective(encounter_id: String = "chapter1_1") -> Dictionary:
	var level := _level_recipe(encounter_id)
	return level.get("post_tutorial_objective", {}).duplicate(true)


func battle_story_brief(encounter_id: String = "chapter1_1") -> String:
	var level := _level_recipe(encounter_id)
	return String(level.get("story_brief", ""))


func battle_objective_detail(encounter_id: String = "chapter1_1") -> String:
	var level := _level_recipe(encounter_id)
	return String(level.get("objective_detail", ""))


func battle_objective(encounter_id: String = "chapter1_1") -> Dictionary:
	var level := _level_recipe(encounter_id)
	var objective_type := String(level.get("objective_type", "rout"))
	var objective := {
		"type": objective_type,
		"title": String(level.get("objective_title", "")),
		"reach_tiles": [],
	}
	for raw_pos in level.get("reach_tiles", []):
		objective["reach_tiles"].append(_array_to_vector2i(raw_pos))
	return objective


func battle_recruitment(encounter_id: String = "chapter1_1") -> Dictionary:
	var level := _level_recipe(encounter_id)
	return level.get("recruitment", {}).duplicate(true)


func chapter_camp_events(chapter_index: int) -> Array:
	var chapter := chapter_data(chapter_index)
	return chapter.get("camp_events", _default_camp_events()).duplicate(true)


func encounter_name(encounter_id: String) -> String:
	var level := _level_recipe(encounter_id)
	return String(level.get("name", encounter_id))


func create_unit(unit_id: String, pos: Vector2i, encounter_index: int = 0) -> Dictionary:
	var template: Dictionary = UNIT_LIBRARY.get(unit_id, {})
	var unit := template.duplicate(true)
	unit["uid"] = "%s_%d" % [unit_id, encounter_index]
	unit["unit_key"] = unit_id
	unit["pos"] = pos
	unit["block"] = 0
	unit["dead"] = false
	return unit


func create_party_unit(member: Dictionary, pos: Vector2i, encounter_index: int = 0) -> Dictionary:
	var unit := create_unit(String(member.get("unit", "")), pos, encounter_index)
	_apply_party_data(unit, [member])
	return unit


func promotion_options(member: Dictionary) -> Array:
	var class_id: String = member.get("class_id", "")
	var class_data: Dictionary = CLASS_LIBRARY.get(class_id, {})
	var options: Array = []
	for next_class_id in class_data.get("promotes_to", []):
		var next_class: Dictionary = CLASS_LIBRARY[next_class_id]
		options.append({
			"character_id": member["character_id"],
			"class_id": next_class_id,
			"name": next_class["name"],
			"tier": next_class["tier"],
			"tags": next_class["tags"],
			"passive_id": next_class["passive_id"],
			"passive": PASSIVE_LIBRARY.get(next_class["passive_id"], ""),
			"hp_bonus": next_class["hp_bonus"],
			"atk_bonus": next_class["atk_bonus"],
		})
	return options


func get_class_name(class_id: String) -> String:
	return CLASS_LIBRARY.get(class_id, {}).get("name", class_id)


func passive_text(passive_id: String) -> String:
	return PASSIVE_LIBRARY.get(passive_id, "")


func _default_camp_events() -> Array:
	return [
		{
			"id": "astra_review",
			"speaker": "阿斯特拉",
			"title": "战术复盘",
			"text": "把刚才的阵线拆解一遍。下一战开局力量 +1。",
			"bonus": "power",
			"amount": 1,
			"icon_key": "engage",
			"summary": "战术复盘：下一战开局力量 +1",
		},
		{
			"id": "liora_prayer",
			"speaker": "莉奥拉",
			"title": "圣辉祝祷",
			"text": "为前线刻下短效庇护。下一战全员生命上限 +2。",
			"bonus": "max_hp",
			"amount": 2,
			"icon_key": "heal",
			"summary": "圣辉祝祷：下一战全员生命上限 +2",
		},
		{
			"id": "kael_watch",
			"speaker": "凯尔",
			"title": "夜巡布防",
			"text": "提前立起盾线。下一战全员开局格挡 +4。",
			"bonus": "block",
			"amount": 4,
			"icon_key": "guard",
			"summary": "夜巡布防：下一战全员开局格挡 +4",
		},
	]


func _apply_party_data(unit: Dictionary, party: Array) -> void:
	for member in party:
		if member.get("unit", "") != unit.get("unit_key", "") and not _unit_matches_character(unit, member):
			continue
		var class_data: Dictionary = CLASS_LIBRARY.get(member["class_id"], {})
		unit["character_id"] = member["character_id"]
		unit["class_id"] = member["class_id"]
		unit["class_tier"] = class_data.get("tier", 1)
		unit["class_tags"] = class_data.get("tags", []).duplicate()
		unit["passive_id"] = class_data.get("passive_id", "")
		unit["level"] = member.get("level", 1)
		unit["xp"] = member.get("xp", 0)
		unit["class_name"] = class_data.get("name", "")
		var level_hp_bonus := _level_hp_bonus(member)
		var level_atk_bonus := _level_atk_bonus(member)
		unit["hp"] = int(unit["hp"]) + int(class_data.get("hp_bonus", 0)) + level_hp_bonus
		unit["max_hp"] = int(unit["max_hp"]) + int(class_data.get("hp_bonus", 0)) + level_hp_bonus
		unit["atk"] = int(unit["atk"]) + int(class_data.get("atk_bonus", 0)) + level_atk_bonus
		return


func _level_hp_bonus(member: Dictionary) -> int:
	var total := 0
	var tags: Array = member.get("class_tags", [])
	for level in range(2, int(member.get("level", 1)) + 1):
		var gain := 2
		if tags.has("lance"):
			gain += 1
		elif tags.has("faith"):
			gain = 1
		total += gain
	return total


func _level_atk_bonus(member: Dictionary) -> int:
	var total := 0
	var tags: Array = member.get("class_tags", [])
	for level in range(2, int(member.get("level", 1)) + 1):
		var gain := 1 if level % 2 == 0 else 0
		if tags.has("faith") and level % 3 == 0:
			gain += 1
		total += gain
	return total


func _unit_matches_character(unit: Dictionary, member: Dictionary) -> bool:
	var character_id: String = member.get("character_id", "")
	if character_id == "astra" and unit.get("id", "") == "hero":
		return true
	if character_id == "liora" and unit.get("name", "") == "莉奥拉":
		return true
	if character_id == "kael" and unit.get("name", "") == "凯尔":
		return true
	if character_id == "evelyn" and unit.get("name", "") == "伊芙琳":
		return true
	return false


func _owner_role(tags: Array) -> String:
	if tags.has("faith"):
		return "faith"
	if tags.has("lance"):
		return "lance"
	if tags.has("sword"):
		return "sword"
	if tags.has("command"):
		return "command"
	return "tactic"


func _encounter_recipe(encounter_id: String) -> Array:
	var level := _level_recipe(encounter_id)
	if level.has("units"):
		var recipe: Array = []
		for entry in level.get("units", []):
			recipe.append({
				"unit": String(entry.get("unit", "")),
				"pos": _array_to_vector2i(entry.get("pos", [0, 0])),
			})
		return recipe
	return ENCOUNTERS.get(encounter_id, [])


func _terrain_recipe(encounter_id: String) -> Dictionary:
	var data := _load_level_data()
	var level := _level_recipe(encounter_id)
	var terrain_source: Dictionary = {}
	if level.has("terrain_preset"):
		var presets: Dictionary = data.get("terrain_presets", {})
		terrain_source = presets.get(String(level.get("terrain_preset", "")), {})
	var terrain_override: Dictionary = level.get("terrain", {})
	if terrain_source.is_empty() and terrain_override.is_empty():
		return {}
	var terrain_map: Dictionary = {}
	_apply_terrain_recipe_source(terrain_map, terrain_source)
	_apply_terrain_recipe_source(terrain_map, terrain_override)
	return terrain_map


func _apply_terrain_recipe_source(terrain_map: Dictionary, source: Dictionary) -> void:
	for kind in source.keys():
		for raw_pos in source[kind]:
			terrain_map[_array_to_vector2i(raw_pos)] = String(kind)


func _terrain_from_tilemap_scene(scene_path: String) -> Dictionary:
	if not ResourceLoader.exists(scene_path):
		push_warning("TileMap terrain scene does not exist: %s" % scene_path)
		return {}
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_warning("TileMap terrain scene is not a PackedScene: %s" % scene_path)
		return {}
	var root := packed.instantiate()
	var tilemap := _find_tilemap_layer(root)
	if tilemap == null:
		root.queue_free()
		push_warning("TileMap terrain scene has no TileMapLayer: %s" % scene_path)
		return {}
	var terrain_map: Dictionary = {}
	for used_cell in tilemap.get_used_cells():
		var cell: Vector2i = used_cell
		if cell.x < 0 or cell.y < 0 or cell.x >= 10 or cell.y >= 8:
			continue
		var atlas: Vector2i = tilemap.get_cell_atlas_coords(cell)
		var kind := String(TILEMAP_TERRAIN_BY_ATLAS.get(atlas, "floor"))
		terrain_map[cell] = kind
	root.queue_free()
	return terrain_map


func _find_tilemap_layer(node: Node) -> Node:
	if node is TileMapLayer:
		return node
	for child in node.get_children():
		var found := _find_tilemap_layer(child)
		if found != null:
			return found
	return null


func _level_recipe(encounter_id: String) -> Dictionary:
	var data := _load_level_data()
	for battle in data.get("battles", []):
		if String(battle.get("id", "")) == encounter_id:
			return battle
	return {}


func _loaded_chapter_data(chapter_index: int) -> Dictionary:
	var data := _load_level_data()
	for chapter_entry in data.get("chapters", []):
		var chapter_from_list: Dictionary = chapter_entry
		if int(chapter_from_list.get("index", 0)) == chapter_index:
			return chapter_from_list.duplicate(true)
	var chapter: Dictionary = data.get("chapter", {})
	if chapter.is_empty() or int(chapter.get("index", 0)) != chapter_index:
		return {}
	return chapter.duplicate(true)


func _load_level_data() -> Dictionary:
	if not level_data_cache.is_empty():
		return level_data_cache
	if not FileAccess.file_exists(LEVEL_DATA_PATH):
		return {}
	var text := FileAccess.get_file_as_string(LEVEL_DATA_PATH)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		level_data_cache = parsed
	return level_data_cache


func _array_to_vector2i(value: Variant) -> Vector2i:
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	if value is Vector2i:
		return value
	return Vector2i.ZERO


func _default_terrain() -> Dictionary:
	var default_terrain: Dictionary = {}
	for x in range(10):
		default_terrain[Vector2i(x, 0)] = "wall"
		default_terrain[Vector2i(x, 7)] = "wall"
	for y in range(8):
		default_terrain[Vector2i(0, y)] = "wall" if y < 2 else "floor"
		default_terrain[Vector2i(9, y)] = "wall"
	for p in [Vector2i(3, 2), Vector2i(3, 5), Vector2i(6, 2), Vector2i(6, 5)]:
		default_terrain[p] = "pillar"
	for p in [Vector2i(4, 0), Vector2i(5, 0)]:
		default_terrain[p] = "gate"
	for p in [Vector2i(4, 3), Vector2i(5, 3)]:
		default_terrain[p] = "high"
	for p in [Vector2i(2, 5)]:
		default_terrain[p] = "holy"
	for p in [Vector2i(7, 4)]:
		default_terrain[p] = "fire"
	for p in [Vector2i(1, 6), Vector2i(8, 1)]:
		default_terrain[p] = "marker"
	return default_terrain
