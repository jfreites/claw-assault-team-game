class_name GameCamera
extends Camera2D
## Cámara de run & gun: solo avanza hacia la derecha, puede bloquearse
## (arena del jefe) y tiene un screen shake simple.

## El jugador queda un poco a la izquierda del centro de la pantalla
@export var follow_offset_x := 24.0
## Distancia mínima del jugador a los bordes de la pantalla
@export var edge_margin := 6.0

var target: Node2D

var _max_x := -INF
var _locked := false
var _lock_x := 0.0
var _shake_strength := 0.0
var _shake_duration := 0.0
var _shake_time := 0.0


func _ready() -> void:
	add_to_group("game_camera")
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	make_current()


func _physics_process(delta: float) -> void:
	if target and not _locked:
		_max_x = maxf(_max_x, target.global_position.x + follow_offset_x)
	_update_position()
	_update_shake(delta)


## Coloca la cámara de golpe sobre el objetivo (al aparecer)
func snap_to_target() -> void:
	if target:
		_max_x = target.global_position.x + follow_offset_x
	_update_position()
	reset_smoothing()


## Bloquea la cámara centrada en `center_x` (arena del jefe)
func lock_at_x(center_x: float) -> void:
	_locked = true
	_lock_x = center_x


func unlock() -> void:
	_locked = false
	_max_x = maxf(_max_x, _lock_x)


func is_locked() -> bool:
	return _locked


func get_view_size() -> Vector2:
	return get_viewport_rect().size / zoom


## Rectángulo visible en coordenadas del mundo (sin contar el shake)
func get_view_rect() -> Rect2:
	var size := get_view_size()
	return Rect2(global_position - size * 0.5, size)


func shake(strength: float, duration: float) -> void:
	if strength >= _shake_strength * (_shake_time / maxf(_shake_duration, 0.001)):
		_shake_strength = strength
		_shake_duration = duration
		_shake_time = duration


## Atajo para sacudir la cámara activa desde cualquier nodo
static func shake_current(from: Node, strength: float, duration: float) -> void:
	var cam := from.get_viewport().get_camera_2d() as GameCamera
	if cam:
		cam.shake(strength, duration)


func _update_position() -> void:
	var half := get_view_size() * 0.5
	var x := _lock_x if _locked else _max_x
	if x == -INF:
		x = global_position.x
	x = clampf(x, limit_left + half.x, maxf(limit_right - half.x, limit_left + half.x))
	var y := clampf(global_position.y, limit_top + half.y, maxf(limit_bottom - half.y, limit_top + half.y))
	global_position = Vector2(x, y).round()


func _update_shake(delta: float) -> void:
	if _shake_time <= 0.0:
		offset = Vector2.ZERO
		return
	_shake_time -= delta
	var k := clampf(_shake_time / maxf(_shake_duration, 0.001), 0.0, 1.0)
	offset = (Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_strength * k).round()
