class_name RunnerEnemy
extends Enemy
## Corredor: camina hacia el jugador, se reorienta cada cierto tiempo y al chocar con paredes.

var dir := -1
var _think := 0.0


func _on_activated() -> void:
	_face_player()
	_think = stats.think_interval


func _enemy_process(delta: float) -> void:
	_think -= delta
	if _think <= 0.0:
		_think = stats.think_interval
		_face_player()
	velocity.x = dir * stats.move_speed
	velocity.y = minf(velocity.y + stats.gravity * delta, 400.0)
	move_and_slide()
	if is_on_wall():
		dir = -dir
	sprite.flip_h = dir < 0
	sprite.play_safe(&"run" if is_on_floor() else &"fall", &"run")


func _face_player() -> void:
	var p := get_player()
	if p:
		dir = -1 if p.global_position.x < global_position.x else 1
