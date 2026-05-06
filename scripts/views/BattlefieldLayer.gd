class_name BattlefieldLayer
extends Control

const BattleLayoutScript := preload("res://scripts/core/BattleLayout.gd")
const BattleProjectionScript := preload("res://scripts/core/BattleProjection.gd")

var state: BattleState
var assets: BattleAssets
var layout = BattleLayoutScript.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if state == null or assets == null or layout == null:
		return
	var viewport_size := get_viewport_rect().size
	_draw_background(viewport_size)
	if state.chapter_phase == "battle":
		_draw_board_frame(layout.board_rect)


func _draw_background(viewport_size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#101a1f", 0.32))
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#d8ef9d", 0.035))
	draw_rect(Rect2(Vector2.ZERO, Vector2(viewport_size.x, 26)), Color("#030814", 0.08))
	draw_rect(Rect2(Vector2(0, viewport_size.y - 150), Vector2(viewport_size.x, 150)), Color("#030814", 0.22))
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#030814", 0.08), false, 14.0)


func _draw_board_frame(board_rect: Rect2) -> void:
	var points := BattleProjectionScript.board_diamond_points(board_rect, BattleState.GRID_W, BattleState.GRID_H)
	var shadow := PackedVector2Array()
	for point in points:
		shadow.append(point + Vector2(0, 4))
	draw_polygon(shadow, [Color("#030814", 0.18)])
	draw_polygon(points, [Color("#071126", 0.08)])
	_draw_polyline(points, Color("#071126", 0.52), 4.0, true)
	_draw_polyline(points, Color("#86b56a", 0.34), 2.0, true)
	_draw_polyline(points, Color("#d8ef9d", 0.24), 1.0, true)


func _draw_polyline(points: PackedVector2Array, color: Color, width: float, closed: bool = false) -> void:
	var count := points.size()
	if count < 2:
		return
	for i in range(count - 1):
		draw_line(points[i], points[i + 1], color, width)
	if closed:
		draw_line(points[count - 1], points[0], color, width)
