class_name MuzzleFlash
extends Node2D
## Destello circular breve en la boca del arma.

const LIFETIME := 0.05

var color := Color(1, 0.95, 0.6)
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFETIME:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var r := lerpf(4.0, 2.0, _t / LIFETIME)
	draw_circle(Vector2.ZERO, r, color)
	draw_circle(Vector2.ZERO, r * 0.5, Color.WHITE)
