class_name WeaponHolder
extends Node2D
## Ejecuta el arma actual leyendo su WeaponData (cadencia, patrón, límite en pantalla).

signal weapon_changed(weapon: WeaponData)
signal fired(weapon: WeaponData)

@export var default_weapon: WeaponData
@export var player_owned := true
## Armas para ciclar con la acción debug_next_weapon (solo pruebas)
@export var debug_weapons: Array[Resource] = []

var current: WeaponData
## Lo modifican los poderes (catnip)
var fire_rate_multiplier := 1.0
var damage_multiplier := 1.0

var _cooldown := 0.0
var _active: Array[Bullet] = []


func _ready() -> void:
	equip(default_weapon)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)


func equip(weapon: WeaponData) -> void:
	current = weapon
	_cooldown = 0.0
	weapon_changed.emit(weapon)


func reset_to_default() -> void:
	equip(default_weapon)


func cycle_debug_weapon() -> void:
	if debug_weapons.is_empty():
		return
	var idx := debug_weapons.find(current)
	equip(debug_weapons[(idx + 1) % debug_weapons.size()] as WeaponData)


func try_fire(origin: Vector2, direction: Vector2) -> bool:
	if current == null or _cooldown > 0.0:
		return false
	if current.max_on_screen > 0:
		_active = _active.filter(func(b): return is_instance_valid(b))
		# Con más cadencia (catnip) también se permiten más balas en pantalla
		if _active.size() >= ceili(current.max_on_screen * fire_rate_multiplier):
			return false
	_cooldown = 1.0 / (current.fire_rate * fire_rate_multiplier)
	_active.append_array(Bullet.spawn_pattern(current, origin, direction, player_owned, self, damage_multiplier))
	fired.emit(current)
	return true
