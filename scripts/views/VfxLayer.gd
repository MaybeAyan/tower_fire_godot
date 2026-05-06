class_name VfxLayer
extends Control

const BattleLayoutScript := preload("res://scripts/core/BattleLayout.gd")

@export_range(0.0, 1.0, 0.01) var tile_anchor_ratio := 0.74
@export var hit_offset := Vector2.ZERO
@export var slash_offset := Vector2.ZERO
@export var magic_offset := Vector2.ZERO
@export var heal_offset := Vector2.ZERO
@export var guard_offset := Vector2.ZERO
@export var death_offset := Vector2.ZERO
@export var text_offset := Vector2(0, -42)
@export var hit_size := 112.0
@export var slash_size := 124.0
@export var magic_size := 132.0
@export var heal_size := 104.0
@export var guard_size := 112.0
@export var death_size := 118.0

@onready var hit_anchor_marker: Node2D = $AnchorOffsets/HitBottom
@onready var heal_anchor_marker: Node2D = $AnchorOffsets/HealBottom
@onready var guard_anchor_marker: Node2D = $AnchorOffsets/GuardBottom

var state: BattleState
var assets: BattleAssets
var layout = BattleLayoutScript.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if state == null or assets == null:
		return
	for effect in state.effects:
		var progress := _effect_active_progress(effect)
		if progress < 0.0:
			continue
		var anchor: Vector2 = _effect_anchor(effect)
		_draw_vfx_sheet(effect, anchor, progress)
		_draw_effect_text(effect, anchor, progress)
	for visual_event in state.visual_events:
		if visual_event.get("kind", "") != "death":
			continue
		var event_progress := _effect_active_progress(visual_event)
		if event_progress < 0.0:
			continue
		var event_anchor: Vector2 = _effect_anchor(visual_event)
		_draw_vfx_sheet(visual_event, event_anchor, event_progress)
		_draw_effect_text(visual_event, event_anchor, event_progress)


func _effect_active_progress(effect: Dictionary) -> float:
	var delay: float = float(effect.get("start_delay", 0.0))
	var age: float = float(effect.get("age", 0.0))
	if age < delay:
		return -1.0
	var active_duration: float = float(effect.get("active_duration", effect.get("duration", 1.0)))
	if active_duration <= 0.0:
		return 1.0
	return clampf((age - delay) / active_duration, 0.0, 1.0)


func _effect_anchor(effect: Dictionary) -> Vector2:
	if effect.has("tile"):
		var tile: Vector2i = effect["tile"]
		var rect := state.tile_rect(tile, layout.board_rect)
		var kind: String = effect["kind"]
		return Vector2(rect.get_center().x, rect.position.y + rect.size.y * tile_anchor_ratio) + _marker_offset(kind)
	return effect.get("pos", Vector2.ZERO)


func _draw_effect_text(effect: Dictionary, anchor: Vector2, progress: float) -> void:
	var label: String = effect.get("text", effect.get("message", ""))
	if label == "":
		return
	var color: Color = effect.get("color", Color("#fff4ba"))
	color.a = 1.0 - progress
	var pos := anchor + text_offset + Vector2(0, -34.0 * progress)
	draw_string(get_theme_default_font(), pos + Vector2(-44, 0), label, HORIZONTAL_ALIGNMENT_CENTER, 88, 20, color)


func _draw_vfx_sheet(effect: Dictionary, anchor: Vector2, progress: float) -> void:
	var kind: String = effect.get("vfx_kind", effect["kind"])
	if kind == "select":
		return
	var texture: Texture2D = assets.vfx_textures.get(kind)
	if texture == null:
		return
	var frame_count := 8
	var frame := mini(frame_count - 1, floori(progress * float(frame_count)))
	var frame_w := float(texture.get_width()) / float(frame_count)
	var frame_h := float(texture.get_height())
	var src := Rect2(Vector2(frame_w * frame, 0.0), Vector2(frame_w, frame_h))
	var vfx_size := _vfx_size(kind)
	var offset := _vfx_offset(kind)
	var alpha := clampf(1.0 - maxf(0.0, progress - 0.82) / 0.18, 0.0, 1.0)
	var dest := Rect2(anchor + offset - Vector2(vfx_size * 0.5, vfx_size), Vector2(vfx_size, vfx_size))
	draw_texture_rect_region(texture, dest, src, Color(1.0, 1.0, 1.0, alpha))


func _marker_offset(kind: String) -> Vector2:
	match kind:
		"hit":
			return hit_anchor_marker.position if hit_anchor_marker != null else Vector2.ZERO
		"slash", "magic":
			return hit_anchor_marker.position if hit_anchor_marker != null else Vector2.ZERO
		"heal":
			return heal_anchor_marker.position if heal_anchor_marker != null else Vector2.ZERO
		"guard":
			return guard_anchor_marker.position if guard_anchor_marker != null else Vector2.ZERO
		"death":
			return hit_anchor_marker.position if hit_anchor_marker != null else Vector2.ZERO
	return Vector2.ZERO


func _vfx_size(kind: String) -> float:
	match kind:
		"hit":
			return hit_size
		"slash":
			return slash_size
		"magic":
			return magic_size
		"heal":
			return heal_size
		"guard":
			return guard_size
		"death":
			return death_size
	return 0.0


func _vfx_offset(kind: String) -> Vector2:
	match kind:
		"hit":
			return hit_offset
		"slash":
			return slash_offset
		"magic":
			return magic_offset
		"heal":
			return heal_offset
		"guard":
			return guard_offset
		"death":
			return death_offset
	return Vector2.ZERO
