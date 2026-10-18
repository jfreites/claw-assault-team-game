class_name Bullet
extends Hitbox
## Proyectil genérico configurado por un WeaponData (jugador y enemigos).
## Se mueve a mano con raycast contra el mundo para rebotar sin atravesar paredes.

const OFFSCREEN_MARGIN := 24.0

var data: WeaponData
var velocity := Vector2.ZERO
var from_player := true

var _life := 0.0
var _bounces_left := 0
var _pierce_left := -1
var _hit_ids: Array[int] = []
var _spent := false

@onready var sprite: EntitySprite = $Sprite
@onready var shape: CollisionShape2D = $Shape


## Instancia las balas del patrón del arma. Devuelve las balas creadas.
static func spawn_pattern(weapon: WeaponData, origin: Vector2, direction: Vector2, player_owned: bool, context: Node, damage_multiplier := 1.0) -> Array[Bullet]:
	var spawned: Array[Bullet] = []
	if weapon == null or weapon.bullet_scene == null:
		return spawned
	var dirs: Array[Vector2] = []
	if weapon.pattern == WeaponData.Pattern.SPREAD and weapon.spread_count > 1:
		var step := deg_to_rad(weapon.spread_angle) / float(weapon.spread_count - 1)
		var start := -deg_to_rad(weapon.spread_angle) * 0.5
		for i in weapon.spread_count:
			dirs.append(direction.rotated(start + step * i))
	else:
		dirs.append(direction)
	var root := get_projectile_root(context)
	for dir in dirs:
		var bullet := weapon.bullet_scene.instantiate() as Bullet
		bullet.configure(weapon, dir, player_owned, damage_multiplier)
		bullet.position = origin
		root.add_child(bullet)
		spawned.append(bullet)
	AudioManager.play_sfx(weapon.sfx)
	return spawned


static func get_projectile_root(context: Node) -> Node:
	var root := context.get_tree().get_first_node_in_group("projectile_root")
	return root if root else context.get_tree().current_scene


func configure(weapon: WeaponData, direction: Vector2, player_owned: bool, damage_multiplier := 1.0) -> void:
	data = weapon
	from_player = player_owned
	velocity = direction.normalized() * weapon.bullet_speed
	damage = maxi(1, roundi(weapon.damage * damage_multiplier))
	_bounces_left = weapon.max_bounces if weapon.pattern == WeaponData.Pattern.BOUNCE else 0
	_pierce_left = weapon.pierce_count if weapon.pattern == WeaponData.Pattern.PIERCE else 0


func _ready() -> void:
	super._ready()
	if data == null:
		queue_free()
		return
	collision_layer = Layers.PLAYER_BULLET if from_player else Layers.ENEMY_BULLET
	collision_mask = 0
	var circle := CircleShape2D.new()
	circle.radius = data.hit_radius
	shape.shape = circle
	sprite.entity = data.bullet_sprite
	_update_rotation()


func _physics_process(delta: float) -> void:
	if _spent:
		return
	_life += delta
	if _life >= data.lifetime:
		queue_free()
		return
	velocity.y += data.bullet_gravity * delta
	var motion := velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + motion, Layers.WORLD)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit:
		if _bounces_left > 0:
			_bounces_left -= 1
			velocity = velocity.bounce(hit.normal) * data.bounce_damping
			global_position = hit.position + hit.normal * 1.0
			AudioManager.play_sfx("bounce")
		else:
			global_position = hit.position
			_impact()
			return
	else:
		global_position += motion
	_update_rotation()
	if _is_offscreen():
		queue_free()


func can_hit(hurtbox: Hurtbox) -> bool:
	return not _spent and not _hit_ids.has(hurtbox.get_instance_id())


func on_hit(hurtbox: Hurtbox) -> void:
	_hit_ids.append(hurtbox.get_instance_id())
	super.on_hit(hurtbox)
	if data.pattern == WeaponData.Pattern.PIERCE:
		if _pierce_left < 0:
			return
		_pierce_left -= 1
		if _pierce_left > 0:
			return
	_impact()


func _impact() -> void:
	_spent = true
	Fx.burst(self, global_position, Color(1, 0.9, 0.5) if from_player else Color(1, 0.4, 0.3), 5, 50.0, 0.2)
	queue_free()


func _update_rotation() -> void:
	if data.rotate_sprite and velocity.length_squared() > 0.01:
		sprite.rotation = velocity.angle()


func _is_offscreen() -> bool:
	var cam := get_viewport().get_camera_2d() as GameCamera
	if cam == null:
		return false
	return not cam.get_view_rect().grow(OFFSCREEN_MARGIN).has_point(global_position)
