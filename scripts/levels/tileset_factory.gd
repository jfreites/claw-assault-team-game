class_name TilesetFactory
extends RefCounted
## Construye el TileSet del juego en runtime a partir de assets/sprites/tiles/tileset.png
## (tira horizontal de tiles de 16x16, ver ASSETS.md). Cambiar el PNG cambia el arte.

enum Tile { GROUND_TOP, GROUND_FILL, PLATFORM, WATER_TOP, WATER_FILL, SAND_TOP, SAND_FILL }

const TILE_SIZE := 16
const TEXTURE_PATH := "res://assets/sprites/tiles/tileset.png"
const SOURCE_ID := 0
const PLATFORM_THICKNESS := 4.0

const Loader := preload("res://scripts/autoload/sprite_loader.gd")


static func build() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	# Capa física 0 = sólido (world), 1 = plataformas one-way
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, Layers.WORLD)
	ts.set_physics_layer_collision_mask(0, 0)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(1, Layers.ONE_WAY)
	ts.set_physics_layer_collision_mask(1, 0)

	var source := TileSetAtlasSource.new()
	source.texture = Loader.load_texture(TEXTURE_PATH)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	ts.add_source(source, SOURCE_ID)
	# Si el PNG trae menos tiles (arte viejo) solo se crean los que existen
	var available := Tile.size()
	if source.texture:
		available = mini(available, source.texture.get_width() / TILE_SIZE)
	for tile in available:
		source.create_tile(Vector2i(tile, 0))

	var h := TILE_SIZE * 0.5
	var full := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	for tile in [Tile.GROUND_TOP, Tile.GROUND_FILL, Tile.SAND_TOP, Tile.SAND_FILL]:
		if not source.has_tile(Vector2i(tile, 0)):
			continue
		var data := source.get_tile_data(Vector2i(tile, 0), 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, full)

	var top := -h + PLATFORM_THICKNESS
	var thin := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, top), Vector2(-h, top)])
	var platform := source.get_tile_data(Vector2i(Tile.PLATFORM, 0), 0)
	platform.add_collision_polygon(1)
	platform.set_collision_polygon_points(1, 0, thin)
	platform.set_collision_polygon_one_way(1, 0, true)
	return ts
