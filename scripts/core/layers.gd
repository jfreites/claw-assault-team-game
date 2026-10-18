class_name Layers
extends RefCounted
## Capas de colisión con nombre (Project Settings > Layer Names > 2D Physics).
## Bits listos para usar en collision_layer / collision_mask.

const WORLD := 1 << 0          # 1  suelo y paredes sólidas
const PLAYER := 1 << 1         # 2  cuerpo y hurtbox del jugador
const ENEMY := 1 << 2          # 4  cuerpos, hurtbox y contacto de enemigos
const PLAYER_BULLET := 1 << 3  # 8  balas del jugador
const ENEMY_BULLET := 1 << 4   # 16 balas enemigas
const PICKUP := 1 << 5         # 32 pickups y cápsulas
const HAZARD := 1 << 6         # 64 agua / abismo (muerte instantánea)
const ONE_WAY := 1 << 7        # 128 plataformas atravesables hacia abajo
