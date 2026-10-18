class_name Level
extends Node2D
## Nivel construido desde un LevelLayout: tiles, spawns, zonas mortales,
## cámara, arena del jefe y flujo de vidas (reaparición en checkpoint / game over).

signal boss_arena_entered
signal boss_defeated

## Ficha del nivel (nombre y carpeta de arte); vacío = arte por defecto (campo de pruebas)
@export var info: LevelInfo
@export var layout: LevelLayout
@export var player_scene: PackedScene
@export var respawn_delay := 0.5
## El gato cae del cielo al empezar o reaparecer
@export var intro_drop := true
## Nombre de la música en assets/audio/music (vacío = sin música)
@export var music := ""
## Segundos entre que la cámara se bloquea y el jefe aparece
@export var boss_awaken_delay := 0.9
## Al vencer al jefe pasa al siguiente nivel / victoria (las pruebas lo desactivan)
@export var advance_on_boss_defeat := true

var player: Player
var level_size := Vector2.ZERO

var _player_start := Vector2(32, 160)
var _arena_x := -1.0
var _arena_reached := false

@onready var tiles: TileMapLayer = $Tiles
@onready var entities: Node2D = $Entities
@onready var camera: GameCamera = $Camera
@onready var hud: Hud = $HUD


func _enter_tree() -> void:
	# Antes del _ready de los hijos: así fondo, tiles y enemigos usan el arte de este nivel
	SpriteLoader.set_level_art_dir(info.art_dir if info else "")
	LevelManager.notify_level_loaded(scene_file_path)


func _ready() -> void:
	var fresh_start := not GameState.respawning
	tiles.tile_set = TilesetFactory.build()
	_build_from_layout()
	_setup_camera()
	_spawn_player()
	if _arena_x >= 0.0:
		_add_arena_trigger()
	if music != "":
		AudioManager.play_music(music)
	if info and fresh_start:
		hud.flash_message("NIVEL %d\n%s" % [info.number, info.title.to_upper()], 2.5)


func _build_from_layout() -> void:
	var ts := layout.tile_size
	var rows := layout.get_rows()
	level_size = Vector2(layout.get_width() * ts, rows.size() * ts)
	GameState.level_bottom_y = level_size.y

	for y in rows.size():
		var row: String = rows[y]
		var water_run_start := -1
		for x in row.length() + 1:
			var c := row[x] if x < row.length() else "."
			var cell := Vector2i(x, y)
			var feet := Vector2((x + 0.5) * ts, (y + 1) * ts)
			# Tramos de superficie de agua → un peligro por tramo
			var is_water_top := c == "~" and layout.char_at(x, y - 1) != "~"
			if is_water_top and water_run_start < 0:
				water_run_start = x
			elif not is_water_top and water_run_start >= 0:
				_add_hazard(Rect2(water_run_start * ts, y * ts + 6, (x - water_run_start) * ts, ts - 6))
				water_run_start = -1
			match c:
				"#":
					var top := layout.char_at(x, y - 1) != "#"
					_set_tile(cell, TilesetFactory.Tile.GROUND_TOP if top else TilesetFactory.Tile.GROUND_FILL)
				":":
					var sand_top := layout.char_at(x, y - 1) != ":"
					_set_tile(cell, TilesetFactory.Tile.SAND_TOP if sand_top else TilesetFactory.Tile.SAND_FILL)
				"=":
					_set_tile(cell, TilesetFactory.Tile.PLATFORM)
				"~":
					_set_tile(cell, TilesetFactory.Tile.WATER_TOP if is_water_top else TilesetFactory.Tile.WATER_FILL)
				"P":
					_player_start = feet
				"A":
					_arena_x = x * ts
				".", " ":
					pass
				_:
					_spawn_entity(c, feet)

	# Abismo: cualquier cosa que caiga bajo el nivel muere
	_add_hazard(Rect2(-64, level_size.y + 24, level_size.x + 128, 64))


func _set_tile(cell: Vector2i, tile: int) -> void:
	tiles.set_cell(cell, TilesetFactory.SOURCE_ID, Vector2i(tile, 0))


func _spawn_entity(c: String, feet: Vector2) -> void:
	var scene := layout.spawns.get(c) as PackedScene
	if scene == null:
		push_warning("Level: carácter '%s' sin escena en spawns" % c)
		return
	var node := scene.instantiate() as Node2D
	node.position = feet
	entities.add_child(node)


func _add_hazard(rect: Rect2) -> void:
	var hazard := Hitbox.new()
	hazard.name = "Hazard"
	hazard.instant_kill = true
	hazard.collision_layer = Layers.HAZARD
	hazard.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = rect.size
	shape.shape = rect_shape
	shape.position = rect.get_center()
	hazard.add_child(shape)
	add_child(hazard)


func _setup_camera() -> void:
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(level_size.x)
	camera.limit_bottom = int(level_size.y)
	# Vista horizontal: la cámara queda pegada al fondo del nivel
	camera.global_position = Vector2(0, level_size.y)


func _spawn_player() -> void:
	player = player_scene.instantiate() as Player
	player.position = GameState.checkpoint_position if GameState.has_checkpoint() else _player_start
	entities.add_child(player)
	player.died.connect(_on_player_died)
	if GameState.respawning:
		player.start_invulnerability()
		GameState.respawning = false
	camera.target = player
	camera.snap_to_target()
	if intro_drop:
		player.global_position.y = camera.get_view_rect().position.y - 24.0
		player.start_intro_drop()
	hud.bind_player(player)


## La arena ocupa una pantalla desde la columna 'A'; al entrar se bloquea la cámara
func _add_arena_trigger() -> void:
	var trigger := Area2D.new()
	trigger.name = "ArenaTrigger"
	trigger.collision_layer = 0
	trigger.collision_mask = Layers.PLAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(layout.tile_size, level_size.y)
	shape.shape = rect
	shape.position = Vector2(_arena_x + layout.tile_size * 1.5, level_size.y * 0.5)
	trigger.add_child(shape)
	trigger.body_entered.connect(_on_arena_trigger)
	add_child(trigger)


func _on_arena_trigger(body: Node2D) -> void:
	if _arena_reached or not body is Player:
		return
	_arena_reached = true
	camera.lock_at_x(_arena_x + camera.get_view_size().x * 0.5)
	boss_arena_entered.emit()
	var boss := get_tree().get_first_node_in_group("boss") as Boss
	if boss == null:
		return
	await get_tree().create_timer(boss_awaken_delay).timeout
	if not is_instance_valid(boss):
		return
	boss.health_changed.connect(hud.set_boss_health)
	boss.defeated.connect(_on_boss_defeated.bind(boss))
	hud.show_boss_bar(boss.data.display_name)
	AudioManager.play_music("boss")
	boss.awaken(Rect2(_arena_x, 0, camera.get_view_size().x, level_size.y))


func _on_boss_defeated(boss: Boss) -> void:
	boss_defeated.emit()
	if is_instance_valid(player) and player.is_alive():
		player.start_invulnerability(999.0)
	hud.hide_boss_bar()
	hud.flash_message("¡MISIÓN CUMPLIDA!", boss.data.victory_delay)
	AudioManager.stop_music()
	AudioManager.play_sfx("stage_clear")
	await get_tree().create_timer(boss.data.victory_delay).timeout
	if advance_on_boss_defeat:
		LevelManager.complete_current_level()


func is_in_boss_arena() -> bool:
	return _arena_reached


func _on_player_died() -> void:
	if GameState.lose_life():
		GameState.respawning = true
		await get_tree().create_timer(respawn_delay).timeout
		get_tree().reload_current_scene()
	else:
		await get_tree().create_timer(respawn_delay).timeout
		LevelManager.show_game_over()
