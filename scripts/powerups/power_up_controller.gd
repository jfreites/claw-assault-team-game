class_name PowerUpController
extends Node
## Administra los poderes activos del jugador: tiempos, modificadores combinados y escudo.

signal power_started(power: PowerUpData)
signal power_ended(power: PowerUpData)
signal shield_changed(hits: int)

var shield_hits := 0

var _remaining: Dictionary = {}  # PowerUpData → segundos restantes

@onready var player: Player = get_parent()


func activate(power: PowerUpData) -> void:
	var is_new := not _remaining.has(power)
	_remaining[power] = power.duration
	if power.shield_hits > 0:
		shield_hits = maxi(shield_hits, power.shield_hits)
		shield_changed.emit(shield_hits)
	_apply()
	AudioManager.play_sfx(power.sfx)
	if is_new:
		power_started.emit(power)


func _physics_process(delta: float) -> void:
	for power in _remaining.keys():
		_remaining[power] -= delta
		if _remaining[power] <= 0.0:
			_end(power)


## Gasta un golpe del escudo. Devuelve true si el golpe fue absorbido.
func absorb_hit() -> bool:
	if shield_hits <= 0:
		return false
	shield_hits -= 1
	shield_changed.emit(shield_hits)
	AudioManager.play_sfx("shield_break")
	if shield_hits == 0:
		for power in _remaining.keys():
			if power.shield_hits > 0:
				_end(power)
	return true


func clear() -> void:
	for power in _remaining.keys():
		_end(power)


func get_active() -> Array:
	return _remaining.keys()


func get_remaining(power: PowerUpData) -> float:
	return maxf(_remaining.get(power, 0.0), 0.0)


func _end(power: PowerUpData) -> void:
	if not _remaining.has(power):
		return
	_remaining.erase(power)
	if power.shield_hits > 0 and not _has_shield_power():
		shield_hits = 0
		shield_changed.emit(0)
	_apply()
	power_ended.emit(power)


func _has_shield_power() -> bool:
	for power in _remaining:
		if power.shield_hits > 0:
			return true
	return false


## Recalcula los multiplicadores del jugador a partir de los poderes activos
func _apply() -> void:
	var speed := 1.0
	var fire_rate := 1.0
	var jump := 1.0
	var damage := 1.0
	var air_jumps := 0
	for power in _remaining:
		speed *= power.speed_multiplier
		fire_rate *= power.fire_rate_multiplier
		jump *= power.jump_multiplier
		damage *= power.damage_multiplier
		air_jumps += power.extra_air_jumps
	player.speed_multiplier = speed
	player.jump_multiplier = jump
	player.extra_air_jumps = air_jumps
	player.weapon_holder.fire_rate_multiplier = fire_rate
	player.weapon_holder.damage_multiplier = damage
