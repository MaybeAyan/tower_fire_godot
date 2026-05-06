class_name MountedUiLayer
extends Control

const BattleLayoutScript := preload("res://scripts/core/BattleLayout.gd")

@onready var board_backdrop: ColorRect = $BoardBackdrop
@onready var sidebar_panel_mount: TextureRect = $SidebarPanelMount
@onready var command_dock_mount: TextureRect = $CommandDockMount
@onready var dialogue_frame_mount: TextureRect = $DialogueFrameMount

var state: BattleState
var assets: BattleAssets
var layout = BattleLayoutScript.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for texture_rect in [sidebar_panel_mount, command_dock_mount, dialogue_frame_mount]:
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	board_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE


func sync() -> void:
	if state == null or assets == null or layout == null:
		return
	_update_rect(board_backdrop, layout.board_rect.grow(18.0))
	board_backdrop.color = Color("#030814", 0.36)
	board_backdrop.visible = false
	_place_texture(sidebar_panel_mount, layout.sidebar_rect, null)
	_place_texture(command_dock_mount, layout.hand_dock_rect, null)
	_place_texture(dialogue_frame_mount, Rect2(), null)
	sidebar_panel_mount.visible = false
	command_dock_mount.visible = false
	dialogue_frame_mount.visible = false


func _place_texture(node: TextureRect, rect: Rect2, texture: Texture2D) -> void:
	_update_rect(node, rect)
	node.texture = texture


func _update_rect(node: Control, rect: Rect2) -> void:
	node.position = rect.position
	node.size = rect.size
