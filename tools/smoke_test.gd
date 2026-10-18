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
	# Las pruebas de movimiento se hacen sin los enemigos del nivel
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
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

	await _test_weapons()
	await _test_enemies()
	await _test_pickups()

	# Agua: muerte instantánea
	_teleport(Vector2(34 * 16 + 8, 10 * 16))
	await _frames(40)
	_check(player.state == Player.State.DEAD, "muere al caer al agua (pos=%s estado=%d)" % [player.global_position, player.state])


func _test_weapons() -> void:
	_teleport(Vector2(4 * 16, 11 * 16))
	await _frames(20)
	var holder := player.weapon_holder
	_check(holder.current.display_name == "Bola de pelo", "arma por defecto: bola de pelo")
	Input.action_press("shoot")
	await _frames(30)
	Input.action_release("shoot")
	var shots := _bullets().size()
	_check(shots >= 2 and shots <= 4, "dispara con cadencia y límite en pantalla (%d balas)" % shots)
	await _frames(60)

	Input.action_press("debug_next_weapon")
	await _frames(3)
	Input.action_release("debug_next_weapon")
	_check(holder.current.display_name == "Estambre", "cambia a estambre (debug)")
	Input.action_press("shoot")
	await _frames(1)
	Input.action_release("shoot")
	var yarn := _bullets()
	_check(yarn.size() == 1, "estambre dispara 1 bala")
	if yarn.size() == 1:
		var b: Bullet = yarn[0]
		await _frames(25)
		_check(is_instance_valid(b) and b.data.pattern == WeaponData.Pattern.BOUNCE and b._bounces_left < b.data.max_bounces, "el estambre rebota en el suelo")
	await _frames(120)

	holder.equip(load("res://resources/weapons/sardine_spread.tres"))
	Input.action_press("shoot")
	await _frames(1)
	Input.action_release("shoot")
	_check(_bullets().size() == 3, "spread dispara 3 balas (%d)" % _bullets().size())
	await _frames(60)
	holder.reset_to_default()


func _test_enemies() -> void:
	_teleport(Vector2(72 * 16, 11 * 16))
	await _frames(20)
	player.start_invulnerability(100.0)
	player.facing = 1
	player.aim = Vector2.RIGHT
	var hits := []
	# Se guarda el tipo de fuente al momento del golpe (la bala puede liberarse luego)
	player.hurtbox.hurt.connect(func(_d, src): hits.append("enemy_bullet" if src is Bullet and not src.from_player else ("contact" if not src is Bullet else "other")))
	var ground := player.global_position.y

	# Corredor: se acerca y el contacto daña
	var runner := _spawn("res://scenes/enemies/runner.tscn", Vector2(player.global_position.x + 120, ground))
	await _frames(20)
	var rx := runner.global_position.x
	await _frames(40)
	_check(is_instance_valid(runner) and runner.global_position.x < rx - 20, "el corredor camina hacia el jugador")
	await _frames(60)
	_check(hits.has("contact"), "el contacto del corredor golpea al jugador")
	var died := []
	if is_instance_valid(runner):
		runner.died.connect(func(e): died.append(e))
		Input.action_press("shoot")
		await _frames(30)
		Input.action_release("shoot")
	_check(not died.is_empty() or not is_instance_valid(runner), "el corredor muere con disparos")
	await _frames(30)

	# Torreta: dispara al jugador, hit-flash y espina perforante
	hits.clear()
	var t1 := _spawn("res://scenes/enemies/turret.tscn", Vector2(player.global_position.x + 110, ground))
	var t2 := _spawn("res://scenes/enemies/turret.tscn", Vector2(player.global_position.x + 150, ground))
	await _frames(150)
	_check(hits.has("enemy_bullet"), "la torreta dispara y alcanza al jugador")
	player.weapon_holder.equip(load("res://resources/weapons/fishbone.tres"))
	player.facing = 1
	Input.action_press("crouch")
	await _frames(3)
	var flashed := [false, false]
	t1.damaged.connect(func(_a): flashed[0] = t1._flash > 0.0)
	t2.damaged.connect(func(_a): flashed[1] = true)
	Input.action_press("shoot")
	await _frames(150)
	_check(flashed[0], "hit-flash al recibir daño")
	_check(flashed[1], "la espina atraviesa la primera torreta y daña la segunda")
	Input.action_release("shoot")
	Input.action_release("crouch")
	_check(not is_instance_valid(t1) and not is_instance_valid(t2), "la espina perforante destruye ambas torretas")
	player.weapon_holder.reset_to_default()

	# Volador: onda sinusoidal y bombas
	var flyer := _spawn("res://scenes/enemies/flyer.tscn", Vector2(player.global_position.x + 120, ground - 90))
	await _frames(10)
	var ys := []
	var bomb_seen := false
	for i in 120:
		await get_tree().physics_frame
		if is_instance_valid(flyer):
			ys.append(flyer.global_position.y)
		if _bullets().any(func(b): return not b.from_player and b.data.bullet_gravity > 0.0):
			bomb_seen = true
	_check(ys.size() > 0 and ys.max() - ys.min() > 20, "el volador oscila en vertical")
	_check(bomb_seen, "el volador suelta bombas")
	if is_instance_valid(flyer):
		flyer.queue_free()
	player.start_invulnerability(0.0)
	await _frames(5)


func _test_pickups() -> void:
	_teleport(Vector2(72 * 16, 11 * 16))
	await _frames(20)
	var ground := player.global_position.y
	player.facing = 1
	player.weapon_holder.reset_to_default()

	# Cápsula: al dispararle suelta su pickup, que cae al suelo
	var capsule := _spawn("res://scenes/pickups/capsule_yarn.tscn", Vector2(player.global_position.x + 150, ground - 16))
	var destroyed := []
	capsule.died.connect(func(_e): destroyed.append(true))
	Input.action_press("shoot")
	await _until(func(): return not destroyed.is_empty(), 120)
	Input.action_release("shoot")
	_check(not destroyed.is_empty(), "la cápsula se destruye a disparos")
	await _frames(60)
	var pickups := _pickups()
	_check(pickups.size() == 1, "la cápsula suelta un pickup")
	if pickups.size() == 1:
		var pk: Pickup = pickups[0]
		_check(pk._landed and absf(pk.global_position.y + Pickup.REST_HEIGHT - ground) < 2.0, "el pickup cae hasta el suelo")
		Input.action_press("move_right" if pk.global_position.x > player.global_position.x else "move_left")
		await _until(func(): return _pickups().is_empty(), 120)
		Input.action_release("move_right")
		Input.action_release("move_left")
		_check(player.weapon_holder.current.display_name == "Estambre", "recoger el pickup equipa el estambre")

	# Catnip: más velocidad y cadencia, con señales de inicio y fin
	var events := []
	player.powers.power_started.connect(func(p): events.append("start:" + p.display_name))
	player.powers.power_ended.connect(func(p): events.append("end:" + p.display_name))
	var catnip: PowerUpData = load("res://resources/powerups/catnip.tres")
	player.weapon_holder.reset_to_default()
	var normal_shots := await _count_shots(60)
	var normal_x := player.global_position.x
	Input.action_press("move_right")
	await _frames(30)
	Input.action_release("move_right")
	var normal_run := player.global_position.x - normal_x
	_teleport(Vector2(72 * 16, 11 * 16))
	await _frames(20)
	player.collect(catnip)
	await _frames(2)
	_check(player.sprite.modulate != Color.WHITE, "el catnip tiñe al personaje")
	var catnip_shots := await _count_shots(60)
	var catnip_x := player.global_position.x
	Input.action_press("move_right")
	await _frames(30)
	Input.action_release("move_right")
	var catnip_run := player.global_position.x - catnip_x
	_check(catnip_shots >= normal_shots * 1.5, "catnip: más disparos por segundo (%d → %d)" % [normal_shots, catnip_shots])
	_check(catnip_run >= normal_run * 1.3, "catnip: corre más rápido (%.0f → %.0f px en 0.5 s)" % [normal_run, catnip_run])
	_teleport(Vector2(72 * 16, 11 * 16))
	await _frames(20)
	_check(events.has("start:Catnip"), "señal power_started del catnip")
	_check(is_equal_approx(player.speed_multiplier, catnip.speed_multiplier) and is_equal_approx(player.weapon_holder.fire_rate_multiplier, catnip.fire_rate_multiplier), "catnip sube velocidad y cadencia")
	_check(level.hud.power.text.contains("CATNIP"), "el HUD muestra el poder y su tiempo (%s)" % level.hud.power.text)
	player.powers._remaining[catnip] = 0.05
	await _frames(10)
	_check(events.has("end:Catnip") and is_equal_approx(player.speed_multiplier, 1.0), "al terminar el catnip se restauran los valores")

	# Leche: escudo que absorbe un golpe
	player.collect(load("res://resources/powerups/milk.tres"))
	await _frames(2)
	_check(player.powers.shield_hits == 1 and player.shield_sprite.visible, "la leche activa el escudo visible")
	var fake_hit := Hitbox.new()
	player._on_hurtbox_hurt(1, fake_hit)
	fake_hit.free()
	await _frames(2)
	_check(player.is_alive() and player.powers.shield_hits == 0, "el escudo absorbe un golpe")
	_check(events.has("end:Leche") and player.is_invulnerable(), "escudo gastado termina el poder y da invulnerabilidad")

	# Drop de enemigo
	var runner := _spawn("res://scenes/enemies/runner.tscn", Vector2(player.global_position.x + 60, ground))
	runner.stats = runner.stats.duplicate()
	runner.stats.drop_chance = 1.0
	var before := _pickups().size()
	runner.die()
	await _frames(5)
	_check(_pickups().size() == before + 1, "un enemigo con drop_chance suelta pickup")
	await _frames(70)


func _count_shots(frames: int) -> int:
	var shots := [0]
	var cb := func(_w): shots[0] += 1
	player.weapon_holder.fired.connect(cb)
	Input.action_press("shoot")
	await _frames(frames)
	Input.action_release("shoot")
	player.weapon_holder.fired.disconnect(cb)
	await _frames(60)
	return shots[0]


func _pickups() -> Array:
	return get_tree().get_nodes_in_group("projectile_root")[0].get_children().filter(func(n): return n is Pickup)


func _spawn(path: String, pos: Vector2) -> Enemy:
	var e: Enemy = load(path).instantiate()
	e.position = pos
	level.entities.add_child(e)
	return e


func _bullets() -> Array:
	return get_tree().get_nodes_in_group("projectile_root")[0].get_children().filter(func(n): return n is Bullet)


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


## Espera hasta que `cond` sea verdadera o pasen `max_frames`
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
