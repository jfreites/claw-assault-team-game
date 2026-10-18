class_name Checkpoint
extends Area2D
## Al tocarlo guarda la posición de reaparición en GameState e iza la bandera.

var _reached := false

@onready var sprite: EntitySprite = $Sprite


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER
	body_entered.connect(_on_body_entered)
	# Si ya se había alcanzado (reaparición tras perder una vida) queda izada
	if GameState.has_checkpoint() and GameState.checkpoint_position.distance_to(global_position) < 1.0:
		_reached = true
		sprite.play_safe(&"active")


func _on_body_entered(body: Node2D) -> void:
	if _reached or not body is Player:
		return
	_reached = true
	GameState.set_checkpoint(global_position)
	sprite.play_safe(&"active")
	AudioManager.play_sfx("checkpoint")
	Fx.burst(self, global_position + Vector2(0, -24), Color(1, 0.9, 0.4), 12, 70.0, 0.4)
	var hud := get_tree().get_first_node_in_group("hud") as Hud
	if hud:
		hud.flash_message("CHECKPOINT", 1.5)
