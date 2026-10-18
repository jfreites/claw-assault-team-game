class_name LevelInfo
extends Resource
## Ficha de un nivel (stage) de la isla: nombre, escena y carpeta de arte propia.

@export var id := "level_01"
## Número que se muestra ("NIVEL 1")
@export var number := 1
@export var title := "Playa de desembarco"
## Ruta de la escena (texto para evitar referencias circulares con la escena)
@export_file("*.tscn") var scene_path := ""
## Carpeta del arte propio del nivel (tileset, fondos, enemigos)
@export_dir var art_dir := "res://assets/sprites/levels/level_01"


func get_display_name() -> String:
	return "Nivel %d: %s" % [number, title]
