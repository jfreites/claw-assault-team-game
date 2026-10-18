class_name WeaponData
extends Resource
## Definición data-driven de un arma. Arma nueva = un .tres nuevo en resources/weapons/.

enum Pattern { SINGLE, SPREAD, BOUNCE, PIERCE }

@export var display_name := "Arma"
## Letra corta para el HUD y los pickups
@export var hud_letter := "H"
@export var pattern: Pattern = Pattern.SINGLE
## Carpeta del sprite del pickup relativa a assets/sprites
@export var pickup_sprite := "pickups/weapon_hairball"

@export_group("Disparo")
## Disparos por segundo manteniendo el botón
@export_range(0.5, 30.0, 0.1) var fire_rate := 6.0
@export var damage := 1
@export var bullet_speed := 260.0
## Segundos antes de desaparecer
@export var lifetime := 1.2
## Máximo de balas propias en pantalla (0 = sin límite)
@export var max_on_screen := 0
@export var sfx := "shoot"

@export_group("Bala")
@export var bullet_scene: PackedScene
## Carpeta del sprite relativa a assets/sprites
@export var bullet_sprite := "projectiles/hairball"
## Radio del hitbox (independiente del arte)
@export var hit_radius := 3.0
@export var rotate_sprite := true
@export var bullet_gravity := 0.0

@export_group("Spread")
@export var spread_count := 3
## Apertura total del abanico en grados
@export var spread_angle := 30.0

@export_group("Rebote")
@export var max_bounces := 3
@export_range(0.0, 1.0) var bounce_damping := 0.85

@export_group("Perforante")
## Enemigos que atraviesa antes de desaparecer (-1 = infinitos)
@export var pierce_count := -1
