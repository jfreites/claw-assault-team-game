class_name PlayerConfig
extends Resource
## Parámetros del jugador. Se ajustan en resources/player/player_config.tres.

@export_group("Movimiento")
@export var run_speed := 90.0
@export var acceleration := 1600.0
@export var gravity := 900.0
@export var max_fall_speed := 380.0

@export_group("Salto")
@export var jump_velocity := -320.0
## Multiplicador de la velocidad vertical al soltar el botón (salto variable)
@export_range(0.0, 1.0) var jump_cut_multiplier := 0.4
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.1
## Tiempo que se ignoran las plataformas one-way al bajar por ellas
@export var drop_through_time := 0.25

@export_group("Daño")
@export var hurt_time := 0.45
@export var hurt_knockback := Vector2(-70, -220)
@export var dead_time := 1.2
@export var respawn_invulnerability := 2.0
## Invulnerabilidad breve cuando el escudo absorbe un golpe
@export var shield_break_invulnerability := 1.0
