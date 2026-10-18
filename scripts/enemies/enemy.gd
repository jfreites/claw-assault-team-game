class_name Enemy
extends CharacterBody2D
## Base de enemigos: salud, daño por contacto, hit-flash, muerte y drop.
## Se activa al entrar en pantalla y se elimina al quedar atrás de la cámara o caer al abismo.
## Subclases: sobrescribir _on_activated() y _enemy_process(delta).

signal died(enemy: Enemy)
signal damaged(amount: int)

const FLASH_SHADER := preload("res://resources/shaders/hit_flash.gdshader")
const FLASH_TIME := 0.08
const DESPAWN_MARGIN := 64.0
## Se activa cuando entra a esta distancia del borde de la pantalla
const ACTIVATION_MARGIN := 8.0

@export var stats: EnemyStats

var health := 1
var active := false

var _dead := false
var _flash := 0.0
var _flash_material: ShaderMaterial

@onready var sprite: EntitySprite = $Sprite
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var contact: Hitbox = $ContactHitbox


func _ready() -> void:
	if stats == null:
		stats = EnemyStats.new()
	health = stats.max_health
	add_to_group("enemies")
	hurtbox.collision_layer = Layers.ENEMY
	hurtbox.collision_mask = Layers.PLAYER_BULLET
	hurtbox.hurt.connect(_on_hurtbox_hurt)
	contact.collision_layer = Layers.ENEMY
	contact.collision_mask = 0
	contact.damage = stats.contact_damage
	contact.monitorable = stats.contact_damage > 0

	_flash_material = ShaderMaterial.new()
	_flash_material.shader = FLASH_SHADER
	sprite.material = _flash_material


func _physics_process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(_flash - delta, 0.0)
		_flash_material.set_shader_parameter("flash", 1.0 if _flash > 0.0 else 0.0)
	if _dead:
		return
	if not active:
		_check_activation()
		return
	_enemy_process(delta)
	_check_despawn()


func take_damage(amount: int) -> void:
	if _dead:
		return
	health -= amount
	_flash = FLASH_TIME
	_flash_material.set_shader_parameter("flash", 1.0)
	damaged.emit(amount)
	if health <= 0:
		die()
	else:
		AudioManager.play_sfx("enemy_hit")


func die() -> void:
	if _dead:
		return
	_dead = true
	hurtbox.active = false
	AudioManager.play_sfx("enemy_die")
	Fx.explosion(self, global_position + _center_offset())
	died.emit(self)
	_try_drop()
	queue_free()


func get_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


## Dirección hacia el jugador, opcionalmente redondeada a N direcciones
func aim_at_player(from: Vector2) -> Vector2:
	var p := get_player()
	if p == null:
		return Vector2.LEFT
	var dir := (p.get_aim_point() - from).normalized()
	if stats.aim_directions > 0:
		var step := TAU / stats.aim_directions
		dir = Vector2.RIGHT.rotated(roundf(dir.angle() / step) * step)
	return dir


# --- Para sobrescribir ----------------------------------------------------

func _on_activated() -> void:
	pass


func _enemy_process(_delta: float) -> void:
	pass


func _center_offset() -> Vector2:
	return Vector2(0, -10)


## Activa al enemigo aunque esté fuera de pantalla (spawners)
func force_activate() -> void:
	if not active and not _dead:
		active = true
		_on_activated.call_deferred()


# --- Interno --------------------------------------------------------------

func _check_activation() -> void:
	var cam := get_viewport().get_camera_2d() as GameCamera
	if cam == null or cam.get_view_rect().grow(ACTIVATION_MARGIN).has_point(global_position):
		active = true
		_on_activated()


func _on_hurtbox_hurt(damage: int, _source: Hitbox) -> void:
	take_damage(damage)


func _try_drop() -> void:
	if stats.drop_table.is_empty() or randf() > stats.drop_chance:
		return
	Pickup.spawn(self, stats.drop_table.pick_random(), global_position + _center_offset())


func _check_despawn() -> void:
	if global_position.y > GameState.level_bottom_y + DESPAWN_MARGIN:
		queue_free()
		return
	var cam := get_viewport().get_camera_2d() as GameCamera
	if cam and global_position.x < cam.get_view_rect().position.x - DESPAWN_MARGIN:
		queue_free()
