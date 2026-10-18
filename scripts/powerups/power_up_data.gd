class_name PowerUpData
extends Resource
## Poder temporal data-driven. Poder nuevo = un .tres nuevo en resources/powerups/.
## Los modificadores se combinan si hay varios poderes activos.

@export var display_name := "Poder"
## Letra corta para el HUD
@export var hud_letter := "?"
## Segundos que dura (el escudo también termina al gastarse)
@export var duration := 10.0
## Carpeta del sprite del pickup relativa a assets/sprites
@export var pickup_sprite := "pickups/power_catnip"
@export var sfx := "power_up"
## Tinte del personaje mientras el poder está activo (blanco = sin tinte)
@export var tint := Color.WHITE

@export_group("Modificadores")
@export var speed_multiplier := 1.0
@export var fire_rate_multiplier := 1.0
@export var jump_multiplier := 1.0
@export var damage_multiplier := 1.0
## Golpes que absorbe el escudo (0 = sin escudo)
@export var shield_hits := 0
## Saltos extra en el aire (1 = salto doble)
@export var extra_air_jumps := 0
