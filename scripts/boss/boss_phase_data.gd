class_name BossPhaseData
extends Resource
## Tiempos y patrones de una fase del jefe. Ajustar aquí la dificultad.

## Secuencia de ataques que se repite: "fan" (abanico), "charge" (embestida), "mortar" (mortero)
@export var pattern: PackedStringArray = ["fan", "charge"]
## Pausa entre ataques
@export var idle_time := 1.2
## Pausa tras chocar al embestir
@export var recover_time := 0.7

@export_group("Abanico")
@export var fan_weapon: WeaponData
@export var fan_volleys := 2
@export var volley_interval := 0.45

@export_group("Embestida")
## Aviso antes de embestir (el punto débil se cierra)
@export var charge_windup := 0.8
@export var charge_speed := 190.0

@export_group("Mortero")
@export var mortar_weapon: WeaponData
@export var mortar_count := 0
@export var mortar_interval := 0.25
## Segundos que tarda cada proyectil en caer
@export var mortar_flight_time := 1.0
## Ancho de la lluvia alrededor del jugador
@export var mortar_spread := 120.0
