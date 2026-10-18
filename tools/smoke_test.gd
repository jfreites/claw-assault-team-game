extends Node
## Prueba de humo: carga el nivel de prueba, simula input y verifica lo básico.
## Uso: godot --headless --path . res://tools/smoke_test.tscn
## Sale con código 0 si todo pasa, 1 si algo falla.

const LEVEL := preload("res://scenes/levels/test_range.tscn")

var _failures := 0
var level: Level
var player: Player


func _ready() -> void:
	level = LEVEL.instantiate()
	add_child(level)
	await _frames(30)
	player = level.player
	await _test_player()
	print("SMOKE TEST: %s (%d fallos)" % ["OK" if _failures == 0 else "FALLÓ", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _test_player() -> void:
	_check(player.is_on_floor(), "el jugador aterriza en el suelo")
	var x0 := player.global_position.x
	Input.action_press("move_right")
	await _frames(40)
	_check(player.global_position.x > x0 + 30, "corre a la derecha (%.1f → %.1f)" % [x0, player.global_position.x])
	_check(player.state == Player.State.RUN, "estado RUN al correr")
	Input.action_press("move_up")
	await _frames(2)
	_check(player.aim.is_equal_approx(Vector2(1, -1).normalized()), "apunta en diagonal arriba al correr")
	Input.action_release("move_up")
	Input.action_release("move_right")
	await _frames(10)
	_check(player.state == Player.State.IDLE, "vuelve a IDLE")

	# Salto variable: un toque corto sube menos que mantener
	var y0 := player.global_position.y
	var short_peak := await _jump_peak(3)
	await _frames(40)
	var long_peak := await _jump_peak(30)
	_check(y0 - long_peak > 45, "salto largo alto (%.1f px)" % (y0 - long_peak))
	_check(y0 - short_peak < (y0 - long_peak) * 0.7, "salto corto más bajo (%.1f px)" % (y0 - short_peak))
	await _frames(40)

	# Echarse
	Input.action_press("crouch")
	await _frames(3)
	_check(player.state == Player.State.PRONE, "se echa con abajo")
	_check(player.hurt_stand.disabled and not player.hurt_prone.disabled, "hurtbox reducido al echarse")
	Input.action_release("crouch")
	await _frames(3)

	# Bajar por plataforma one-way (columnas 12-16, fila 9)
	_teleport(Vector2(14 * 16 + 8, 9 * 16 - 2))
	await _frames(20)
	var on_platform_y := player.global_position.y
	_check(player.is_on_floor() and absf(on_platform_y - 144.0) < 2.0, "parado sobre la plataforma one-way (y=%.1f)" % on_platform_y)
	Input.action_press("crouch")
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	Input.action_release("crouch")
	await _frames(30)
	_check(player.global_position.y > on_platform_y + 20, "bajó a través de la plataforma (y=%.1f)" % player.global_position.y)

	# Agua: muerte instantánea
	_teleport(Vector2(34 * 16 + 8, 10 * 16))
	await _frames(40)
	_check(player.state == Player.State.DEAD, "muere al caer al agua (pos=%s estado=%d)" % [player.global_position, player.state])


func _teleport(pos: Vector2) -> void:
	player.global_position = pos
	player.velocity = Vector2.ZERO
	level.camera.snap_to_target()


func _jump_peak(hold_frames: int) -> float:
	var peak := player.global_position.y
	Input.action_press("jump")
	for i in 60:
		if i == hold_frames:
			Input.action_release("jump")
		await get_tree().physics_frame
		peak = minf(peak, player.global_position.y)
	Input.action_release("jump")
	return peak


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _check(cond: bool, label: String) -> void:
	print(("  [ok]   " if cond else "  [FAIL] ") + label)
	if not cond:
		_failures += 1
