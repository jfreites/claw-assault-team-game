extends Node
## Recorrido automático del nivel 1: un bot corre a la derecha disparando y salta
## al llegar a un borde o pared. Verifica caída inicial, checkpoint y bloqueo de cámara.
## Uso: godot --headless --path . res://tools/playthrough_test.tscn
## (el jugador es invulnerable a enemigos; el agua/abismo sí lo matan)

const LEVEL_PATH := "res://scenes/levels/level_01.tscn"
const TIME_LIMIT := 240.0

var level: Level
var player: Player
var _failures := 0


func _ready() -> void:
	GameState.reset_run()
	level = (load(LEVEL_PATH) as PackedScene).instantiate()
	add_child(level)
	player = level.player
	var arena := [false]
	level.boss_arena_entered.connect(func(): arena[0] = true)
	await get_tree().physics_frame

	_check(player.state == Player.State.FALL and not player.input_enabled, "el gato entra cayendo del cielo sin control")
	await _until(func(): return player.input_enabled, 180)
	_check(player.input_enabled and player.is_on_floor(), "aterriza en la playa y recupera el control")
	player.start_invulnerability(9999.0)

	var t := 0.0
	var checkpoint_time := -1.0
	var start_lives := GameState.lives
	Input.action_press("move_right")
	Input.action_press("shoot")
	while t < TIME_LIMIT and not arena[0]:
		await get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
		if not is_instance_valid(player) or not player.is_alive():
			print("    el bot murió en x=%.0f (col %d) y=%.0f velocidad=%.2f" % [player.global_position.x, int(player.global_position.x / 16), player.global_position.y, player.speed_multiplier])
			break
		if checkpoint_time < 0.0 and GameState.has_checkpoint():
			checkpoint_time = t
		_bot_jump()
	Input.action_release("move_right")
	Input.action_release("shoot")
	Input.action_release("jump")

	_check(GameState.lives == start_lives, "el bot no cae al agua ni al abismo")
	_check(checkpoint_time > 0.0, "se activa el checkpoint (%.1f s)" % checkpoint_time)
	_check(arena[0], "llega a la arena del jefe (%.1f s de carrera continua)" % t)
	if arena[0]:
		await _frames(120)
		var cam := level.camera
		var expected := level._arena_x + cam.get_view_size().x * 0.5
		_check(cam.is_locked() and absf(cam.global_position.x - expected) < 1.0, "la cámara se bloquea en la arena")
		Input.action_press("move_left")
		await _frames(120)
		Input.action_release("move_left")
		_check(player.global_position.x >= cam.get_view_rect().position.x, "no se puede salir de la arena hacia atrás")
	print("PLAYTHROUGH: %s (%d fallos)" % ["OK" if _failures == 0 else "FALLÓ", _failures])
	# Silenciar y esperar un poco: así el servidor de audio suelta los sonidos antes de salir
	AudioManager.stop_all()
	await _frames(5)
	get_tree().quit(1 if _failures > 0 else 0)


## Salta si delante no hay suelo o hay una pared
func _bot_jump() -> void:
	if not player.is_on_floor():
		if player.velocity.y > 0.0:
			Input.action_release("jump")
		return
	var space := player.get_world_2d().direct_space_state
	var feet := player.global_position
	var mask := Layers.WORLD | Layers.ONE_WAY
	var ahead := feet + Vector2(14, -4)
	var ground := space.intersect_ray(PhysicsRayQueryParameters2D.create(ahead, ahead + Vector2(0, 40), mask))
	var wall := space.intersect_ray(PhysicsRayQueryParameters2D.create(feet + Vector2(0, -8), feet + Vector2(16, -8), Layers.WORLD))
	if ground.is_empty() or not wall.is_empty():
		Input.action_press("jump")


func _until(cond: Callable, max_frames: int) -> void:
	for i in max_frames:
		if cond.call():
			return
		await get_tree().physics_frame


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _check(cond: bool, label: String) -> void:
	print(("  [ok]   " if cond else "  [FAIL] ") + label)
	if not cond:
		_failures += 1
