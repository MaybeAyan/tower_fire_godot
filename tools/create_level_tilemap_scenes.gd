extends SceneTree

const BattleContentScript := preload("res://scripts/core/BattleContent.gd")
const TILE_SET := preload("res://assets/tile_sets/forest_tactical_tileset.tres")
const MAP_DIR := "res://scenes/maps"
const GRID_W := 10
const GRID_H := 8
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


func _init() -> void:
	var err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MAP_DIR))
	if err != OK:
		push_error("Could not create map directory: %s" % error_string(err))
		quit(1)
		return

	var content = BattleContentScript.new()
	var battle_ids := _battle_ids()
	for battle_id in battle_ids:
		var terrain := content.battlefield_terrain(battle_id)
		var scene_path := "%s/%s_tilemap.tscn" % [MAP_DIR, battle_id]
		var save_err := _save_map_scene(scene_path, battle_id, terrain)
		if save_err != OK:
			push_error("Could not save %s: %s" % [scene_path, error_string(save_err)])
			quit(1)
			return
		print("Created %s" % scene_path)
	quit()


func _battle_ids() -> Array[String]:
	var ids: Array[String] = []
	var text := FileAccess.get_file_as_string(BattleContentScript.LEVEL_DATA_PATH)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return ids
	for battle in parsed.get("battles", []):
		var id := String(battle.get("id", ""))
		if id != "":
			ids.append(id)
	return ids


func _save_map_scene(scene_path: String, battle_id: String, terrain: Dictionary) -> Error:
	var root := Node2D.new()
	root.name = "%sMap" % battle_id
	var layer := TileMapLayer.new()
	layer.name = "Terrain"
	layer.tile_set = TILE_SET
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(layer)
	layer.owner = root
	for y in range(GRID_H):
		for x in range(GRID_W):
			var pos := Vector2i(x, y)
			var kind := String(terrain.get(pos, "floor"))
			layer.set_cell(pos, 0, TERRAIN_ATLAS.get(kind, TERRAIN_ATLAS["floor"]), 0)
	var packed := PackedScene.new()
	var pack_err := packed.pack(root)
	if pack_err != OK:
		root.free()
		return pack_err
	var save_err := ResourceSaver.save(packed, scene_path)
	root.free()
	return save_err
