class_name EnemySpawner
extends Node2D
## Genera enemigos por el borde derecho de la pantalla mientras su columna está a la vista
## (los corredores infinitos de Contra). Desaparece cuando la cámara lo deja atrás.

@export var enemy_scene: PackedScene
@export var interval := 2.2
@export var first_delay := 0.8
@export var max_alive := 2
## Total a generar (0 = sin límite mientras esté activo)
@export var total := 5

var _timer := 0.0
var _spawned := 0
var _alive: Array[Node] = []
var _started := false


func _physics_process(delta: float) -> void:
	var cam := get_viewport().get_camera_2d() as GameCamera
	if cam == null or enemy_scene == null:
		return
	var view := cam.get_view_rect()
	if global_position.x < view.position.x - 32.0:
		queue_free()
		return
	if global_position.x > view.end.x:
		return
	if not _started:
		_started = true
		_timer = first_delay
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = interval
	_alive = _alive.filter(func(e): return is_instance_valid(e))
	if _alive.size() >= max_alive or (total > 0 and _spawned >= total):
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or not player.is_alive():
		return
	var enemy := enemy_scene.instantiate() as Node2D
	enemy.position = Vector2(view.end.x + 12.0, global_position.y)
	get_parent().add_child(enemy)
	if enemy is Enemy:
		enemy.force_activate()
	_alive.append(enemy)
	_spawned += 1
