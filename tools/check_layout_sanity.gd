extends SceneTree

const BattleLayoutScript := preload("res://scripts/core/BattleLayout.gd")

var errors: Array[String] = []


func _init() -> void:
	_check_view(Vector2(1280, 720), 6)
	_check_view(Vector2(1600, 900), 6)
	_check_view(Vector2(1024, 640), 6)
	_print_result()
	quit(1 if not errors.is_empty() else 0)


func _check_view(view_size: Vector2, hand_count: int) -> void:
	var layout = BattleLayoutScript.new()
	layout.update(view_size, hand_count)
	_assert_positive("board", layout.board_rect)
	_assert_positive("sidebar", layout.sidebar_rect)
	_assert_positive("hand dock", layout.hand_dock_rect)
	_assert_positive("tutorial", layout.tutorial_rect)
	_assert_gap("board/sidebar", layout.board_rect, layout.sidebar_rect, 12.0, "horizontal")
	_assert_gap("board/dock", layout.board_rect, layout.hand_dock_rect, 18.0, "vertical")
	_assert_inside("board", layout.board_rect, view_size)
	_assert_inside("sidebar", layout.sidebar_rect, view_size)
	_assert_inside("hand dock", layout.hand_dock_rect, view_size)
	if layout.tutorial_rect.end.y > layout.board_rect.position.y:
		_add_error("Tutorial overlaps board at %s." % str(view_size))


func _assert_positive(label: String, rect: Rect2) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_add_error("%s rect is not positive: %s" % [label, str(rect)])


func _assert_gap(label: String, a: Rect2, b: Rect2, min_gap: float, axis: String) -> void:
	var gap := b.position.x - a.end.x if axis == "horizontal" else b.position.y - a.end.y
	if gap < min_gap:
		_add_error("%s gap %.1f is below %.1f." % [label, gap, min_gap])


func _assert_inside(label: String, rect: Rect2, view_size: Vector2) -> void:
	if rect.position.x < -0.1 or rect.position.y < -0.1 or rect.end.x > view_size.x + 0.1 or rect.end.y > view_size.y + 0.1:
		_add_error("%s rect is outside %s: %s" % [label, str(view_size), str(rect)])


func _add_error(message: String) -> void:
	errors.append(message)
	push_error(message)


func _print_result() -> void:
	if errors.is_empty():
		print("Layout sanity checks passed.")
	else:
		print("Layout sanity checks failed: %d issue(s)." % errors.size())
