class_name Hurtbox
extends Area2D
## Área que recibe daño. Cada frame de física revisa las Hitbox que la tocan
## (así el contacto continuo también cuenta al terminar la invulnerabilidad).

signal hurt(damage: int, source: Hitbox)

@export var active := true


func _ready() -> void:
	monitoring = true
	monitorable = false


func _physics_process(_delta: float) -> void:
	if not active:
		return
	for area in get_overlapping_areas():
		var hitbox := area as Hitbox
		if hitbox and hitbox.can_hit(self):
			hitbox.on_hit(self)
			hurt.emit(hitbox.damage, hitbox)
			if not active:
				return
