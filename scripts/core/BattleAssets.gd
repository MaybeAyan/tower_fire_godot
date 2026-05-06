class_name BattleAssets
extends RefCounted

const CARD_STRIKE := "strike"
const CARD_LANCE := "lance"
const CARD_DASH := "dash"
const CARD_GUARD := "guard"
const CARD_ENGAGE := "engage"
const CARD_HEAL := "heal"
const ART_ASSETS_PATH := "res://assets/data/art_assets.json"
const FALLBACK_BATTLEFIELD_PATH := "res://assets/art/battlefield-academy-courtyard.png"
const FALLBACK_TERRAIN_TILESET_PATH := "res://assets/art/tilesets/academy-courtyard-tiles.png"
const DEFAULT_FRAME_SIZE := Vector2(128, 128)
const DEFAULT_SHEET_PIVOT := Vector2(64, 118)

var battlefield_texture: Texture2D = null
var battlefield_textures: Dictionary = {}
var token_textures: Dictionary = {}
var portrait_textures: Dictionary = {}
var unit_action_sheets: Dictionary = {}
var unit_action_sheet_meta: Dictionary = {}
var card_textures: Dictionary = {}
var ui_textures: Dictionary = {}
var vfx_textures: Dictionary = {}
var atmosphere_textures: Dictionary = {}
var dialogue_background_textures: Dictionary = {}
var terrain_tileset_texture: Texture2D = null
var terrain_tile_regions: Dictionary = {}
var terrain_tile_size := Vector2(64, 64)


func load_all() -> void:
	var art_assets := _load_art_asset_data()
	battlefield_texture = _load_image_texture(_configured_path(art_assets, "battlefield", FALLBACK_BATTLEFIELD_PATH))
	battlefield_textures.clear()
	terrain_tileset_texture = _load_optional_image_texture(_configured_path(art_assets, "terrain_tileset", FALLBACK_TERRAIN_TILESET_PATH))
	terrain_tile_size = _configured_vector2(art_assets, "terrain_tile_size", Vector2(64, 64))
	terrain_tile_regions = _configured_rects(art_assets, "terrain_tile_regions")
	if terrain_tile_regions.is_empty():
		terrain_tile_regions = _fallback_terrain_regions()
	token_textures = _load_texture_map(_fallback_token_paths(), _configured_paths(art_assets, "tokens"), false)
	portrait_textures = _load_texture_map(_fallback_portrait_paths(), _configured_paths(art_assets, "portraits"), false)
	unit_action_sheets = _load_texture_map(_fallback_unit_action_sheet_paths(), _configured_paths(art_assets, "unit_action_sheets"), true)
	unit_action_sheet_meta = _configured_unit_action_sheet_meta(art_assets)
	card_textures = _load_texture_map(_fallback_card_paths(), _configured_paths(art_assets, "cards"), false)
	ui_textures = _load_texture_map(_fallback_ui_paths(), _configured_paths(art_assets, "ui"), false)
	vfx_textures = _load_texture_map(_fallback_vfx_paths(), _configured_paths(art_assets, "vfx"), false)
	atmosphere_textures = _load_texture_map(_fallback_atmosphere_paths(), _configured_paths(art_assets, "atmosphere"), true)
	dialogue_background_textures = _load_texture_map({}, _configured_paths(art_assets, "dialogue_backgrounds"), false)


func battlefield_texture_for(path: String) -> Texture2D:
	if path == "":
		return battlefield_texture
	if battlefield_textures.has(path):
		return battlefield_textures[path] as Texture2D
	var texture := _load_optional_image_texture(path)
	if texture == null:
		texture = battlefield_texture
	battlefield_textures[path] = texture
	return texture


func _fallback_terrain_regions() -> Dictionary:
	return {
		"floor": Rect2(0, 0, 64, 64),
		"wall": Rect2(64, 0, 64, 64),
		"pillar": Rect2(128, 0, 64, 64),
		"gate": Rect2(192, 0, 64, 64),
		"high": Rect2(0, 64, 64, 64),
		"holy": Rect2(64, 64, 64, 64),
		"fire": Rect2(128, 64, 64, 64),
		"marker": Rect2(192, 64, 64, 64),
	}


func _load_image_texture(res_path: String) -> Texture2D:
	var image := Image.new()
	var err := image.load(ProjectSettings.globalize_path(res_path))
	if err != OK:
		push_warning("Could not load art asset: %s" % res_path)
		return null
	return ImageTexture.create_from_image(image)


func _load_optional_image_texture(res_path: String) -> Texture2D:
	if not FileAccess.file_exists(res_path):
		return null
	return _load_image_texture(res_path)


func _load_art_asset_data() -> Dictionary:
	if not FileAccess.file_exists(ART_ASSETS_PATH):
		return {}
	var text := FileAccess.get_file_as_string(ART_ASSETS_PATH)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Art assets file is not a JSON object: %s" % ART_ASSETS_PATH)
		return {}
	return parsed


func _configured_path(art_assets: Dictionary, key: String, fallback_path: String) -> String:
	var value: Variant = art_assets.get(key, fallback_path)
	if typeof(value) != TYPE_STRING:
		push_warning("Art asset path %s must be a string. Using fallback." % key)
		return fallback_path
	return String(value)


func _configured_paths(art_assets: Dictionary, section: String) -> Dictionary:
	var value: Variant = art_assets.get(section, {})
	if typeof(value) != TYPE_DICTIONARY:
		push_warning("Art asset section %s must be a dictionary. Using fallbacks." % section)
		return {}
	return value


func _configured_vector2(art_assets: Dictionary, key: String, fallback: Vector2) -> Vector2:
	var value: Variant = art_assets.get(key, [])
	if typeof(value) == TYPE_ARRAY and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback


func _configured_rects(art_assets: Dictionary, section: String) -> Dictionary:
	var configured := _configured_paths(art_assets, section)
	var rects := {}
	for key in configured:
		var value: Variant = configured[key]
		if typeof(value) == TYPE_ARRAY and value.size() >= 4:
			rects[key] = Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
	return rects


func _load_texture_map(fallback_paths: Dictionary, configured_paths: Dictionary, optional: bool) -> Dictionary:
	var paths := fallback_paths.duplicate(true)
	for key in configured_paths:
		paths[key] = configured_paths[key]
	var textures := {}
	for key in paths:
		var path := String(paths[key])
		textures[key] = _load_optional_image_texture(path) if optional else _load_image_texture(path)
	return textures


func unit_action_sheet_meta_for(key: String) -> Dictionary:
	if unit_action_sheet_meta.has(key):
		return unit_action_sheet_meta[key]
	return _make_unit_action_sheet_meta("fixed")


func dialogue_background_texture(bg_id: String) -> Texture2D:
	return dialogue_background_textures.get(bg_id, null) as Texture2D


func atmosphere_texture(key: String) -> Texture2D:
	return atmosphere_textures.get(key, null) as Texture2D


func _configured_unit_action_sheet_meta(art_assets: Dictionary) -> Dictionary:
	var metas := _default_unit_action_sheet_meta_map()
	var configured: Variant = art_assets.get("unit_action_sheet_meta", {})
	if typeof(configured) != TYPE_DICTIONARY:
		return metas
	for key in configured:
		var value: Variant = configured[key]
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var meta: Dictionary = metas.get(String(key), _make_unit_action_sheet_meta("fixed"))
		var frame_size: Variant = value.get("frame_size", [])
		if typeof(frame_size) == TYPE_ARRAY and frame_size.size() >= 2:
			meta["frame_size"] = Vector2(float(frame_size[0]), float(frame_size[1]))
		var pivot: Variant = value.get("pivot", [])
		if typeof(pivot) == TYPE_ARRAY and pivot.size() >= 2:
			meta["pivot"] = Vector2(float(pivot[0]), float(pivot[1]))
		var mirror_mode := String(value.get("mirror_mode", meta.get("mirror_mode", "fixed")))
		if mirror_mode in ["player", "enemy", "fixed"]:
			meta["mirror_mode"] = mirror_mode
		var base_facing := String(value.get("base_facing", meta.get("base_facing", "left")))
		if base_facing in ["left", "right"]:
			meta["base_facing"] = base_facing
		metas[String(key)] = meta
	return metas


func _default_unit_action_sheet_meta_map() -> Dictionary:
	return {
		"astra": _make_unit_action_sheet_meta("enemy", DEFAULT_SHEET_PIVOT, "left"),
		"evelyn": _make_unit_action_sheet_meta("enemy", DEFAULT_SHEET_PIVOT, "left"),
		"liora": _make_unit_action_sheet_meta("enemy", DEFAULT_SHEET_PIVOT, "left"),
		"kael": _make_unit_action_sheet_meta("enemy", DEFAULT_SHEET_PIVOT, "left"),
		"sword": _make_unit_action_sheet_meta("player", DEFAULT_SHEET_PIVOT, "left"),
		"mage": _make_unit_action_sheet_meta("player", DEFAULT_SHEET_PIVOT, "left"),
		"guard": _make_unit_action_sheet_meta("player", DEFAULT_SHEET_PIVOT, "left"),
		"enemy_boss": _make_unit_action_sheet_meta("player", DEFAULT_SHEET_PIVOT, "left"),
	}


func _make_unit_action_sheet_meta(mirror_mode: String, pivot: Vector2 = DEFAULT_SHEET_PIVOT, base_facing: String = "left") -> Dictionary:
	return {
		"frame_size": DEFAULT_FRAME_SIZE,
		"pivot": pivot,
		"mirror_mode": mirror_mode,
		"base_facing": base_facing,
	}


func _fallback_token_paths() -> Dictionary:
	return {
		"hero": "res://assets/art/tokens/astra-hero.png",
		"faith": "res://assets/art/tokens/liora-saint.png",
		"sword": "res://assets/art/tokens/blade-acolyte.png",
		"mage": "res://assets/art/tokens/rune-flare.png",
		"guard": "res://assets/art/tokens/shield-vow.png",
	}


func _fallback_portrait_paths() -> Dictionary:
	return {
		"astra": "res://assets/art/portraits/astra.png",
		"liora": "res://assets/art/portraits/liora.png",
		"kael": "res://assets/art/portraits/kael.png",
	}


func _fallback_card_paths() -> Dictionary:
	return {
		CARD_STRIKE: "res://assets/art/cards/quick-slash.png",
		CARD_LANCE: "res://assets/art/cards/radiant-lance.png",
		CARD_DASH: "res://assets/art/cards/step-command.png",
		CARD_GUARD: "res://assets/art/cards/guard-bloom.png",
		CARD_ENGAGE: "res://assets/art/cards/engage-crest.png",
		CARD_HEAL: "res://assets/art/cards/mend-light.png",
	}


func _fallback_ui_paths() -> Dictionary:
	return {
		"status_panel": "res://assets/art/ui/status-panel-frame.png",
		"hand_dock": "res://assets/art/ui/hand-dock-frame.png",
		"glass_status_panel": "res://assets/art/ui/glass_tactics/glass-status-panel-frame.png",
		"glass_status_panel_rich": "res://assets/art/ui/glass_tactics/glass-status-panel.png",
		"glass_hand_dock": "res://assets/art/ui/glass_tactics/glass-hand-dock-frame.png",
		"glass_skill_strip": "res://assets/art/ui/glass_tactics/glass-skill-strip.png",
		"glass_prompt_pill": "res://assets/art/ui/glass_tactics/glass-prompt-pill.png",
		"glass_hp_bar": "res://assets/art/ui/glass_tactics/glass-hp-bar.png",
		"oil_status_panel": "res://assets/art/ui/japanese_oil_hud/oil-status-panel-frame.png",
		"oil_hand_dock": "res://assets/art/ui/japanese_oil_hud/oil-hand-dock-frame.png",
		"oil_skill_strip": "res://assets/art/ui/japanese_oil_hud/oil-skill-strip.png",
		"oil_prompt_pill": "res://assets/art/ui/japanese_oil_hud/oil-prompt-pill.png",
		"oil_hp_bar": "res://assets/art/ui/japanese_oil_hud/oil-hp-bar.png",
		"oil_safe_corner": "res://assets/art/ui/japanese_oil_safe/oil-safe-corner.png",
		"oil_safe_edge_h": "res://assets/art/ui/japanese_oil_safe/oil-safe-edge-h.png",
		"oil_safe_edge_v": "res://assets/art/ui/japanese_oil_safe/oil-safe-edge-v.png",
		"oil_safe_button_glow": "res://assets/art/ui/japanese_oil_safe/oil-safe-button-glow.png",
		"oil_safe_crest": "res://assets/art/ui/japanese_oil_safe/oil-safe-crest.png",
		"iso_status_panel": "res://assets/art/ui/isometric_tactics/iso-status-panel.png",
		"iso_skill_dock": "res://assets/art/ui/isometric_tactics/iso-skill-dock.png",
		"skill_card_frame": "res://assets/art/ui/isometric_tactics/iso-skill-card-frame.png",
		"objective_pill": "res://assets/art/ui/isometric_tactics/iso-objective-pill.png",
		"small_button": "res://assets/art/ui/isometric_tactics/iso-small-button.png",
		"sidebar_inner": "res://assets/art/ui/sidebar-inner-frame.png",
		"reward_panel": "res://assets/art/ui/reward-panel-frame.png",
		"range_floor": "res://assets/art/ui/pixel-range-floor.png",
		"range_move": "res://assets/art/ui/glass_tactics/glass-range-move.png",
		"range_attack": "res://assets/art/ui/glass_tactics/glass-range-attack.png",
		"range_danger": "res://assets/art/ui/glass_tactics/glass-range-danger.png",
		"range_selected": "res://assets/art/ui/glass_tactics/glass-range-selected.png",
		"selected_ring": "res://assets/art/ui/glass_tactics/glass-selected-ring.png",
		"dialogue_frame": "res://assets/art/ui/fe-dialogue-frame.png",
		"dialogue_nameplate": "res://assets/art/ui/fe-dialogue-nameplate.png",
		"hp_bar": "res://assets/art/ui/fe-hp-bar.png",
		"exp_bar": "res://assets/art/ui/fe-exp-bar.png",
		"level_badge": "res://assets/art/ui/pixel-level-badge.png",
		"exp_gem": "res://assets/art/ui/pixel-exp-gem.png",
	}


func _fallback_vfx_paths() -> Dictionary:
	return {
		"hit": "res://assets/art/vfx/fire-slash-sheet.png",
		"slash": "res://assets/art/vfx/sword-slash-sheet.png",
		"magic": "res://assets/art/vfx/arcane-burst-sheet.png",
		"heal": "res://assets/art/vfx/heal-sigil-sheet.png",
		"guard": "res://assets/art/vfx/guard-shield-sheet.png",
		"death": "res://assets/art/vfx/defeat-dissolve-sheet.png",
	}


func _fallback_atmosphere_paths() -> Dictionary:
	return {
		"sacred_crest": "res://assets/art/atmosphere/sacred-crest-gold-v1.png",
		"rune_fire": "res://assets/art/atmosphere/rune-fire-crack-v1.png",
		"lantern_glow": "res://assets/art/atmosphere/lantern-glow-v1.png",
		"torn_banner": "res://assets/art/atmosphere/torn-blue-banner-v1.png",
	}


func _fallback_unit_action_sheet_paths() -> Dictionary:
	return {
		"astra": "res://assets/art/unit_sheets/astra-actions.png",
		"liora": "res://assets/art/unit_sheets/liora-actions.png",
		"kael": "res://assets/art/unit_sheets/kael-actions.png",
		"sword": "res://assets/art/unit_sheets/enemy-sword-actions.png",
		"mage": "res://assets/art/unit_sheets/enemy-mage-actions.png",
		"guard": "res://assets/art/unit_sheets/enemy-guard-actions.png",
		"enemy_boss": "res://assets/art/unit_sheets/enemy-boss-actions.png",
	}
