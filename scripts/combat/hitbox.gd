class_name Hitbox
extends Area2D
## Área que causa daño: contacto de enemigos, balas y peligros (agua/abismo).
## Los Hurtbox la detectan; la Hitbox no necesita monitorear nada.

signal hit_landed(hurtbox: Hurtbox)

@export var damage := 1
## Mata sin importar invulnerabilidad ni escudos (abismo, agua)
@export var instant_kill := false


func _ready() -> void:
	monitoring = false
	monitorable = true


## ¿Puede dañar a este hurtbox ahora? (las balas perforantes lo usan para no repetir)
func can_hit(_hurtbox: Hurtbox) -> bool:
	return true


func on_hit(hurtbox: Hurtbox) -> void:
	hit_landed.emit(hurtbox)
