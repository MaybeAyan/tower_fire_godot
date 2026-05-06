@tool
class_name TerrainTileMapLayer
extends TileMapLayer

const BattleLayoutScript := preload("res://scripts/core/BattleLayout.gd")
const BattleProjectionScript := preload("res://scripts/core/BattleProjection.gd")
const DEFAULT_TILE_SET := preload("res://assets/tile_sets/forest_tactical_tileset.tres")
const SOURCE_ID := 0
const SOURCE_TILE_SIZE := 64.0
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
const TERRAIN_ATLAS := {
	"floor": Vector2i(0, 0),
	"wall": Vector2i(1, 0),
	"pillar": Vector2i(2, 0),
	"gate": Vector2i(3, 0),
	"high": Vector2i(0, 1),
	"holy": Vector2i(1, 1),
	"fire": Vector2i(2, 1),
	"marker": Vector2i(3, 1),
}

var state: BattleState
var layout = BattleLayoutScript.new()
var loaded_scene_revision := -1
var loaded_scene_path := ""


func _ready() -> void:
	if tile_set == null:
		tile_set = DEFAULT_TILE_SET
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	y_sort_enabled = false
	visible = false


func sync() -> void:
	if state == null or layout == null:
		visible = false
		return
	visible = state.chapter_phase == "battle"
	if not visible:
		return
	var scene_path := state.current_tilemap_scene_path()
	if loaded_scene_revision != state.battle_map_revision or loaded_scene_path != scene_path:
		_sync_from_current_scene()
		loaded_scene_revision = state.battle_map_revision
		loaded_scene_path = scene_path
	_fit_to_board_rect()


func _fit_to_board_rect() -> void:
	var used := get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return
	var target: Rect2 = layout.board_rect
	var grid_rect := BattleProjectionScript.board_grid_rect(target, BattleState.GRID_W, BattleState.GRID_H)
	var source_size := Vector2(used.size) * SOURCE_TILE_SIZE
	var scale_value: float = minf(grid_rect.size.x / source_size.x, grid_rect.size.y / source_size.y)
	scale = Vector2(scale_value, scale_value)
	position = grid_rect.position - Vector2(used.position) * SOURCE_TILE_SIZE * scale_value


func _sync_from_current_scene() -> void:
	if state == null:
		return
	var scene_path := state.current_tilemap_scene_path()
	if scene_path != "" and _load_tilemap_scene(scene_path):
		return
	_sync_from_state_terrain()


func _sync_from_state_terrain() -> void:
	clear()
	for y in range(BattleState.GRID_H):
		for x in range(BattleState.GRID_W):
			var tile := Vector2i(x, y)
			var kind := state.terrain_kind(tile)
			var atlas: Vector2i = TERRAIN_ATLAS.get(kind, TERRAIN_ATLAS["floor"])
			set_cell(tile, SOURCE_ID, atlas, 0)


func _terrain_from_tilemap() -> Dictionary:
	var terrain_map: Dictionary = {}
	for used_cell in get_used_cells():
		var cell: Vector2i = used_cell
		if cell.x < 0 or cell.y < 0 or cell.x >= BattleState.GRID_W or cell.y >= BattleState.GRID_H:
			continue
		var atlas := get_cell_atlas_coords(cell)
		var kind := String(TERRAIN_ATLAS.find_key(atlas))
		if kind == "":
			kind = "floor"
		terrain_map[cell] = kind
	return terrain_map


func _load_tilemap_scene(scene_path: String) -> bool:
	if not ResourceLoader.exists(scene_path):
		push_warning("TileMap scene does not exist: %s" % scene_path)
		return false
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_warning("TileMap scene is not a PackedScene: %s" % scene_path)
		return false
	var root := packed.instantiate()
	var source_layer := _find_tilemap_layer(root) as TileMapLayer
	if source_layer == null:
		root.queue_free()
		push_warning("TileMap scene has no TileMapLayer: %s" % scene_path)
		return false
	clear()
	var scene_terrain := {}
	for used_cell in source_layer.get_used_cells():
		var cell: Vector2i = used_cell
		set_cell(
			cell,
			source_layer.get_cell_source_id(cell),
			source_layer.get_cell_atlas_coords(cell),
			source_layer.get_cell_alternative_tile(cell)
		)
		if cell.x >= 0 and cell.y >= 0 and cell.x < BattleState.GRID_W and cell.y < BattleState.GRID_H:
			scene_terrain[cell] = String(TILEMAP_TERRAIN_BY_ATLAS.get(source_layer.get_cell_atlas_coords(cell), "floor"))
	if not scene_terrain.is_empty():
		state.terrain = scene_terrain.duplicate(true)
	root.queue_free()
	return true


func _find_tilemap_layer(node: Node) -> Node:
	if node is TileMapLayer:
		return node
	for child in node.get_children():
		var found := _find_tilemap_layer(child)
		if found != null:
			return found
	return null
