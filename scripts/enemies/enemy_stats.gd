class_name EnemyStats
extends Resource
## Parámetros de un tipo de enemigo (resources/enemies/*.tres).
## Cada subtipo usa solo los campos que le aplican.

@export var max_health := 1
@export var contact_damage := 1
@export var score := 100

@export_group("Movimiento")
@export var move_speed := 60.0
@export var gravity := 900.0
## Cada cuánto el corredor vuelve a mirar hacia el jugador
@export var think_interval := 1.2

@export_group("Disparo")
@export var weapon: WeaponData
@export var fire_interval := 2.0
@export var first_shot_delay := 0.8
@export var fire_range := 260.0
## Direcciones posibles al apuntar (16 = estilo Contra, 0 = libre)
@export var aim_directions := 16

@export_group("Vuelo")
@export var wave_amplitude := 20.0
## Ondas por segundo
@export var wave_frequency := 0.8

@export_group("Drop")
@export_range(0.0, 1.0) var drop_chance := 0.0
## WeaponData o PowerUpData posibles (etapa 4)
@export var drop_table: Array[Resource] = []
