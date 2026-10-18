class_name LevelLayout
extends Resource
## Nivel descrito como texto ASCII: cada carácter es una celda de `tile_size` px.
##   '#' suelo sólido      '=' plataforma one-way     '~' agua (mortal)
##   'P' inicio del jugador '.' o espacio = vacío
## Cualquier otro carácter se busca en `spawns` (carácter → escena) y se instancia
## con los pies en el borde inferior de la celda.

@export var tile_size := 16
@export var spawns: Dictionary = {}
@export_multiline var map := ""

var _rows: PackedStringArray


func get_rows() -> PackedStringArray:
	if _rows.is_empty():
		for line in map.split("\n"):
			_rows.append(line.trim_suffix("\r"))
		while _rows.size() > 0 and _rows[_rows.size() - 1].strip_edges().is_empty():
			_rows.remove_at(_rows.size() - 1)
	return _rows


func get_width() -> int:
	var w := 0
	for row in get_rows():
		w = maxi(w, row.length())
	return w


func get_height() -> int:
	return get_rows().size()


func char_at(x: int, y: int) -> String:
	var rows := get_rows()
	if y < 0 or y >= rows.size() or x < 0 or x >= rows[y].length():
		return "."
	return rows[y][x]
