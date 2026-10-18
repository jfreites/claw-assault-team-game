@tool
class_name MuzzleGuide
extends Node2D
## Ayuda visual de los puntos de disparo. No afecta al gameplay.
## - En el editor dibuja todos los puntos de MuzzleConfig (mirando a la derecha).
## - En juego, F1 (acción debug_muzzle) muestra el punto de spawn y la línea de disparo actuales.

const LINE_LENGTH := 400.0
const SPAWN_COLOR := Color(1, 1, 0.2)
const LINE_COLOR := Color(1, 1, 0.2, 0.7)
const REFERENCE_COLOR := Color(0.3, 1, 1, 0.5)

## Compartido por todas las instancias: se activa/desactiva con F1
static var debug_enabled := false


func _ready() -> void:
	z_index = 50


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	if Input.is_action_just_pressed("debug_muzzle"):
		debug_enabled = not debug_enabled
	queue_redraw()


func _draw() -> void:
	var config := _config()
	if config == null:
		return
	if Engine.is_editor_hint():
		_draw_editor_guide(config)
	elif debug_enabled:
		_draw_runtime_debug(config)


func _draw_editor_guide(config: MuzzleConfig) -> void:
	var font := ThemeDB.fallback_font
	draw_line(Vector2(-24, -config.horizontal_height), Vector2(40, -config.horizontal_height), REFERENCE_COLOR, 1.0)
	var points := config.get_named_points()
	for key: String in points:
		var p: Vector2 = points[key]
		_draw_cross(p, SPAWN_COLOR)
		draw_string(font, p + Vector2(3, -2), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, SPAWN_COLOR)


func _draw_runtime_debug(config: MuzzleConfig) -> void:
	var player := get_parent() as Player
	if player == null:
		return
	# Línea de referencia: altura del disparo horizontal compartida por idle/run/jump/fall
	var ref_y := -config.horizontal_height
	draw_line(Vector2(-LINE_LENGTH, ref_y), Vector2(LINE_LENGTH, ref_y), REFERENCE_COLOR, 1.0)
	var spawn := player.get_muzzle_position() - player.global_position
	draw_line(spawn, spawn + player.aim * LINE_LENGTH, LINE_COLOR, 1.0)
	_draw_cross(spawn, SPAWN_COLOR)
	var label := "%s  y=%d" % [player.get_state_name().to_upper(), roundi(-spawn.y)]
	draw_string(ThemeDB.fallback_font, Vector2(-20, -40), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, SPAWN_COLOR)


func _draw_cross(p: Vector2, color: Color) -> void:
	draw_line(p + Vector2(-3, 0), p + Vector2(3, 0), color, 1.0)
	draw_line(p + Vector2(0, -3), p + Vector2(0, 3), color, 1.0)


func _config() -> MuzzleConfig:
	var parent := get_parent()
	return parent.get("muzzle_config") as MuzzleConfig if parent else null
