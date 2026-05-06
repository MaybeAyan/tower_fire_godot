class_name BattleLayout
extends RefCounted

var viewport_size := Vector2.ZERO
var board_rect := Rect2()
var sidebar_rect := Rect2()
var hand_dock_rect := Rect2()
var tutorial_rect := Rect2()
var objective_rect := Rect2()
var modal_rect := Rect2()
var card_size := Vector2(170, 200)
var hand_gap := 14.0


func update(view_size: Vector2, hand_count: int) -> void:
	viewport_size = view_size
	var top_margin := clampf(view_size.y * 0.115, 78.0, 94.0)
	var dock_height := clampf(view_size.y * 0.15, 108.0, 124.0)
	var bottom_margin := clampf(view_size.y * 0.018, 12.0, 18.0)
	var side_margin := clampf(view_size.x * 0.016, 18.0, 28.0)
	var sidebar_width := clampf(view_size.x * 0.205, 278.0, 330.0)
	var gap := clampf(view_size.x * 0.012, 14.0, 20.0)
	var board_to_dock_gap := clampf(view_size.y * 0.026, 18.0, 28.0)
	var base_board_size := Vector2(800.0, 640.0)
	var max_board_width := maxf(360.0, view_size.x - side_margin * 2.0 - sidebar_width - gap)
	var max_board_height := maxf(280.0, view_size.y - top_margin - dock_height - bottom_margin - board_to_dock_gap)
	var scale := minf(1.0, minf(max_board_width / base_board_size.x, max_board_height / base_board_size.y))
	var board_size := base_board_size * scale
	var content_width := board_size.x + gap + sidebar_width
	var board_x := clampf((view_size.x - content_width) * 0.5, side_margin, maxf(side_margin, view_size.x - side_margin - content_width))
	var board_y := top_margin
	board_rect = Rect2(Vector2(board_x, board_y), board_size)

	var sidebar_x := minf(view_size.x - side_margin - sidebar_width, board_rect.end.x + gap)
	var sidebar_y := board_rect.position.y
	var sidebar_height := clampf(board_rect.size.y, 320.0, view_size.y - sidebar_y - dock_height - bottom_margin - board_to_dock_gap)

	sidebar_rect = Rect2(
		Vector2(sidebar_x, sidebar_y),
		Vector2(sidebar_width, sidebar_height)
	)

	var dock_y := board_rect.end.y + board_to_dock_gap
	hand_dock_rect = Rect2(
		Vector2(board_rect.position.x, dock_y),
		Vector2(board_rect.size.x, minf(dock_height, maxf(96.0, view_size.y - dock_y - bottom_margin)))
	)

	var tutorial_w := clampf(board_rect.size.x * 0.42, 300.0, 370.0)
	var tutorial_h := clampf(view_size.y * 0.052, 36.0, 42.0)
	tutorial_rect = Rect2(
		Vector2(board_rect.position.x, maxf(16.0, board_rect.position.y - tutorial_h - 10.0)),
		Vector2(tutorial_w, tutorial_h)
	)

	var objective_w := minf(390.0, maxf(240.0, sidebar_rect.position.x - tutorial_rect.end.x - gap))
	objective_rect = Rect2(
		Vector2(tutorial_rect.end.x + gap * 0.55, tutorial_rect.position.y),
		Vector2(objective_w, tutorial_h)
	)

	var modal_size := Vector2(minf(760.0, view_size.x - 120.0), minf(520.0, view_size.y - 100.0))
	modal_rect = Rect2(
		Vector2((view_size.x - modal_size.x) * 0.5, (view_size.y - modal_size.y) * 0.5),
		modal_size
	)

	hand_gap = clampf(view_size.x * 0.008, 10.0, 15.0)
	var max_total_width := hand_dock_rect.size.x - 120.0
	var max_card_width := (max_total_width - hand_gap * maxf(0.0, hand_count - 1.0)) / maxf(1.0, float(max(hand_count, 1)))
	var card_width := clampf(max_card_width, 168.0, 220.0)
	var card_height := clampf(card_width * 0.36, 58.0, 72.0)
	card_size = Vector2(card_width, card_height)
