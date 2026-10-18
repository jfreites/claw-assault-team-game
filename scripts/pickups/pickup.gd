class_name Pickup
extends Area2D
## Objeto recogible. `item` apunta a un WeaponData o a un PowerUpData.
## Salta al aparecer, cae hasta el suelo y parpadea antes de desaparecer.

const SCENE_PATH := "res://scenes/pickups/pickup.tscn"
const GRAVITY := 500.0
const MAX_FALL := 220.0
const LIFETIME := 12.0
const BLINK_TIME := 3.0
## Distancia del centro al suelo al aterrizar (medio hitbox)
const REST_HEIGHT := 7.0

@export var item: Resource

var velocity := Vector2(0, -140)
var _life := 0.0
var _landed := false

@onready var sprite: EntitySprite = $Sprite


## Crea un pickup en `pos` con el contenido `item`
static func spawn(context: Node, item_res: Resource, pos: Vector2) -> Pickup:
	var pickup := (load(SCENE_PATH) as PackedScene).instantiate() as Pickup
	pickup.item = item_res
	pickup.position = pos
	Bullet.get_projectile_root(context).add_child.call_deferred(pickup)
	return pickup


func _ready() -> void:
	collision_layer = Layers.PICKUP
	collision_mask = Layers.PLAYER
	monitoring = true
	body_entered.connect(_on_body_entered)
	var sprite_path := ""
	if item is WeaponData or item is PowerUpData:
		sprite_path = item.pickup_sprite
	if sprite_path != "":
		sprite.entity = sprite_path


func _physics_process(delta: float) -> void:
	_life += delta
	if _life >= LIFETIME:
		queue_free()
		return
	sprite.visible = _life < LIFETIME - BLINK_TIME or int(_life * 10.0) % 2 == 0
	if _landed:
		return
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	var motion := velocity * delta
	# Solo aterriza al caer (atraviesa plataformas al subir)
	if velocity.y > 0.0:
		var from := global_position + Vector2(0, REST_HEIGHT)
		var query := PhysicsRayQueryParameters2D.create(from, from + motion, Layers.WORLD | Layers.ONE_WAY)
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		if hit:
			global_position = hit.position - Vector2(0, REST_HEIGHT)
			_landed = true
			return
	global_position += motion
	if global_position.y > GameState.level_bottom_y + 32.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or not player.is_alive() or item == null:
		return
	player.collect(item)
	Fx.burst(self, global_position, Color(1, 1, 0.6), 8, 60.0, 0.3)
	queue_free()
