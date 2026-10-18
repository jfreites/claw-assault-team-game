# Guía de arte (ASSETS)

Todo el arte se carga **por convención de nombres**. Si dejas un PNG real con el mismo nombre que el placeholder, el juego lo usa automáticamente: no hay que tocar código ni escenas.

La especificación de cada entidad (tamaño, animaciones, fps, anclaje) vive en un solo lugar: [`scripts/art/sprite_catalog.gd`](scripts/art/sprite_catalog.gd). Ese archivo lo leen tanto el juego (`SpriteLoader`) como el generador de placeholders.

## Reglas generales

| Regla | Valor |
|---|---|
| Resolución del juego | 384×216, escalado entero, filtro **Nearest** |
| Formato | PNG con transparencia (RGBA) |
| Orientación | **Todo el arte mira a la DERECHA**. El código voltea con `flip_h`. |
| Anclaje `feet` | Origen en los pies, centrado en X (personajes, enemigos de suelo, torretas) |
| Anclaje `center` | Origen en el centro del frame (balas, voladores) |
| Hitboxes | Son `CollisionShape2D` fijas en cada escena. **No dependen del tamaño del arte.** |
| Punto de disparo | `Marker2D` en la escena (`Muzzles/*` del jugador, `Muzzle` de enemigos), no en el sprite |

El anclaje se calcula con el tamaño real del primer frame de la animación por defecto, así que si tu arte es más grande que el placeholder igual queda parado sobre el suelo.

## Dos formas de entregar una animación

**A. Frames sueltos** (lo que genera el placeholder):
```
assets/sprites/player/run_0.png
assets/sprites/player/run_1.png
...
```
Se cargan en orden desde `_0` hasta el primer número que falte.

**B. Hoja horizontal** (tiene prioridad sobre los frames sueltos):
```
assets/sprites/player/run.png      ← frames en una fila, todos del mismo tamaño
assets/sprites/player/run.json     ← opcional
```
Sin JSON se usa el ancho de frame del catálogo y el alto de la imagen; el número de frames es `ancho_hoja / ancho_frame`. El JSON puede sobrescribir cualquier cosa:
```json
{ "frame_width": 48, "frame_height": 48, "frames": 6, "fps": 12, "loop": true }
```
> Si exportas el juego, agrega `*.json` a los filtros de recursos no-recurso del preset de exportación.

Las animaciones que no están en el catálogo también se detectan (por ejemplo `taunt_0.png`), aunque el código solo reproduce las que conoce.

## Entidades

### Jugador — `assets/sprites/player/`
Frame **32×32**, anclaje `feet`.

| Animación | Frames sug. | FPS | Loop | Notas |
|---|---|---|---|---|
| `idle` | 2 | 4 | sí | De pie, apuntando al frente |
| `aim_up` | 2 | 4 | sí | De pie apuntando arriba (opcional → usa `idle`) |
| `run` | 6 | 12 | sí | **A cuatro patas**, distinta de idle |
| `run_aim_up` | 6 | 12 | sí | Corriendo y apuntando en diagonal arriba (opcional → `run`) |
| `run_aim_down` | 6 | 12 | sí | Corriendo y apuntando en diagonal abajo (opcional → `run`) |
| `jump` | 4 | 14 | sí | Bola/voltereta estilo Contra |
| `fall` | 2 | 8 | sí | Caída sin haber saltado (opcional → `jump`) |
| `prone` | 1 | 1 | sí | Echado en el suelo |
| `hurt` | 2 | 8 | sí | Golpeado, sale despedido (opcional → `jump`) |
| `dead` | 1 | 1 | no | Tirado en el suelo (opcional → `prone`) |

Hitboxes fijas (escena `scenes/player/player.tscn`): cuerpo 12×24; hurtbox de pie 10×22; hurtbox echado 22×8.
Puntos de disparo (`Muzzles/`, coordenadas mirando a la derecha, el código las espeja):

| Marker2D | Posición | Cuándo |
|---|---|---|
| `Forward` | (14, -16) | De pie, al frente |
| `Run` | (16, -10) | Corriendo, al frente |
| `Up` | (2, -32) | Arriba |
| `UpForward` | (13, -24) | Diagonal arriba |
| `DownForward` | (13, -5) | Diagonal abajo |
| `Down` | (0, 0) | Abajo (solo en el aire) |
| `Prone` | (17, -4) | Echado |
| `Air` | (0, -14) | Durante el salto (bola) |

### Enemigos — `assets/sprites/enemies/<tipo>/`

| Entidad | Frame | Anclaje | Animaciones (frames @ fps) | Muzzle (escena) |
|---|---|---|---|---|
| `enemies/runner` | 24×28 | feet | `run` (4 @ 10), `fall` (1, opcional → `run`) | — |
| `enemies/turret` | 24×24 | feet | `idle` (1), `fire` (2 @ 10, sin loop) | `Muzzle` (0, -12) |
| `enemies/flyer` | 28×18 | center | `fly` (2 @ 8) | `Muzzle` (0, 6) |

### Proyectiles — `assets/sprites/projectiles/<nombre>/`
Anclaje `center`, animación `fly`. Las balas con `rotate_sprite = true` en su `WeaponData` se rotan hacia la dirección de vuelo (dibújalas apuntando a la derecha).

| Entidad | Frame | Frames @ fps | Usada por |
|---|---|---|---|
| `projectiles/hairball` | 6×6 | 2 @ 12 | Bola de pelo |
| `projectiles/yarn` | 8×8 | 4 @ 12 | Estambre |
| `projectiles/fishbone` | 14×6 | 1 | Espina de pescado (rota) |
| `projectiles/sardine` | 7×7 | 2 @ 12 | Sardinas (spread, rota) |
| `projectiles/enemy_shot` | 5×5 | 2 @ 10 | Torreta |
| `projectiles/enemy_bomb` | 7×7 | 2 @ 8 | Volador |

El radio del hitbox de cada bala es `hit_radius` en su `WeaponData`, independiente del arte.

### Tiles — `assets/sprites/tiles/tileset.png`
Tira horizontal de tiles de **16×16** en este orden (índice = columna):

| Índice | Tile | Colisión |
|---|---|---|
| 0 | Suelo con superficie (pasto) | sólido (world) |
| 1 | Relleno de tierra | sólido (world) |
| 2 | Plataforma one-way | 4 px superiores, one-way |
| 3 | Superficie de agua | ninguna (zona mortal) |
| 4 | Agua profunda | ninguna |
| 5 | Arena con superficie (playa) | sólido (world) |
| 6 | Relleno de arena | sólido (world) |

Si tu tileset trae menos tiles, solo se crean los que existen.

El `TileSet` se construye en código (`scripts/levels/tileset_factory.gd`), así que basta con reemplazar el PNG.

### Pickups y cápsula — `assets/sprites/pickups/<nombre>/`
Anclaje `center`. El sprite de cada pickup lo indica el campo `pickup_sprite` de su `WeaponData` / `PowerUpData`, así que un arma o poder nuevo puede traer su propio ícono.

| Entidad | Frame | Animación | Contenido |
|---|---|---|---|
| `pickups/capsule` | 26×16 | `fly` (2 @ 8) | Cápsula voladora (hitbox 22×14) |
| `pickups/weapon_hairball` | 16×14 | `idle` (2 @ 4) | Bola de pelo |
| `pickups/weapon_yarn` | 16×14 | `idle` (2 @ 4) | Estambre |
| `pickups/weapon_fishbone` | 16×14 | `idle` (2 @ 4) | Espina de pescado |
| `pickups/weapon_sardine` | 16×14 | `idle` (2 @ 4) | Sardinas |
| `pickups/power_catnip` | 16×14 | `idle` (2 @ 4) | Catnip |
| `pickups/power_milk` | 16×14 | `idle` (2 @ 4) | Leche |

Hitbox del pickup: 14×14 fijo (`scenes/pickups/pickup.tscn`).

### Fondos — `assets/sprites/backgrounds/`
Imágenes sueltas de **384×216** (una pantalla) que se repiten en horizontal. Las rutas y velocidades están en el nodo `Backdrop` (`ParallaxBackdrop`) de cada nivel.

| Archivo | Factor de scroll | Contenido |
|---|---|---|
| `far.png` | 0.15 | Cielo, sol, islas lejanas, mar (opaca) |
| `near.png` | 0.45 | Palmeras y arbustos (transparente arriba) |

El borde izquierdo y el derecho deben empalmar para que la repetición no se note.

### Props — `assets/sprites/props/<nombre>/`

| Entidad | Frame | Anclaje | Animaciones | Uso |
|---|---|---|---|---|
| `props/checkpoint` | 16×32 | feet | `idle` (1, bandera abajo), `active` (2 @ 6, izada) | Checkpoint (hitbox 16×64) |

### Efectos — `assets/sprites/fx/<nombre>/`

| Entidad | Frame | Anclaje | Animación | Uso |
|---|---|---|---|---|
| `fx/shield` | 32×32 | center | `idle` (4 @ 10) | Burbuja del escudo de leche, centrada en (0, -13) del jugador |

### Pendientes (etapas siguientes)
`boss/` y `ui/` se documentarán cuando se construyan esas etapas.

## Capas de colisión

Definidas con nombre en *Project Settings → Layer Names → 2D Physics* y como constantes en `scripts/core/layers.gd`.

| # | Nombre | Quién está en ella | Quién la detecta |
|---|---|---|---|
| 1 | `world` | Tiles sólidos | Cuerpos del jugador y enemigos, raycast de balas |
| 2 | `player` | Cuerpo y hurtbox del jugador | — |
| 3 | `enemy` | Cuerpos, hurtbox y contacto de enemigos | Hurtbox del jugador (contacto) |
| 4 | `player_bullet` | Balas del jugador | Hurtbox de enemigos |
| 5 | `enemy_bullet` | Balas enemigas | Hurtbox del jugador |
| 6 | `pickup` | Pickups y cuerpo de la cápsula | Los pickups detectan el cuerpo del jugador (capa 2) |
| 7 | `hazard` | Agua y abismo (muerte instantánea) | Hurtbox del jugador |
| 8 | `one_way` | Plataformas atravesables | Cuerpos (el jugador la desactiva un instante al bajar) |

> La capa 8 `one_way` es un agregado: separar las plataformas del suelo sólido permite bajar por ellas sin atravesar el piso.

## Paso a paso: reemplazar un placeholder por arte real

Ejemplo: la animación de correr del gato, 6 frames de 32×32.

1. Dibuja los frames **mirando a la derecha**, con los pies tocando el borde inferior del frame y el cuerpo centrado en X.
2. Opción A: borra `assets/sprites/player/run_*.png` y copia tus `run_0.png … run_5.png`.
   Opción B: deja una hoja `assets/sprites/player/run.png` (192×32). Tiene prioridad, no hace falta borrar nada.
3. Abre el proyecto en Godot (importa los PNG automáticamente) o ejecuta `godot --headless --path . --import`.
4. Juega. Si la animación tiene otro número de frames u otro tamaño, todo se ajusta solo; si usas hoja con otro tamaño de frame, agrega `run.json`.
5. ¿Ajustar FPS por defecto o agregar una animación al catálogo? Edita `scripts/art/sprite_catalog.gd` (no es código de gameplay).
6. Si el arma sale de un lugar raro respecto al arte nuevo, mueve los `Marker2D` de `Muzzles/` en `scenes/player/player.tscn`.

Para volver a los placeholders de algo: borra esos PNG y ejecuta el generador (ver README).
