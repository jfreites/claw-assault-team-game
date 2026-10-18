class_name Fx
extends RefCounted
## Efectos simples y reutilizables (partículas). Se pulen en la etapa 7.


## Ráfaga de partículas cuadradas que se autodestruye.
static func burst(context: Node, pos: Vector2, color: Color, amount := 10, speed := 80.0, lifetime := 0.35) -> void:
	if not context.is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = lifetime
	p.explosiveness = 1.0
	p.spread = 180.0
	p.direction = Vector2.UP
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 220)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = color
	p.position = pos
	p.finished.connect(p.queue_free)
	Bullet.get_projectile_root(context).add_child(p)
	p.emitting = true


## Explosión: dos ráfagas de color + sacudida de cámara.
static func explosion(context: Node, pos: Vector2, size := 1.0) -> void:
	burst(context, pos, Color(1.0, 0.85, 0.3), int(14 * size), 110.0 * size, 0.45)
	burst(context, pos, Color(1.0, 0.4, 0.15), int(8 * size), 70.0 * size, 0.35)
	GameCamera.shake_current(context, 1.5 * size, 0.15)
