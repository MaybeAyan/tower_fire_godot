class_name SideCombatLayer
extends Control

const BattleLayoutScript := preload("res://scripts/core/BattleLayout.gd")

var state: BattleState
var assets: BattleAssets
var layout = BattleLayoutScript.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if state == null or assets == null:
		return
	var event := _active_attack_event()
	if event.is_empty():
		return
	var progress := clampf(float(event.get("age", 0.0)) / maxf(0.01, float(event.get("duration", 1.0))), 0.0, 1.0)
	var viewport_size := get_viewport_rect().size
	var intro := clampf(progress / 0.18, 0.0, 1.0)
	var outro := clampf((1.0 - progress) / 0.18, 0.0, 1.0)
	var alpha := minf(intro, outro)
	var panel := _combat_rect(viewport_size)
	_draw_cinema_backdrop(viewport_size, panel, alpha, progress)
	_draw_stage(panel, event, progress, alpha)


func _active_attack_event() -> Dictionary:
	for visual_event in state.visual_events:
		if visual_event.get("kind", "") != "attack":
			continue
		if not visual_event.has("attacker_name") or not visual_event.has("target_name"):
			continue
		return visual_event
	return {}


func _combat_rect(viewport_size: Vector2) -> Rect2:
	var width := minf(viewport_size.x - 140.0, 980.0)
	var height := minf(viewport_size.y * 0.58, 388.0)
	return Rect2(Vector2((viewport_size.x - width) * 0.5, 58.0), Vector2(width, height))


func _draw_cinema_backdrop(viewport_size: Vector2, panel: Rect2, alpha: float, progress: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#030814", 0.54 * alpha))
	var shutter := (1.0 - alpha) * panel.size.y * 0.22
	var draw_panel := Rect2(panel.position + Vector2(0, shutter), panel.size - Vector2(0, shutter * 2.0))
	draw_rect(draw_panel.grow(8.0), Color("#030814", 0.30 * alpha))
	var background := _combat_background_texture()
	if background != null:
		_draw_background_cover(background, draw_panel, Color(1.0, 1.0, 1.0, 0.78 * alpha))
	else:
		draw_rect(draw_panel, Color("#14110d", 0.92 * alpha))
	draw_rect(draw_panel, Color("#030814", 0.38 * alpha))
	draw_rect(Rect2(draw_panel.position, Vector2(draw_panel.size.x, draw_panel.size.y * 0.28)), Color("#030814", 0.20 * alpha))
	draw_rect(Rect2(draw_panel.position + Vector2(0, draw_panel.size.y * 0.68), Vector2(draw_panel.size.x, draw_panel.size.y * 0.32)), Color("#2c2115", 0.22 * alpha))
	_draw_floor_glaze(draw_panel, alpha)
	for i in range(6):
		var x := draw_panel.position.x + float(i + 1) * draw_panel.size.x / 7.0
		draw_line(Vector2(x, draw_panel.position.y + draw_panel.size.y * 0.62), Vector2(x - 34.0, draw_panel.end.y - 12.0), Color("#f0c66e", 0.08 * alpha), 1.4)
	var flash := sin(progress * PI)
	draw_rect(draw_panel, Color("#fff4ba", 0.07 * flash * alpha))
	draw_rect(draw_panel, Color("#030814", 0.24 * alpha), false, 8.0)
	draw_rect(draw_panel.grow(-3.0), Color("#f0c66e", 0.38 * alpha), false, 2.0)
	draw_line(draw_panel.position + Vector2(28.0, draw_panel.size.y * 0.66), draw_panel.end - Vector2(28.0, draw_panel.size.y * 0.18), Color("#fff4ba", 0.10 * alpha), 1.2)


func _combat_background_texture() -> Texture2D:
	if assets == null:
		return null
	if state != null:
		var path := state.current_battlefield_background_path()
		var texture := assets.battlefield_texture_for(path)
		if texture != null:
			return texture
	return assets.battlefield_texture


func _draw_background_cover(texture: Texture2D, rect: Rect2, color: Color) -> void:
	var texture_size := Vector2(float(texture.get_width()), float(texture.get_height()))
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var target_ratio := rect.size.x / maxf(1.0, rect.size.y)
	var source_ratio := texture_size.x / maxf(1.0, texture_size.y)
	var source := Rect2(Vector2.ZERO, texture_size)
	if source_ratio > target_ratio:
		source.size.x = texture_size.y * target_ratio
		source.position.x = (texture_size.x - source.size.x) * 0.5
	else:
		source.size.y = texture_size.x / target_ratio
		source.position.y = (texture_size.y - source.size.y) * 0.5
	draw_texture_rect_region(texture, rect, source, color)


func _draw_floor_glaze(rect: Rect2, alpha: float) -> void:
	var floor_rect := Rect2(rect.position + Vector2(rect.size.x * 0.08, rect.size.y * 0.58), Vector2(rect.size.x * 0.84, rect.size.y * 0.30))
	for i in range(5):
		var t := float(i) / 4.0
		var inset := Vector2(floor_rect.size.x * 0.08 * t, floor_rect.size.y * 0.20 * t)
		draw_rect(Rect2(floor_rect.position + inset, floor_rect.size - inset * 2.0), Color("#f0c66e", (0.055 - t * 0.008) * alpha), false, 2.0)


func _draw_stage(panel: Rect2, event: Dictionary, progress: float, alpha: float) -> void:
	var attacker_on_left := String(event.get("attacker_team", "")) == "player"
	var left_unit := _event_actor(event, true if attacker_on_left else false)
	var right_unit := _event_actor(event, false if attacker_on_left else true)
	var left_center := panel.position + Vector2(panel.size.x * 0.29, panel.size.y * 0.70)
	var right_center := panel.position + Vector2(panel.size.x * 0.71, panel.size.y * 0.70)
	var impact := sin(progress * PI)
	var lunge := sin(clampf((progress - 0.18) / 0.36, 0.0, 1.0) * PI) * 44.0
	if attacker_on_left:
		left_center.x += lunge
		right_center.x += impact * 10.0
	else:
		right_center.x -= lunge
		left_center.x -= impact * 10.0
	_draw_combatant(left_center, left_unit, _combatant_should_flip(left_unit, true), alpha)
	_draw_combatant(right_center, right_unit, _combatant_should_flip(right_unit, false), alpha)
	_draw_nameplate(panel, left_unit.get("name", ""), true, alpha)
	_draw_nameplate(panel, right_unit.get("name", ""), false, alpha)
	_draw_clash(panel, event, progress, alpha)


func _event_actor(event: Dictionary, attacker: bool) -> Dictionary:
	var prefix := "attacker" if attacker else "target"
	return {
		"name": String(event.get(prefix + "_name", "")),
		"team": String(event.get(prefix + "_team", "")),
		"role": String(event.get(prefix + "_role", "")),
		"unit_id": String(event.get(prefix + "_unit_id", "")),
		"character_id": String(event.get(prefix + "_character_id", "")),
		"unit_key": String(event.get(prefix + "_unit_key", "")),
	}


func _draw_combatant(center: Vector2, actor: Dictionary, flip_h: bool, alpha: float) -> void:
	var sheet_key := _sheet_key(actor)
	var sheet: Texture2D = assets.unit_action_sheets.get(sheet_key, null) as Texture2D
	var token: Texture2D = assets.token_textures.get(actor.get("unit_id", ""), null) as Texture2D
	draw_ellipse(center, 86.0, 18.0, Color("#030814", 0.28 * alpha))
	if sheet != null:
		var frame_w := float(sheet.get_width()) / 4.0
		var frame_h := float(sheet.get_height()) / 6.0
		var source := Rect2(Vector2(0, 0), Vector2(frame_w, frame_h))
		var dest_size := Vector2(220, 220)
		var dest := Rect2(center - Vector2(dest_size.x * 0.5, dest_size.y * 0.92), dest_size)
		_draw_sheet(sheet, dest, source, Color(1, 1, 1, alpha), flip_h)
	elif token != null:
		var dest := Rect2(center - Vector2(84, 142), Vector2(168, 168))
		draw_texture_rect(token, dest, false, Color(1, 1, 1, alpha))
	else:
		var color := Color("#79d8ff", alpha) if actor.get("team", "") == "player" else Color("#ff6685", alpha)
		draw_circle(center + Vector2(0, -70), 58, color)


func _draw_sheet(texture: Texture2D, dest: Rect2, source: Rect2, color: Color, flip_h: bool) -> void:
	if not flip_h:
		draw_texture_rect_region(texture, dest, source, color)
		return
	draw_set_transform(dest.position + Vector2(dest.size.x, 0), 0.0, Vector2(-1, 1))
	draw_texture_rect_region(texture, Rect2(Vector2.ZERO, dest.size), source, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_nameplate(panel: Rect2, actor_name: String, left: bool, alpha: float) -> void:
	var plate_size := Vector2(250, 42)
	var pos := panel.position + Vector2(30, 24)
	if not left:
		pos.x = panel.end.x - plate_size.x - 30.0
	var rect := Rect2(pos, plate_size)
	draw_rect(rect, Color("#14100b", 0.86 * alpha))
	draw_rect(rect.grow(-3), Color("#d8c790", 0.30 * alpha))
	draw_rect(rect, Color("#f0c66e", 0.62 * alpha), false, 2.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(0, 28), actor_name, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 20, Color("#fff4ba", alpha))


func _draw_clash(panel: Rect2, event: Dictionary, progress: float, alpha: float) -> void:
	var center := panel.get_center() + Vector2(0, panel.size.y * 0.04)
	var impact := sin(progress * PI)
	var warm := Color("#fff4ba", alpha * (0.18 + impact * 0.46))
	var ember := Color("#f0c66e", alpha * impact * 0.52)
	draw_circle(center, 24.0 + impact * 18.0, Color("#fff4ba", 0.10 * impact * alpha))
	draw_arc(center, 34.0 + impact * 42.0, -PI * 0.12, PI * 1.12, 46, warm, 3.0)
	draw_arc(center, 18.0 + impact * 28.0, PI * 0.20, PI * 1.32, 36, Color("#ffcf8a", 0.24 * impact * alpha), 2.0)
	for i in range(4):
		var t := float(i) / 3.0
		var offset := Vector2(lerpf(-44.0, 34.0, t), lerpf(20.0, -24.0, t))
		var len := 26.0 - t * 8.0
		draw_line(center + offset - Vector2(len, -len * 0.38), center + offset + Vector2(len, -len * 0.38), Color(ember, ember.a * (1.0 - t * 0.18)), 2.2)
	var amount := int(event.get("amount", 0))
	if amount > 0:
		draw_string(get_theme_default_font(), center + Vector2(-50, -52), "%d" % amount, HORIZONTAL_ALIGNMENT_CENTER, 100, 30, Color("#ffcfda", alpha))


func _combatant_should_flip(actor: Dictionary, on_left: bool) -> bool:
	var desired := "right" if on_left else "left"
	var base := _actor_base_facing(actor)
	return base != desired


func _actor_base_facing(actor: Dictionary) -> String:
	var sheet_key := _sheet_key(actor)
	var meta := assets.unit_action_sheet_meta_for(sheet_key) if assets != null else {}
	return String(meta.get("base_facing", "left"))


func _sheet_key(actor: Dictionary) -> String:
	var character_id := String(actor.get("character_id", ""))
	if character_id != "":
		return character_id
	var unit_key := String(actor.get("unit_key", ""))
	if unit_key != "" and assets.unit_action_sheets.has(unit_key):
		return unit_key
	var role := String(actor.get("role", ""))
	match role:
		"hero", "scout":
			return "astra"
		"faith":
			return "liora"
		"lance":
			return "kael"
	return role
