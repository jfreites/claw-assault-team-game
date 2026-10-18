class_name BossData
extends Resource
## Parámetros generales del jefe y sus dos fases.

@export var display_name := "MECHA-DOG"
@export var max_health := 50
@export var contact_damage := 1
## Pasa a la fase 2 al bajar de esta fracción de salud
@export_range(0.0, 1.0) var phase2_health_ratio := 0.5
## Medio ancho del cuerpo (para no salirse de la arena)
@export var body_half_width := 30.0

@export_group("Tiempos")
@export var intro_roar_time := 1.0
@export var phase_change_time := 1.2
@export var death_time := 2.2
## Espera tras la explosión final antes de la pantalla de victoria
@export var victory_delay := 2.0

@export_group("Fases")
@export var phase1: BossPhaseData
@export var phase2: BossPhaseData
## Tinte del cuerpo en la fase 2 (más furioso)
@export var phase2_tint := Color(1, 0.7, 0.65)
