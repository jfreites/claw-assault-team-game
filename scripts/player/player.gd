class_name Player
extends CharacterBody2D
## Gato guerrero: máquina de estados, salto variable con coyote/buffer,
## apuntado en 8 direcciones y bajada por plataformas one-way.

signal died
signal state_changed(new_state: int)

enum State { IDLE, RUN, JUMP, FALL, PRONE, HURT, DEAD }

@export var config: PlayerConfig

## Multiplicadores que modifican los poderes temporales
var speed_multiplier := 1.0
var jump_multiplier := 1.0
var extra_air_jumps := 0
## Color que aplican los poderes activos; parpadea para que se note
var power_tint := Color.WHITE

var state: State = State.IDLE
var facing := 1
var aim := Vector2.RIGHT
var input_enabled := true

var _state_time := 0.0
var _coyote := 0.0
var _jump_buffer := 0.0
var _drop_time := 0.0
var _invulnerable := 0.0
var _jumped := false
var _air_jumps_used := 0
var _died_emitted := false

@onready var sprite: EntitySprite = $Sprite
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hurt_stand: CollisionShape2D = $Hurtbox/Stand
@onready var hurt_prone: CollisionShape2D = $Hurtbox/Prone
@onready var muzzles: Node2D = $Muzzles
@onready var weapon_holder: WeaponHolder = $WeaponHolder
@onready var powers: PowerUpController = $PowerUps
@onready var shield_sprite: EntitySprite = $ShieldSprite


func _ready() -> void:
	if config == null:
		config = PlayerConfig.new()
	add_to_group("player")
	hurtbox.hurt.connect(_on_hurtbox_hurt)


func _physics_process(delta: float) -> void:
	_state_time += delta
	_tick_timers(delta)
	match state:
		State.HURT:
			_physics_hurt(delta)
		State.DEAD:
			_physics_dead(delta)
		_:
			_physics_control(delta)
	_clamp_to_camera()
	_update_visuals()


# --- Control normal -------------------------------------------------------

func _physics_control(delta: float) -> void:
	var h := _input_h()
	var up := _pressed("move_up")
	var down := _pressed("crouch")
	var lock := _pressed("lock_aim")
	var on_floor := is_on_floor()

	if on_floor:
		_coyote = config.coyote_time
		_air_jumps_used = 0
	if _just_pressed("jump"):
		_jump_buffer = config.jump_buffer_time

	# Echarse: abajo en el suelo sin moverse (no aplica con la dirección fijada)
	var want_prone := on_floor and down and h == 0 and not lock

	if _jump_buffer > 0.0:
		if on_floor and down and _standing_on_one_way():
			_start_drop()
		elif _coyote > 0.0:
			_do_jump()
		elif _air_jumps_used < extra_air_jumps:
			_air_jumps_used += 1
			_do_jump()
	# Salto variable: soltar el botón corta la subida
	if _just_released("jump") and _jumped and velocity.y < 0.0:
		velocity.y *= config.jump_cut_multiplier

	var target_speed := 0.0 if want_prone else h * config.run_speed * speed_multiplier
	velocity.x = move_toward(velocity.x, target_speed, config.acceleration * delta)
	velocity.y = minf(velocity.y + config.gravity * delta, config.max_fall_speed)

	# Con lock_aim se conserva la dirección de disparo mientras se camina
	if not lock:
		if h != 0:
			facing = h
		aim = _compute_aim(h, up, down, on_floor)

	move_and_slide()

	if _pressed("shoot"):
		weapon_holder.try_fire(get_muzzle_position(), aim)
	if _just_pressed("debug_next_weapon"):
		weapon_holder.cycle_debug_weapon()

	if is_on_floor():
		_jumped = false
		if want_prone:
			_set_state(State.PRONE)
		elif h != 0:
			_set_state(State.RUN)
		else:
			_set_state(State.IDLE)
	else:
		_set_state(State.JUMP if _jumped else State.FALL)


func _compute_aim(h: int, up: bool, down: bool, on_floor: bool) -> Vector2:
	var y := 0.0
	if up:
		y = -1.0
	elif down and not (on_floor and h == 0):
		# Abajo recto solo en el aire; en el suelo abajo+lado = diagonal
		y = 1.0
	if y != 0.0 and h == 0:
		return Vector2(0, y)
	var x := float(h if h != 0 else facing)
	return Vector2(x, y).normalized()


func _do_jump() -> void:
	velocity.y = config.jump_velocity * jump_multiplier
	_jumped = true
	_coyote = 0.0
	_jump_buffer = 0.0
	AudioManager.play_sfx("jump")


func _start_drop() -> void:
	collision_mask &= ~Layers.ONE_WAY
	_drop_time = config.drop_through_time
	_jump_buffer = 0.0
	position.y += 1.0


func _standing_on_one_way() -> bool:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col.get_normal().y < -0.5:
			if PhysicsServer2D.body_get_collision_layer(col.get_collider_rid()) & Layers.ONE_WAY:
				return true
	return false


# --- Daño y muerte --------------------------------------------------------

func _on_hurtbox_hurt(_damage: int, source: Hitbox) -> void:
	if not is_alive():
		return
	var lethal := source != null and source.instant_kill
	if not lethal and _invulnerable > 0.0:
		return
	# Escudo (leche): absorbe el golpe y da un respiro
	if not lethal and powers.absorb_hit():
		start_invulnerability(config.shield_break_invulnerability)
		GameCamera.shake_current(self, 2.0, 0.15)
		return
	kill(lethal)


## Un golpe = una vida. `instant` salta la animación de golpe (abismo/agua).
func kill(instant := false) -> void:
	if not is_alive():
		return
	hurtbox.active = false
	powers.clear()
	AudioManager.play_sfx("player_hurt")
	GameCamera.shake_current(self, 3.0, 0.25)
	if instant:
		velocity = Vector2.ZERO
		_set_state(State.DEAD)
	else:
		velocity = Vector2(config.hurt_knockback.x * facing, config.hurt_knockback.y)
		_set_state(State.HURT)


func _physics_hurt(delta: float) -> void:
	velocity.y = minf(velocity.y + config.gravity * delta, config.max_fall_speed)
	move_and_slide()
	if _state_time >= config.hurt_time and (is_on_floor() or _state_time >= config.hurt_time * 3.0):
		_set_state(State.DEAD)


func _physics_dead(delta: float) -> void:
	velocity.x = 0.0
	velocity.y = minf(velocity.y + config.gravity * delta, config.max_fall_speed)
	move_and_slide()
	if not _died_emitted and _state_time >= config.dead_time:
		_died_emitted = true
		died.emit()


## Aplica el contenido de un pickup: arma nueva o poder temporal
func collect(item: Resource) -> void:
	if item is WeaponData:
		weapon_holder.equip(item)
		AudioManager.play_sfx("pickup_weapon")
	elif item is PowerUpData:
		powers.activate(item)


func start_invulnerability(duration := -1.0) -> void:
	_invulnerable = config.respawn_invulnerability if duration < 0.0 else duration


func is_invulnerable() -> bool:
	return _invulnerable > 0.0


func is_alive() -> bool:
	return state != State.HURT and state != State.DEAD


## Punto al que apuntan los enemigos
func get_aim_point() -> Vector2:
	return global_position + (Vector2(0, -5) if state == State.PRONE else Vector2(0, -14))


## Punto de disparo según estado y dirección (Marker2D configurables en la escena)
func get_muzzle_position() -> Vector2:
	var marker_name := "Forward"
	if state == State.JUMP:
		# En el salto (bola) se dispara desde el centro hacia la dirección de apuntado
		var air := muzzles.get_node_or_null("Air") as Marker2D
		return global_position + (air.position if air else Vector2(0, -14)) + aim * 8.0
	elif state == State.PRONE:
		marker_name = "Prone"
	elif aim.y < -0.9:
		marker_name = "Up"
	elif aim.y > 0.9:
		marker_name = "Down"
	elif aim.y < 0.0:
		marker_name = "UpForward"
	elif aim.y > 0.0:
		marker_name = "DownForward"
	elif state == State.RUN:
		marker_name = "Run"
	var marker := muzzles.get_node_or_null(marker_name) as Marker2D
	var local := marker.position if marker else Vector2(12, -14)
	local.x *= facing
	return global_position + local


# --- Estado y visuales ----------------------------------------------------

func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	_state_time = 0.0
	# Echado: hurtbox bajo y ancho
	hurt_stand.set_deferred("disabled", new_state == State.PRONE)
	hurt_prone.set_deferred("disabled", new_state != State.PRONE)
	state_changed.emit(new_state)


func _update_visuals() -> void:
	sprite.flip_h = facing < 0
	match state:
		State.IDLE:
			sprite.play_safe(&"aim_up" if aim.y < -0.9 else &"idle", &"idle")
		State.RUN:
			if aim.y < -0.1:
				sprite.play_safe(&"run_aim_up", &"run")
			elif aim.y > 0.1:
				sprite.play_safe(&"run_aim_down", &"run")
			else:
				sprite.play_safe(&"run")
		State.JUMP:
			sprite.play_safe(&"jump")
		State.FALL:
			sprite.play_safe(&"fall", &"jump")
		State.PRONE:
			sprite.play_safe(&"prone", &"idle")
		State.HURT:
			sprite.play_safe(&"hurt", &"jump")
		State.DEAD:
			sprite.play_safe(&"dead", &"prone")
	shield_sprite.visible = powers.shield_hits > 0 and is_alive()
	if power_tint != Color.WHITE:
		sprite.modulate = power_tint if int(Time.get_ticks_msec() / 120.0) % 2 == 0 else power_tint.lerp(Color.WHITE, 0.5)
	else:
		sprite.modulate = Color.WHITE
	# Parpadeo durante la invulnerabilidad
	sprite.visible = _invulnerable <= 0.0 or int(_invulnerable * 20.0) % 2 == 0


func _tick_timers(delta: float) -> void:
	_coyote = maxf(_coyote - delta, 0.0)
	_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	if _drop_time > 0.0:
		_drop_time -= delta
		if _drop_time <= 0.0:
			collision_mask |= Layers.ONE_WAY


func _clamp_to_camera() -> void:
	var cam := get_viewport().get_camera_2d() as GameCamera
	if cam == null:
		return
	var rect := cam.get_view_rect()
	var min_x := rect.position.x + cam.edge_margin
	var max_x := rect.end.x - cam.edge_margin
	if global_position.x < min_x:
		global_position.x = min_x
		velocity.x = maxf(velocity.x, 0.0)
	elif global_position.x > max_x:
		global_position.x = max_x
		velocity.x = minf(velocity.x, 0.0)


# --- Input ----------------------------------------------------------------

func _input_h() -> int:
	if not input_enabled:
		return 0
	return int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))


func _pressed(action: StringName) -> bool:
	return input_enabled and Input.is_action_pressed(action)


func _just_pressed(action: StringName) -> bool:
	return input_enabled and Input.is_action_just_pressed(action)


func _just_released(action: StringName) -> bool:
	return input_enabled and Input.is_action_just_released(action)
