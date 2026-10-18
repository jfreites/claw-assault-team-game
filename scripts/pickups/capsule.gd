class_name Capsule
extends Enemy
## Cápsula voladora: cruza la pantalla en onda sinusoidal y al destruirla suelta su `item`.
## No daña por contacto (contact_damage = 0 en sus stats).

## WeaponData o PowerUpData que suelta (si es null usa el drop_table de los stats)
@export var item: Resource

var dir := -1
var _base_y := 0.0
var _t := 0.0


func _on_activated() -> void:
	_base_y = global_position.y
	var p := get_player()
	# Cruza la pantalla hacia el lado del jugador
	if p:
		dir = -1 if p.global_position.x < global_position.x else 1


func _enemy_process(delta: float) -> void:
	_t += delta
	global_position.x += dir * stats.move_speed * delta
	global_position.y = _base_y + sin(_t * TAU * stats.wave_frequency) * stats.wave_amplitude


func _try_drop() -> void:
	if item:
		Pickup.spawn(self, item, global_position)
	else:
		super._try_drop()


func _center_offset() -> Vector2:
	return Vector2.ZERO
