class_name BattleProjection
extends RefCounted


static func tile_width(board_rect: Rect2, grid_w: int, grid_h: int) -> float:
	var gap := tile_gap(board_rect, grid_w, grid_h)
	return floor((board_rect.size.x - gap * maxf(0.0, float(grid_w - 1))) / maxf(1.0, float(grid_w)))


static func tile_height(board_rect: Rect2, grid_w: int, grid_h: int) -> float:
	var gap := tile_gap(board_rect, grid_w, grid_h)
	return floor((board_rect.size.y - gap * maxf(0.0, float(grid_h - 1))) / maxf(1.0, float(grid_h)))


static func tile_gap(board_rect: Rect2, grid_w: int, grid_h: int) -> float:
	return 0.0


static func tile_size(board_rect: Rect2, grid_w: int, grid_h: int) -> Vector2:
	var gap: float = tile_gap(board_rect, grid_w, grid_h)
	var w: float = floor((board_rect.size.x - gap * maxf(0.0, float(grid_w - 1))) / maxf(1.0, float(grid_w)))
	var h: float = floor((board_rect.size.y - gap * maxf(0.0, float(grid_h - 1))) / maxf(1.0, float(grid_h)))
	var side: float = floor(minf(w, h))
	return Vector2(side, side)


static func board_grid_rect(board_rect: Rect2, grid_w: int, grid_h: int) -> Rect2:
	var gap := tile_gap(board_rect, grid_w, grid_h)
	var size := tile_size(board_rect, grid_w, grid_h)
	var used_size := Vector2(
		size.x * float(grid_w) + gap * maxf(0.0, float(grid_w - 1)),
		size.y * float(grid_h) + gap * maxf(0.0, float(grid_h - 1))
	)
	return Rect2(board_rect.position + (board_rect.size - used_size) * 0.5, used_size)


static func tile_center(tile: Vector2i, board_rect: Rect2, grid_w: int, grid_h: int) -> Vector2:
	return tile_surface_rect(tile, board_rect, grid_w, grid_h).get_center()


static func tile_surface_rect(tile: Vector2i, board_rect: Rect2, grid_w: int, grid_h: int) -> Rect2:
	var gap := tile_gap(board_rect, grid_w, grid_h)
	var size := tile_size(board_rect, grid_w, grid_h)
	var grid_rect := board_grid_rect(board_rect, grid_w, grid_h)
	return Rect2(grid_rect.position + Vector2(float(tile.x), float(tile.y)) * (size + Vector2(gap, gap)), size)


static func tile_ui_rect(tile: Vector2i, board_rect: Rect2, grid_w: int, grid_h: int) -> Rect2:
	var surface := tile_surface_rect(tile, board_rect, grid_w, grid_h)
	return surface.grow(-maxf(2.0, surface.size.y * 0.04))


static func tile_visual_rect(tile: Vector2i, board_rect: Rect2, grid_w: int, grid_h: int, visual_height_ratio: float = 0.70) -> Rect2:
	var surface := tile_surface_rect(tile, board_rect, grid_w, grid_h)
	var visual_h := surface.size.y * clampf(visual_height_ratio, 0.70, 1.20)
	return Rect2(Vector2(surface.position.x, surface.position.y - (visual_h - surface.size.y) * 0.5), Vector2(surface.size.x, visual_h))


static func tile_unit_anchor(tile: Vector2i, board_rect: Rect2, grid_w: int, grid_h: int) -> Vector2:
	return tile_surface_rect(tile, board_rect, grid_w, grid_h).get_center()


static func tile_diamond_points(tile: Vector2i, board_rect: Rect2, grid_w: int, grid_h: int) -> PackedVector2Array:
	return diamond_points(tile_surface_rect(tile, board_rect, grid_w, grid_h))


static func diamond_points(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])


static func board_diamond_points(board_rect: Rect2, grid_w: int, grid_h: int) -> PackedVector2Array:
	return diamond_points(board_grid_rect(board_rect, grid_w, grid_h))


static func screen_to_tile(pos: Vector2, board_rect: Rect2, grid_w: int, grid_h: int) -> Vector2i:
	var gap := tile_gap(board_rect, grid_w, grid_h)
	var size := tile_size(board_rect, grid_w, grid_h)
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2i(-1, -1)
	var grid_rect := board_grid_rect(board_rect, grid_w, grid_h)
	if not grid_rect.has_point(pos):
		return Vector2i(-1, -1)
	var step := size + Vector2(gap, gap)
	var local := pos - grid_rect.position
	var tile := Vector2i(floori(local.x / step.x), floori(local.y / step.y))
	if tile.x < 0 or tile.y < 0 or tile.x >= grid_w or tile.y >= grid_h:
		return Vector2i(-1, -1)
	if not tile_surface_rect(tile, board_rect, grid_w, grid_h).has_point(pos):
		return Vector2i(-1, -1)
	return tile
