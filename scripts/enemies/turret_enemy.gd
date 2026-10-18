class_name TurretEnemy
extends Enemy
## Torreta fija: dispara hacia el jugador cada `fire_interval` segundos si está en rango.

var _timer := 0.0

@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	super._ready()
	sprite.animation_finished.connect(func(): sprite.play_safe(&"idle"))


func _on_activated() -> void:
	_timer = stats.first_shot_delay


func _enemy_process(delta: float) -> void:
	var p := get_player()
	if p == null or not p.is_alive():
		return
	var to_player := p.get_aim_point() - muzzle.global_position
	sprite.flip_h = to_player.x < 0.0
	_timer -= delta
	if _timer <= 0.0 and to_player.length() <= stats.fire_range:
		_timer = stats.fire_interval
		Bullet.spawn_pattern(stats.weapon, muzzle.global_position, aim_at_player(muzzle.global_position), false, self)
		if sprite.sprite_frames.has_animation(&"fire"):
			sprite.play(&"fire")
