extends Node
## Prueba del jefe del nivel 1 (perro mecha): aparición, ataques, punto débil, fases y muerte.
## Uso: godot --headless --path . res://tools/boss_test.tscn

const LEVEL_PATH := "res://scenes/levels/level_01.tscn"

var level: Level
var player: Player
var boss: Boss
var _failures := 0


func _ready() -> void:
	GameState.reset_run()
	level = (load(LEVEL_PATH) as PackedScene).instantiate()
	level.advance_on_boss_defeat = false
	level.intro_drop = false
	add_child(level)
	await _frames(10)
	player = level.player
	player.start_invulnerability(9999.0)
	boss = get_tree().get_first_node_in_group("boss") as Boss
	_check(boss != null and boss.state == Boss.State.DORMANT and not boss.visible, "el jefe espera dormido e invisible")

	# Entrar a la arena
	player.global_position = Vector2(218 * 16, 190)
	level.camera.snap_to_target()
	await _until(func(): return boss.state != Boss.State.DORMANT, 180)
	_check(level.camera.is_locked(), "la cámara se bloquea al entrar a la arena")
	_check(boss.visible and boss.state == Boss.State.INTRO, "el jefe aparece cayendo")
	_check(level.hud.boss_bar.visible, "barra de vida del jefe en el HUD")
	await _until(func(): return boss.state == Boss.State.IDLE, 300)
	_check(boss.state == Boss.State.IDLE and boss.is_on_floor(), "aterriza y empieza el combate")

	# Fase 1: abanico y embestida
	var max_bullets := [0]
	var saw := {}
	for i in 600:
		await get_tree().physics_frame
		saw[boss.state] = true
		max_bullets[0] = maxi(max_bullets[0], _enemy_bullets().size())
		if saw.has(Boss.State.CHARGE) and saw.has(Boss.State.RECOVER) and max_bullets[0] >= 5:
			break
	_check(max_bullets[0] >= 5, "fase 1: dispara en abanico (%d balas a la vez)" % max_bullets[0])
	_check(saw.has(Boss.State.WINDUP) and saw.has(Boss.State.CHARGE) and saw.has(Boss.State.RECOVER), "fase 1: avisa, embiste y se recupera")

	# Punto débil: cerrado durante la embestida
	await _until(func(): return boss.state == Boss.State.WINDUP or boss.state == Boss.State.CHARGE, 600)
	var hp := boss.health
	boss._on_weak_point_hurt(5, null)
	_check(boss.health == hp, "punto débil cerrado al embestir: no recibe daño")
	await _until(func(): return boss.is_weak_point_open(), 300)

	# Daño real: el jugador dispara desde el suelo al punto débil
	var bar_before := level.hud.boss_fill.size.x
	hp = boss.health
	player.weapon_holder.equip(load(OS.get_environment("BOSS_WEAPON") if OS.get_environment("BOSS_WEAPON") != "" else "res://resources/weapons/sardine_spread.tres"))
	for i in 240:
		_aim_at_boss()
		Input.action_press("shoot")
		await get_tree().physics_frame
	Input.action_release("shoot")
	_release_moves()
	_check(boss.health < hp, "disparos reales dañan el punto débil (%d → %d)" % [hp, boss.health])
	_check(level.hud.boss_fill.size.x < bar_before, "la barra del HUD baja")
	_check(boss.phase == 1 or boss.health <= boss.data.max_health * boss.data.phase2_health_ratio, "sigue en fase 1 si no bajó del umbral")

	# Fase 2
	var changed := [false]
	boss.phase_changed.connect(func(_p): changed[0] = true)
	var to_threshold := boss.health - int(boss.data.max_health * boss.data.phase2_health_ratio)
	if boss.phase == 1 and to_threshold >= 0:
		boss.take_damage(to_threshold)
	_check(boss.state == Boss.State.PHASE_CHANGE or boss.phase == 2, "al bajar de la mitad de vida cambia de fase")
	await _until(func(): return changed[0] or boss.phase == 2, 200)
	_check(boss.phase == 2 and boss.get_phase_data().charge_speed > boss.data.phase1.charge_speed, "fase 2: más rápida")
	var shells := [false]
	for i in 900:
		await get_tree().physics_frame
		if _enemy_bullets().any(func(b): return b.data.bullet_gravity > 0.0):
			shells[0] = true
			break
	_check(shells[0], "fase 2: nuevo ataque de mortero")

	# Muerte
	var defeated := [false]
	level.boss_defeated.connect(func(): defeated[0] = true)
	boss.take_damage(9999)
	_check(boss.state == Boss.State.DYING, "al llegar a 0 entra en secuencia de explosiones")
	await _until(func(): return defeated[0], 300)
	_check(defeated[0] and boss.state == Boss.State.DEAD and not boss.visible, "explota y queda derrotado")
	_check(not level.hud.boss_bar.visible and level.hud.message.visible, "se oculta la barra y aparece el mensaje de victoria")
	_check(_enemy_bullets().is_empty(), "se limpian las balas enemigas")
	print("BOSS TEST: %s (%d fallos)" % ["OK" if _failures == 0 else "FALLÓ", _failures])
	# Silenciar y esperar un poco: así el servidor de audio suelta los sonidos antes de salir
	AudioManager.stop_all()
	await _frames(5)
	get_tree().quit(1 if _failures > 0 else 0)


## Mira al jefe y se mantiene a distancia
func _aim_at_boss() -> void:
	_release_moves()
	var dx := boss.global_position.x - player.global_position.x
	var toward := "move_right" if dx > 0.0 else "move_left"
	var away := "move_left" if dx > 0.0 else "move_right"
	if absf(dx) > 120.0:
		Input.action_press(toward)
	elif absf(dx) < 70.0:
		Input.action_press(away)
		Input.action_press("lock_aim")
	player.facing = 1 if dx > 0.0 else -1
	player.aim = Vector2(player.facing, 0)


func _release_moves() -> void:
	for a in ["move_left", "move_right", "lock_aim"]:
		Input.action_release(a)


func _enemy_bullets() -> Array:
	return Bullet.get_projectile_root(self).get_children().filter(func(n): return n is Bullet and not n.from_player and not n._spent)


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
