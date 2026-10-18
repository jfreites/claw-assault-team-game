class_name LevelList
extends Resource
## Orden de los niveles de la campaña. Agregar un nivel = sumar su LevelInfo aquí.

@export var levels: Array[Resource] = []


func get_level(index: int) -> LevelInfo:
	return levels[index] as LevelInfo if index >= 0 and index < levels.size() else null


func size() -> int:
	return levels.size()


func index_of_scene(scene_path: String) -> int:
	for i in levels.size():
		if (levels[i] as LevelInfo).scene_path == scene_path:
			return i
	return -1
