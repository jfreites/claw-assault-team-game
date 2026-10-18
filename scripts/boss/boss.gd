class_name Boss
extends CharacterBody2D
## Jefe del nivel 1: perro mecha. Máquina de estados con dos fases por salud.
## Solo el punto débil (Area2D aparte) recibe daño; la armadura detiene las balas.
## Tiempos y patrones en BossData / BossPhaseData (resources/boss/).

signal health_changed(current: int, max_health: int)
signal phase_changed(phase: int)
signal defeated

enum State { DORMANT, INTRO, IDLE, FAN, WINDUP, CHARGE, RECOVER, MORTAR, PHASE_CHANGE, DYING, DEAD }

const FLASH_SHADER := preload("res://resources/shaders/hit_flash.gdshader")
const GRAVITY := 900.0
const FLASH_TIME := 0.06
## Estados en los que el punto débil está cerrado (blindado)
const CLOSED_STATES := [State.DORMANT, State.INTRO, State.WINDUP, State.CHARGE, State.PHASE_CHANGE, State.DYING, State.DEAD]

@export var data: BossData

var state: State = State.DORMANT
var phase := 1
var health := 1
var facing := -1
var arena := Rect2()

var _t := 0.0
var _landed := false
var _pattern_index := 0
var _shots := 0
var _shot_timer := 0.0
var _flash := 0.0
var _flash_material: ShaderMaterial
var _base_x: Dictionary = {}

@onready var sprite: EntitySprite = $Sprite
@onready var weak_sprite: EntitySprite = $WeakPointSprite
@onready var weak_point: Hurtbox = $WeakPoint
@onready var armor: Hurtbox = $Armor
@onready var contact: Hitbox = $ContactHitbox
@onready var muzzle: Marker2D = $Muzzle
@onready var mortar_muzzle: Marker2D = $MortarMuzzle


func _ready() -> void:
	add_to_group("boss")
	health = data.max_health
	collision_layer = Layers.ENEMY
	collision_mask = Layers.WORLD
	for hb: Hurtbox in [weak_point, armor]:
		hb.collision_layer = Layers.ENEMY
		hb.collision_mask = Layers.PLAYER_BULLET
	weak_point.hurt.connect(_on_weak_point_hurt)
	armor.hurt.connect(_on_armor_hurt)
	contact.collision_layer = Layers.ENEMY
	contact.collision_mask = 0
	contact.damage = data.contact_damage
	# Las piezas asimétricas se espejan a mano según hacia dónde mira
	for node: Node2D in [weak_point, weak_sprite, muzzle, mortar_muzzle]:
		_base_x[node] = node.position.x
	_flash_material = ShaderMaterial.new()
	_flash_material.shader = FLASH_SHADER
	sprite.material = _flash_material
	visible = false
	_set_combat_enabled(false)
	_apply_facing()


## Lo llama el nivel al entrar a la arena: el perro cae desde arriba de la pantalla
func awaken(arena_rect: Rect2) -> void:
	if state != State.DORMANT:
		return
	arena = arena_rect
	global_position.y = arena.position.y - 60.0
	velocity = Vector2.ZERO
	visible = true
	_set_state(State.INTRO)
	health_changed.emit(health, data.max_health)


func get_phase_data() -> BossPhaseData:
	return data.phase2 if phase == 2 else data.phase1


func is_weak_point_open() -> bool:
	return not state in CLOSED_STATES


func _physics_process(delta: float) -> void:
	_update_flash(delta)
	if state == State.DORMANT or state == State.DEAD:
		return
	_t += delta
	match state:
		State.INTRO: _state_intro()
		State.IDLE: _state_idle()
		State.FAN: _state_fan(delta)
		State.WINDUP: _state_windup()
		State.CHARGE: _state_charge()
		State.RECOVER: _state_recover()
		State.MORTAR: _state_mortar(delta)
		State.PHASE_CHANGE: _state_phase_change()
		State.DYING: _state_dying(delta)
	velocity.y = minf(velocity.y + GRAVITY * delta, 600.0)
	move_and_slide()
	_clamp_to_arena()
	_update_visuals()


# --- Estados --------------------------------------------------------------

func _state_intro() -> void:
	velocity.x = 0.0
	if not _landed and is_on_floor():
		_landed = true
		_t = 0.0
		GameCamera.shake_current(self, 5.0, 0.4)
		AudioManager.play_sfx("boss_land")
		Fx.burst(self, global_position, Color(0.8, 0.75, 0.6), 18, 100.0, 0.5)
	elif _landed and _t >= data.intro_roar_time:
		_set_combat_enabled(true)
		_set_state(State.IDLE)


func _state_idle() -> void:
	velocity.x = 0.0
	_face_player()
	if _t >= get_phase_data().idle_time:
		_next_attack()


func _next_attack() -> void:
	var pattern := get_phase_data().pattern
	if pattern.is_empty():
		_set_state(State.IDLE)
		return
	var attack := pattern[_pattern_index % pattern.size()]
	_pattern_index += 1
	match attack:
		"fan": _set_state(State.FAN)
		"charge": _set_state(State.WINDUP)
		"mortar": _set_state(State.MORTAR if get_phase_data().mortar_weapon else State.FAN)
		_: _set_state(State.IDLE)


func _state_fan(delta: float) -> void:
	var p := get_phase_data()
	_shot_timer -= delta
	if _shot_timer > 0.0:
		return
	if _shots >= p.fan_volleys:
		_set_state(State.IDLE)
		return
	_shots += 1
	_shot_timer = p.volley_interval
	_face_player()
	Bullet.spawn_pattern(p.fan_weapon, muzzle.global_position, _dir_to_player(muzzle.global_position), false, self)


func _state_windup() -> void:
	velocity.x = 0.0
	if _t >= get_phase_data().charge_windup:
		AudioManager.play_sfx("boss_charge")
		_set_state(State.CHARGE)


func _state_charge() -> void:
	velocity.x = facing * get_phase_data().charge_speed
	var at_edge := (facing < 0 and global_position.x <= arena.position.x + data.body_half_width + 1.0) \
		or (facing > 0 and global_position.x >= arena.end.x - data.body_half_width - 1.0)
	if at_edge or is_on_wall():
		velocity.x = 0.0
		GameCamera.shake_current(self, 4.0, 0.3)
		AudioManager.play_sfx("boss_crash")
		Fx.burst(self, global_position + Vector2(facing * data.body_half_width, -16), Color(1, 0.9, 0.5), 12, 90.0, 0.35)
		_set_state(State.RECOVER)


func _state_recover() -> void:
	velocity.x = 0.0
	if _t >= get_phase_data().recover_time:
		_face_player()
		_set_state(State.IDLE)


func _state_mortar(delta: float) -> void:
	var p := get_phase_data()
	velocity.x = 0.0
	_shot_timer -= delta
	if _shot_timer > 0.0:
		return
	if _shots >= p.mortar_count:
		_set_state(State.IDLE)
		return
	# Cada proyectil cae en un punto distinto alrededor del jugador
	var player := _player()
	var center_x := player.global_position.x if player else arena.get_center().x
	var k := float(_shots) / maxf(p.mortar_count - 1, 1)
	var target := Vector2(center_x + lerpf(-0.5, 0.5, k) * p.mortar_spread, arena.end.y - 24.0)
	target.x = clampf(target.x, arena.position.x + 8.0, arena.end.x - 8.0)
	_shots += 1
	_shot_timer = p.mortar_interval
	_fire_mortar(p, target)


func _fire_mortar(p: BossPhaseData, target: Vector2) -> void:
	var origin := mortar_muzzle.global_position
	var flight := p.mortar_flight_time
	var g := p.mortar_weapon.bullet_gravity
	# Tiro parabólico: velocidad inicial para llegar a `target` en `flight` segundos
	var v := Vector2((target.x - origin.x) / flight, (target.y - origin.y - 0.5 * g * flight * flight) / flight)
	for bullet in Bullet.spawn_pattern(p.mortar_weapon, origin, Vector2.UP, false, self):
		bullet.velocity = v


func _state_phase_change() -> void:
	velocity.x = 0.0
	if _t >= data.phase_change_time:
		phase = 2
		_pattern_index = 0
		sprite.modulate = data.phase2_tint
		phase_changed.emit(phase)
		_set_state(State.IDLE)


func _state_dying(delta: float) -> void:
	velocity.x = 0.0
	_shot_timer -= delta
	if _shot_timer <= 0.0:
		_shot_timer = 0.12
		var spot := global_position + Vector2(randf_range(-30, 30), randf_range(-44, -4))
		Fx.explosion(self, spot, 0.8)
		AudioManager.play_sfx("explosion")
	if _t >= data.death_time:
		Fx.explosion(self, global_position + Vector2(0, -22), 3.0)
		GameCamera.shake_current(self, 8.0, 0.6)
		AudioManager.play_sfx("boss_explode")
		visible = false
		_set_state(State.DEAD)
		defeated.emit()


# --- Daño -----------------------------------------------------------------

func _on_weak_point_hurt(damage: int, source: Hitbox) -> void:
	if not is_weak_point_open():
		_on_armor_hurt(damage, source)
		return
	take_damage(damage)


func _on_armor_hurt(_damage: int, source: Hitbox) -> void:
	# La armadura detiene la bala: chispa y sonido metálico
	AudioManager.play_sfx("armor_hit")
	if source:
		Fx.burst(self, source.global_position, Color(0.85, 0.9, 1.0), 3, 40.0, 0.15)


func take_damage(amount: int) -> void:
	if state == State.DYING or state == State.DEAD:
		return
	health = maxi(health - amount, 0)
	_flash = FLASH_TIME
	health_changed.emit(health, data.max_health)
	AudioManager.play_sfx("boss_hit")
	if health <= 0:
		_start_dying()
	elif phase == 1 and state != State.PHASE_CHANGE and health <= data.max_health * data.phase2_health_ratio:
		AudioManager.play_sfx("boss_roar")
		GameCamera.shake_current(self, 4.0, 0.5)
		_set_state(State.PHASE_CHANGE)


func _start_dying() -> void:
	_set_combat_enabled(false)
	# Fuera las balas enemigas para que la victoria sea limpia
	for node in Bullet.get_projectile_root(self).get_children():
		if node is Bullet and not node.from_player:
			node.queue_free()
	_set_state(State.DYING)


# --- Utilidades -----------------------------------------------------------

func _set_state(new_state: State) -> void:
	state = new_state
	_t = 0.0
	_shots = 0
	_shot_timer = 0.0


func _set_combat_enabled(enabled: bool) -> void:
	weak_point.active = enabled
	armor.active = enabled
	contact.set_deferred("monitorable", enabled)


func _player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func _face_player() -> void:
	var p := _player()
	if p:
		var new_facing := -1 if p.global_position.x < global_position.x else 1
		if new_facing != facing:
			facing = new_facing
			_apply_facing()


func _dir_to_player(from: Vector2) -> Vector2:
	var p := _player()
	return (p.get_aim_point() - from).normalized() if p else Vector2(facing, 0)


func _apply_facing() -> void:
	sprite.flip_h = facing < 0
	weak_sprite.flip_h = facing < 0
	for node: Node2D in _base_x:
		node.position.x = _base_x[node] * facing


func _clamp_to_arena() -> void:
	if arena.size.x <= 0.0:
		return
	global_position.x = clampf(global_position.x, arena.position.x + data.body_half_width, arena.end.x - data.body_half_width)


func _update_flash(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(_flash - delta, 0.0)
	_flash_material.set_shader_parameter("flash", 1.0 if _flash > 0.0 else 0.0)


func _update_visuals() -> void:
	match state:
		State.INTRO:
			sprite.play_safe(&"roar" if _landed else &"idle", &"idle")
		State.IDLE, State.RECOVER:
			sprite.play_safe(&"idle")
		State.FAN:
			sprite.play_safe(&"fire", &"idle")
		State.WINDUP:
			sprite.play_safe(&"windup", &"idle")
		State.CHARGE:
			sprite.play_safe(&"charge", &"idle")
		State.MORTAR:
			sprite.play_safe(&"mortar", &"fire")
		State.PHASE_CHANGE:
			sprite.play_safe(&"roar", &"idle")
		State.DYING:
			sprite.play_safe(&"dying", &"idle")
	weak_sprite.visible = visible and state != State.DYING
	weak_sprite.play_safe(&"open" if is_weak_point_open() else &"closed", &"open")
	# Aviso de embestida: parpadeo
	if state == State.WINDUP:
		sprite.visible = int(_t * 16.0) % 2 == 0
	else:
		sprite.visible = true
