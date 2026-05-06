extends SceneTree


func _init() -> void:
	var texture := load("res://assets/art/tilesets/forest-tactical-tiles-v2-8x6.png") as Texture2D
	if texture == null:
		push_error("Could not load forest tactical tiles texture.")
		quit(1)
		return

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(64, 64)

	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(64, 64)
	for y in range(6):
		for x in range(8):
			source.create_tile(Vector2i(x, y))
	tile_set.add_source(source, 0)

	var err := ResourceSaver.save(tile_set, "res://assets/tile_sets/forest_tactical_tileset.tres")
	if err != OK:
		push_error("Could not save forest tactical TileSet: %s" % error_string(err))
		quit(1)
		return
	print("Created res://assets/tile_sets/forest_tactical_tileset.tres")
	quit()
