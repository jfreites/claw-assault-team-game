class_name FlyerEnemy
extends Enemy
## Volador: avanza en línea recta con onda sinusoidal vertical y suelta proyectiles.

var dir := -1
var _base_y := 0.0
var _t := 0.0
var _timer := 0.0

@onready var muzzle: Marker2D = $Muzzle


func _on_activated() -> void:
	_base_y = global_position.y
	var p := get_player()
	if p:
		dir = -1 if p.global_position.x < global_position.x else 1
	_timer = stats.first_shot_delay


func _enemy_process(delta: float) -> void:
	_t += delta
	global_position.x += dir * stats.move_speed * delta
	global_position.y = _base_y + sin(_t * TAU * stats.wave_frequency) * stats.wave_amplitude
	sprite.flip_h = dir < 0
	_timer -= delta
	if _timer <= 0.0:
		_timer = stats.fire_interval
		var p := get_player()
		if p and p.is_alive():
			# Suelta la bomba con un leve empuje hacia el jugador
			var side := signf(p.global_position.x - global_position.x)
			Bullet.spawn_pattern(stats.weapon, muzzle.global_position, Vector2(side * 0.5, 1.0), false, self)


func _center_offset() -> Vector2:
	return Vector2.ZERO
