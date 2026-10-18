extends Node
## LevelManager (autoload): flujo de la partida entre título, niveles y victoria.
## La lista de niveles vive en resources/levels/level_list.tres.

const LEVEL_LIST_PATH := "res://resources/levels/level_list.tres"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const VICTORY_SCENE := "res://scenes/ui/victory_screen.tscn"
const GAME_OVER_SCENE := "res://scenes/ui/game_over_screen.tscn"

var level_list: LevelList
var current_index := 0


func _ready() -> void:
	level_list = load(LEVEL_LIST_PATH) as LevelList


## Empieza una partida nueva desde el nivel 1
func start_game() -> void:
	GameState.reset_run()
	go_to_level(0)


func go_to_level(index: int) -> void:
	var info := level_list.get_level(index)
	if info == null:
		push_error("LevelManager: no existe el nivel %d" % index)
		return
	current_index = index
	GameState.checkpoint_position = Vector2.INF
	GameState.respawning = false
	get_tree().change_scene_to_file(info.scene_path)


## Llamar al ganar un nivel: pasa al siguiente o muestra la victoria
func complete_current_level() -> void:
	if current_index + 1 < level_list.size():
		go_to_level(current_index + 1)
	else:
		get_tree().change_scene_to_file(VICTORY_SCENE)


## Reintenta el nivel actual desde el principio con las vidas completas
func retry_current_level() -> void:
	GameState.reset_run()
	go_to_level(current_index)


func show_game_over() -> void:
	get_tree().change_scene_to_file(GAME_OVER_SCENE)


func go_to_title() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)


func current_level() -> LevelInfo:
	return level_list.get_level(current_index)


## Sincroniza el índice cuando un nivel se abre directo desde el editor (F6)
func notify_level_loaded(scene_path: String) -> void:
	var index := level_list.index_of_scene(scene_path)
	if index >= 0:
		current_index = index
