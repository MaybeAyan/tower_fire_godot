extends SceneTree

const BattleContentScript := preload("res://scripts/core/BattleContent.gd")

const GRID_W := 10
const GRID_H := 8
const WALKABLE_TERRAIN := ["floor", "gate", "high", "holy", "fire", "marker"]
const KNOWN_TERRAIN := ["floor", "wall", "pillar", "gate", "high", "holy", "fire", "marker"]
const KNOWN_OBJECTIVE_TYPES := ["rout", "reach"]
const KNOWN_TUTORIAL_ACTIONS := ["select_unit", "move_or_wait", "attack_or_skill", "end_turn"]
const KNOWN_CAMP_EVENT_BONUSES := ["power", "max_hp", "block"]
const KNOWN_CAMP_EVENT_ICONS := ["strike", "lance", "dash", "guard", "engage", "heal"]
const KNOWN_MIRROR_MODES := ["player", "enemy", "fixed"]
const ART_ASSETS_PATH := "res://assets/data/art_assets.json"
const REQUIRED_ART_KEYS := {
	"tokens": ["hero", "faith", "sword", "mage", "guard"],
	"portraits": ["astra", "liora", "kael"],
	"cards": ["strike", "lance", "dash", "guard", "engage", "heal"],
	"ui": ["status_panel", "hand_dock", "iso_status_panel", "iso_skill_dock", "skill_card_frame", "objective_pill", "small_button", "glass_status_panel", "glass_status_panel_rich", "glass_hand_dock", "glass_skill_strip", "glass_prompt_pill", "glass_hp_bar", "oil_status_panel", "oil_hand_dock", "oil_skill_strip", "oil_prompt_pill", "oil_hp_bar", "oil_safe_corner", "oil_safe_edge_h", "oil_safe_edge_v", "oil_safe_button_glow", "oil_safe_crest", "sidebar_inner", "reward_panel", "range_floor", "range_move", "range_attack", "range_danger", "range_selected", "selected_ring", "dialogue_frame", "dialogue_nameplate", "hp_bar", "exp_bar", "level_badge", "exp_gem"],
	"vfx": ["hit", "slash", "magic", "heal", "guard", "death"],
	"atmosphere": ["sacred_crest", "rune_fire", "lantern_glow", "torn_banner"],
}

var content = BattleContentScript.new()
var errors: Array[String] = []
var warnings: Array[String] = []
var referenced_dialogue_bg_ids: Array[String] = []


func _init() -> void:
	_validate_level_file()
	_validate_art_assets_file()
	_validate_character_skill_pools()
	_print_result()
	quit(1 if not errors.is_empty() else 0)


func _validate_level_file() -> void:
	var path: String = BattleContentScript.LEVEL_DATA_PATH
	if not FileAccess.file_exists(path):
		_add_error("Level data file missing: %s" % path)
		return
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_add_error("Level data file is not valid JSON object: %s" % path)
		return
	var data: Dictionary = parsed
	var chapter: Dictionary = data.get("chapter", {})
	var chapters: Array = data.get("chapters", [])
	var battles: Array = data.get("battles", [])
	var terrain_presets: Dictionary = data.get("terrain_presets", {})
	_validate_chapter(chapter, battles)
	for extra_chapter in chapters:
		_validate_chapter(extra_chapter, battles)
	_validate_terrain_presets(terrain_presets)
	_validate_battles(battles, terrain_presets)


func _validate_chapter(chapter: Dictionary, battles: Array) -> void:
	if chapter.is_empty():
		_add_error("Chapter block is missing.")
		return
	var battle_ids: Array[String] = []
	for battle in battles:
		battle_ids.append(String(battle.get("id", "")))
	for encounter_id in chapter.get("encounters", []):
		if not battle_ids.has(String(encounter_id)):
			_add_error("Chapter references missing encounter: %s" % String(encounter_id))
	if chapter.get("dialogue", []).is_empty():
		_add_warning("Chapter has no intro dialogue.")
	var chapter_bg := String(chapter.get("dialogue_bg", ""))
	if chapter_bg != "" and not referenced_dialogue_bg_ids.has(chapter_bg):
		referenced_dialogue_bg_ids.append(chapter_bg)
	for line in chapter.get("dialogue", []):
		var line_bg := String(line.get("bg", ""))
		if line_bg != "" and not referenced_dialogue_bg_ids.has(line_bg):
			referenced_dialogue_bg_ids.append(line_bg)
	_validate_camp_events(chapter.get("camp_events", []))


func _validate_camp_events(events: Array) -> void:
	var seen_ids: Array[String] = []
	for i in range(events.size()):
		var event: Dictionary = events[i]
		var event_id := String(event.get("id", ""))
		if event_id == "":
			_add_error("Camp event %d is missing id." % i)
		elif seen_ids.has(event_id):
			_add_error("Duplicate camp event id: %s" % event_id)
		seen_ids.append(event_id)
		for field in ["speaker", "title", "text", "summary"]:
			if String(event.get(field, "")) == "":
				_add_error("Camp event %s is missing %s." % [event_id if event_id != "" else str(i), field])
		var bonus := String(event.get("bonus", ""))
		if not KNOWN_CAMP_EVENT_BONUSES.has(bonus):
			_add_error("Camp event %s uses unknown bonus: %s" % [event_id if event_id != "" else str(i), bonus])
		var amount := int(event.get("amount", 0))
		if amount <= 0:
			_add_error("Camp event %s needs a positive amount." % [event_id if event_id != "" else str(i)])
		var icon_key := String(event.get("icon_key", ""))
		if icon_key != "" and not KNOWN_CAMP_EVENT_ICONS.has(icon_key):
			_add_error("Camp event %s uses unknown icon_key: %s" % [event_id if event_id != "" else str(i), icon_key])


func _validate_terrain_presets(terrain_presets: Dictionary) -> void:
	for preset_name in terrain_presets.keys():
		var preset: Dictionary = terrain_presets[preset_name]
		_validate_terrain_map("terrain preset %s" % String(preset_name), preset)


func _validate_battles(battles: Array, terrain_presets: Dictionary) -> void:
	var seen_ids: Array[String] = []
	for battle in battles:
		var battle_id: String = String(battle.get("id", ""))
		if battle_id == "":
			_add_error("Battle is missing id.")
			continue
		if seen_ids.has(battle_id):
			_add_error("Duplicate battle id: %s" % battle_id)
		seen_ids.append(battle_id)
		if battle.has("terrain_preset"):
			var preset_name: String = String(battle.get("terrain_preset", ""))
			if not terrain_presets.has(preset_name):
				_add_error("%s references missing terrain preset: %s" % [battle_id, preset_name])
		if battle.has("terrain"):
			_validate_terrain_map("battle %s terrain" % battle_id, battle.get("terrain", {}))
		var tilemap_scene := String(battle.get("tilemap_scene", ""))
		if tilemap_scene != "" and not ResourceLoader.exists(tilemap_scene):
			_add_error("%s tilemap_scene file missing: %s" % [battle_id, tilemap_scene])
		var battle_bg := String(battle.get("battlefield_background", ""))
		if battle_bg != "" and not FileAccess.file_exists(battle_bg):
			_add_error("%s battlefield_background file missing: %s" % [battle_id, battle_bg])
		_validate_battle_objective(battle, terrain_presets)
		_validate_battle_units(battle, terrain_presets)
		_validate_tutorial_steps(battle)
		_validate_recruitment(battle)


func _validate_battle_units(battle: Dictionary, terrain_presets: Dictionary) -> void:
	var battle_id: String = String(battle.get("id", ""))
	var units: Array = battle.get("units", [])
	if units.is_empty():
		_add_error("%s has no units." % battle_id)
		return
	var occupied: Dictionary = {}
	var terrain_map: Dictionary = _terrain_for_battle(battle, terrain_presets)
	var player_count := 0
	var enemy_count := 0
	for entry in units:
		var unit_id: String = String(entry.get("unit", ""))
		if not BattleContentScript.UNIT_LIBRARY.has(unit_id):
			_add_error("%s references unknown unit id: %s" % [battle_id, unit_id])
			continue
		var pos: Vector2i = _array_to_vector2i(entry.get("pos", []))
		if not _in_bounds(pos):
			_add_error("%s unit %s spawn is out of bounds: %s" % [battle_id, unit_id, str(pos)])
			continue
		var pos_key: String = "%d,%d" % [pos.x, pos.y]
		if occupied.has(pos_key):
			_add_error("%s has overlapping spawns at %s" % [battle_id, pos_key])
		occupied[pos_key] = unit_id
		var terrain_kind: String = terrain_map.get(pos_key, "floor")
		if not WALKABLE_TERRAIN.has(terrain_kind):
			_add_error("%s unit %s spawns on blocked terrain %s at %s" % [battle_id, unit_id, terrain_kind, pos_key])
		var unit_data: Dictionary = BattleContentScript.UNIT_LIBRARY[unit_id]
		if unit_data.get("team", "") == "player":
			player_count += 1
		elif unit_data.get("team", "") == "enemy":
			enemy_count += 1
	if player_count == 0:
		_add_error("%s has no player units." % battle_id)
	if enemy_count == 0:
		_add_error("%s has no enemy units." % battle_id)


func _validate_battle_objective(battle: Dictionary, terrain_presets: Dictionary) -> void:
	var battle_id: String = String(battle.get("id", ""))
	var objective_type := String(battle.get("objective_type", "rout"))
	if not KNOWN_OBJECTIVE_TYPES.has(objective_type):
		_add_error("%s uses unknown objective_type: %s" % [battle_id, objective_type])
	if objective_type != "reach":
		return
	var reach_tiles: Array = battle.get("reach_tiles", [])
	if reach_tiles.is_empty():
		_add_error("%s reach objective needs reach_tiles." % battle_id)
	if String(battle.get("objective_title", "")) == "":
		_add_error("%s reach objective needs objective_title." % battle_id)
	var terrain_map: Dictionary = _terrain_for_battle(battle, terrain_presets)
	var occupied: Dictionary = {}
	for entry in battle.get("units", []):
		var unit_pos := _array_to_vector2i(entry.get("pos", []))
		occupied["%d,%d" % [unit_pos.x, unit_pos.y]] = String(entry.get("unit", ""))
	for raw_pos in reach_tiles:
		var pos := _array_to_vector2i(raw_pos)
		if not _in_bounds(pos):
			_add_error("%s reach tile is out of bounds: %s" % [battle_id, str(pos)])
			continue
		var key := "%d,%d" % [pos.x, pos.y]
		var terrain_kind: String = terrain_map.get(key, "floor")
		if not WALKABLE_TERRAIN.has(terrain_kind):
			_add_error("%s reach tile is blocked by %s at %s" % [battle_id, terrain_kind, key])
		if occupied.has(key):
			_add_error("%s reach tile overlaps unit %s at %s" % [battle_id, occupied[key], key])


func _validate_tutorial_steps(battle: Dictionary) -> void:
	var battle_id: String = String(battle.get("id", ""))
	var steps: Array = battle.get("tutorial_steps", [])
	for i in range(steps.size()):
		var step: Dictionary = steps[i]
		var action := String(step.get("action", ""))
		if not KNOWN_TUTORIAL_ACTIONS.has(action):
			_add_error("%s tutorial step %d uses unknown action: %s" % [battle_id, i, action])
		if String(step.get("title", "")) == "":
			_add_error("%s tutorial step %d is missing title." % [battle_id, i])
		if String(step.get("body", "")) == "":
			_add_error("%s tutorial step %d is missing body." % [battle_id, i])
		var character_id := String(step.get("character_id", ""))
		if character_id != "" and not BattleContentScript.CHARACTER_LIBRARY.has(character_id):
			_add_error("%s tutorial step %d references unknown character: %s" % [battle_id, i, character_id])
		var required_skill_id := String(step.get("required_skill_id", ""))
		if required_skill_id != "":
			_validate_tutorial_skill_id(battle_id, i, "required", required_skill_id, character_id)
		var recommended_skill_id := String(step.get("recommended_skill_id", ""))
		if recommended_skill_id != "":
			_validate_tutorial_skill_id(battle_id, i, "recommended", recommended_skill_id, character_id)
		for raw_pos in step.get("focus", []):
			var pos: Vector2i = _array_to_vector2i(raw_pos)
			if not _in_bounds(pos):
				_add_error("%s tutorial step %d focus is out of bounds: %s" % [battle_id, i, str(pos)])
		for raw_pos in step.get("recommended_focus", []):
			var recommended_pos: Vector2i = _array_to_vector2i(raw_pos)
			if not _in_bounds(recommended_pos):
				_add_error("%s tutorial step %d recommended_focus is out of bounds: %s" % [battle_id, i, str(recommended_pos)])
	var post_tutorial: Dictionary = battle.get("post_tutorial_objective", {})
	if not post_tutorial.is_empty():
		if String(post_tutorial.get("title", "")) == "":
			_add_error("%s post_tutorial_objective is missing title." % battle_id)
		if String(post_tutorial.get("body", "")) == "":
			_add_error("%s post_tutorial_objective is missing body." % battle_id)


func _validate_recruitment(battle: Dictionary) -> void:
	var battle_id: String = String(battle.get("id", ""))
	var recruitment: Dictionary = battle.get("recruitment", {})
	if recruitment.is_empty():
		return
	var character_id := String(recruitment.get("character_id", ""))
	if not BattleContentScript.CHARACTER_LIBRARY.has(character_id):
		_add_error("%s recruitment references unknown character: %s" % [battle_id, character_id])
	var unit_id := String(recruitment.get("unit", ""))
	if not BattleContentScript.UNIT_LIBRARY.has(unit_id):
		_add_error("%s recruitment references unknown unit: %s" % [battle_id, unit_id])
	var condition := String(recruitment.get("condition", ""))
	if condition != "survive":
		_add_error("%s recruitment uses unsupported condition: %s" % [battle_id, condition])
	for field in ["title", "body"]:
		if String(recruitment.get(field, "")) == "":
			_add_error("%s recruitment is missing %s." % [battle_id, field])
	var found_unit := false
	for entry in battle.get("units", []):
		if String(entry.get("unit", "")) == unit_id:
			found_unit = true
	if not found_unit:
		_add_error("%s recruitment unit is not placed in battle units: %s" % [battle_id, unit_id])


func _validate_tutorial_skill_id(battle_id: String, index: int, label: String, skill_id: String, character_id: String) -> void:
	if not BattleContentScript.CARD_LIBRARY.has(skill_id):
		_add_error("%s tutorial step %d references unknown %s skill: %s" % [battle_id, index, label, skill_id])
	elif character_id != "":
		var skill_pool: Array = BattleContentScript.CHARACTER_SKILL_POOLS.get(character_id, [])
		if not skill_pool.has(skill_id):
			_add_error("%s tutorial step %d %s skill %s is not in %s's starting pool." % [battle_id, index, label, skill_id, character_id])


func _validate_terrain_map(label: String, terrain_map: Dictionary) -> void:
	var occupied: Dictionary = {}
	for terrain_kind in terrain_map.keys():
		var kind: String = String(terrain_kind)
		if not KNOWN_TERRAIN.has(kind):
			_add_error("%s uses unknown terrain kind: %s" % [label, kind])
			continue
		for raw_pos in terrain_map[terrain_kind]:
			var pos: Vector2i = _array_to_vector2i(raw_pos)
			if not _in_bounds(pos):
				_add_error("%s has %s tile out of bounds: %s" % [label, kind, str(pos)])
				continue
			var pos_key: String = "%d,%d" % [pos.x, pos.y]
			if occupied.has(pos_key):
				_add_error("%s assigns multiple terrain kinds to %s" % [label, pos_key])
			occupied[pos_key] = kind


func _validate_character_skill_pools() -> void:
	_validate_skill_library_text()
	for character_id in BattleContentScript.CHARACTER_SKILL_POOLS.keys():
		var skill_ids: Array = BattleContentScript.CHARACTER_SKILL_POOLS[character_id]
		if skill_ids.is_empty():
			_add_warning("%s has an empty skill pool." % String(character_id))
		var tags: Array = _class_tags_for_character(String(character_id))
		for skill_id_variant in skill_ids:
			var skill_id: String = String(skill_id_variant)
			if not BattleContentScript.CARD_LIBRARY.has(skill_id):
				_add_error("%s skill pool references unknown card: %s" % [String(character_id), skill_id])
				continue
			var card: Dictionary = BattleContentScript.CARD_LIBRARY[skill_id]
			var executor_tags: Array = card.get("executor_tags", [])
			if not _tags_overlap(tags, executor_tags):
				_add_error("%s cannot execute skill %s; class tags %s do not match %s" % [String(character_id), skill_id, str(tags), str(executor_tags)])


func _validate_skill_library_text() -> void:
	var forbidden_terms := ["抽", "弃", "能量", "再次行动", "额外行动", "免费行动"]
	for skill_id in BattleContentScript.CARD_LIBRARY.keys():
		var skill: Dictionary = BattleContentScript.CARD_LIBRARY[skill_id]
		var text: String = String(skill.get("text", ""))
		for term in forbidden_terms:
			if text.contains(term):
				_add_error("Skill %s contains removed card/action-economy term: %s" % [String(skill_id), term])


func _validate_art_assets_file() -> void:
	if not FileAccess.file_exists(ART_ASSETS_PATH):
		_add_error("Art assets file missing: %s" % ART_ASSETS_PATH)
		return
	var text := FileAccess.get_file_as_string(ART_ASSETS_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_add_error("Art assets file is not valid JSON object: %s" % ART_ASSETS_PATH)
		return
	var data: Dictionary = parsed
	_validate_art_path_field(data, "battlefield", false)
	_validate_art_path_field(data, "terrain_tileset", false)
	for section in REQUIRED_ART_KEYS.keys():
		_validate_art_path_section(data, String(section), REQUIRED_ART_KEYS[section])
	_validate_art_path_section(data, "dialogue_backgrounds", referenced_dialogue_bg_ids, true)
	_validate_art_path_section(data, "unit_action_sheets", [], true)
	var unit_action_sheets: Dictionary = data.get("unit_action_sheets", {})
	if unit_action_sheets.is_empty():
		_add_warning("Art assets file has no unit_action_sheets.")
		return
	_validate_required_action_sheet_keys(unit_action_sheets)
	_validate_unit_action_sheet_meta(data, unit_action_sheets)


func _validate_art_path_field(data: Dictionary, key: String, required: bool) -> void:
	if not data.has(key):
		if required:
			_add_error("Art assets file missing path field: %s" % key)
		return
	var path := String(data[key])
	_validate_res_path("Art asset %s" % key, path)


func _validate_art_path_section(data: Dictionary, section: String, required_keys: Array, allow_extra_keys := false) -> void:
	if not data.has(section):
		_add_error("Art assets file missing section: %s" % section)
		return
	if typeof(data[section]) != TYPE_DICTIONARY:
		_add_error("Art assets section must be an object: %s" % section)
		return
	var paths: Dictionary = data[section]
	if paths.is_empty():
		_add_warning("Art assets section is empty: %s" % section)
	for key in required_keys:
		if not paths.has(String(key)):
			_add_error("Art assets section %s missing key: %s" % [section, String(key)])
	for key in paths.keys():
		if not allow_extra_keys and not required_keys.has(String(key)):
			_add_warning("Art assets section %s has extra key: %s" % [section, String(key)])
		_validate_res_path("Art asset %s.%s" % [section, String(key)], String(paths[key]))


func _validate_res_path(label: String, path: String) -> void:
	if path == "":
		_add_error("%s path is empty." % label)
	elif not path.begins_with("res://"):
		_add_error("%s path must use res://: %s" % [label, path])
	elif not FileAccess.file_exists(path):
		_add_error("%s file missing: %s" % [label, path])


func _validate_required_action_sheet_keys(unit_action_sheets: Dictionary) -> void:
	for character_id in BattleContentScript.CHARACTER_LIBRARY.keys():
		if not unit_action_sheets.has(String(character_id)):
			_add_error("Missing player action sheet key: %s" % String(character_id))
	var required_enemy_roles: Array[String] = []
	for unit_id in BattleContentScript.UNIT_LIBRARY.keys():
		var unit: Dictionary = BattleContentScript.UNIT_LIBRARY[unit_id]
		if unit.get("team", "") != "enemy":
			continue
		var role := String(unit.get("role", ""))
		if role != "" and not required_enemy_roles.has(role):
			required_enemy_roles.append(role)
	for role in required_enemy_roles:
		if not unit_action_sheets.has(role):
			_add_error("Missing enemy action sheet key for role: %s" % role)


func _validate_unit_action_sheet_meta(data: Dictionary, unit_action_sheets: Dictionary) -> void:
	if not data.has("unit_action_sheet_meta"):
		_add_error("Art assets file missing section: unit_action_sheet_meta")
		return
	if typeof(data["unit_action_sheet_meta"]) != TYPE_DICTIONARY:
		_add_error("Art assets section must be an object: unit_action_sheet_meta")
		return
	var meta_map: Dictionary = data["unit_action_sheet_meta"]
	for key in unit_action_sheets.keys():
		var sheet_key := String(key)
		if not meta_map.has(sheet_key):
			_add_error("unit_action_sheet_meta missing key: %s" % sheet_key)
			continue
		var meta: Variant = meta_map[sheet_key]
		if typeof(meta) != TYPE_DICTIONARY:
			_add_error("unit_action_sheet_meta.%s must be an object." % sheet_key)
			continue
		var frame_size: Variant = meta.get("frame_size", [])
		if not (frame_size is Array and frame_size.size() >= 2 and int(frame_size[0]) > 0 and int(frame_size[1]) > 0):
			_add_error("unit_action_sheet_meta.%s.frame_size must be [w, h]." % sheet_key)
		var pivot: Variant = meta.get("pivot", [])
		if not (pivot is Array and pivot.size() >= 2):
			_add_error("unit_action_sheet_meta.%s.pivot must be [x, y]." % sheet_key)
		var mirror_mode := String(meta.get("mirror_mode", ""))
		if not KNOWN_MIRROR_MODES.has(mirror_mode):
			_add_error("unit_action_sheet_meta.%s.mirror_mode is invalid: %s" % [sheet_key, mirror_mode])


func _class_tags_for_character(character_id: String) -> Array:
	var character: Dictionary = BattleContentScript.CHARACTER_LIBRARY.get(character_id, {})
	var class_id: String = String(character.get("class_id", ""))
	var class_data: Dictionary = BattleContentScript.CLASS_LIBRARY.get(class_id, {})
	return class_data.get("tags", [])


func _tags_overlap(unit_tags: Array, executor_tags: Array) -> bool:
	if executor_tags.is_empty():
		return true
	for tag in unit_tags:
		if executor_tags.has(tag):
			return true
	return false


func _terrain_for_battle(battle: Dictionary, terrain_presets: Dictionary) -> Dictionary:
	var battle_id := String(battle.get("id", ""))
	if battle_id != "":
		var tilemap_terrain := content.battlefield_terrain(battle_id)
		if not tilemap_terrain.is_empty():
			var tilemap_result: Dictionary = {}
			for tile in tilemap_terrain.keys():
				var pos: Vector2i = tile
				tilemap_result["%d,%d" % [pos.x, pos.y]] = String(tilemap_terrain[tile])
			return tilemap_result
	var source: Dictionary = {}
	if battle.has("terrain_preset"):
		source = terrain_presets.get(String(battle.get("terrain_preset", "")), {})
	var result: Dictionary = {}
	_apply_terrain_source(result, source)
	if battle.has("terrain"):
		_apply_terrain_source(result, battle.get("terrain", {}))
	return result


func _apply_terrain_source(result: Dictionary, source: Dictionary) -> void:
	for terrain_kind in source.keys():
		for raw_pos in source[terrain_kind]:
			var pos: Vector2i = _array_to_vector2i(raw_pos)
			result["%d,%d" % [pos.x, pos.y]] = String(terrain_kind)


func _array_to_vector2i(value: Variant) -> Vector2i:
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i(-999, -999)


func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < GRID_W and pos.y < GRID_H


func _add_error(message: String) -> void:
	errors.append(message)


func _add_warning(message: String) -> void:
	warnings.append(message)


func _print_result() -> void:
	for warning in warnings:
		print("[warn] %s" % warning)
	for error in errors:
		push_error(error)
		print("ERROR: %s" % error)
	if errors.is_empty():
		print("Project data validation passed. Warnings: %d" % warnings.size())
	else:
		print("Project data validation failed. Errors: %d Warnings: %d" % [errors.size(), warnings.size()])
