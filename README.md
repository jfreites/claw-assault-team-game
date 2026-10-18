# Contra But Cats

Vertical slice de un run & gun 2D estilo Contra protagonizado por un gato guerrero. Godot 4.3+ (probado con 4.7.2), solo GDScript, sin plugins.

> Estado: etapas 1–5 (jugador, armas, enemigos, pickups, poderes y nivel 1 "La isla"). El jefe y el pulido (HUD final, game feel, pantallas) llegan en las etapas 6 y 7.

## Ejecutar

Abre la carpeta en Godot y presiona F5, o desde la terminal:

```bash
godot --path .
```

La escena principal es `scenes/levels/level_1.tscn` ("La isla"). El campo de pruebas con una muestra de todo sigue en `scenes/levels/test_range.tscn` (ábrelo y presiona F6).

**La isla**: el gato cae del cielo a la playa → tramo plano con corredores → plataformas sobre agua y abismo con voladores → torretas y cápsula de arma (spread) → zona de checkpoint (bandera) → arena del jefe con cámara bloqueada. El jefe llega en la etapa 6; por ahora la arena está vacía.

## Controles

| Acción | Teclado | Gamepad |
|---|---|---|
| Moverse | WASD / flechas | Cruceta / stick izq. |
| Apuntar arriba | W / ↑ | Arriba |
| Agacharse / echarse | S / ↓ | Abajo |
| Saltar | K / Z / Espacio | A |
| Disparar (mantener) | J / X | X / B / gatillo der. |
| Fijar dirección de disparo | L / C / Shift | LB / RB |
| (Debug) cambiar de arma | Tab | Select/Back |

- Abajo + saltar sobre una plataforma de madera = bajar a través de ella.
- Abajo recto solo dispara hacia abajo en el aire; en el suelo te echas (hurtbox más bajo).
- Mantén *fijar dirección* para caminar sin cambiar hacia dónde disparas.
- Un golpe = una vida. Con 3 vidas; al perder una reapareces en el último checkpoint.
- Dispara a las cápsulas voladoras para que suelten un arma o un poder; tócalo para recogerlo.
- Poderes: **Catnip** (+40 % velocidad y +80 % cadencia, 10 s; el gato parpadea en verde) y **Leche** (escudo que absorbe un golpe, 20 s). El HUD muestra el tiempo restante.

## Herramientas

```bash
# Regenerar placeholders que falten (no pisa arte real)
godot --headless --path . --script res://tools/generate_placeholders.gd
# Regenerar TODOS los placeholders (sobrescribe PNG con el mismo nombre)
godot --headless --path . --script res://tools/generate_placeholders.gd -- --force
# Importar los PNG nuevos sin abrir el editor
godot --headless --path . --import
# Reescribir el Input Map (teclado + gamepad) en project.godot
godot --headless --path . --script res://tools/setup_input_map.gd
# Prueba automática de movimiento, armas, enemigos, pickups y poderes
godot --headless --path . res://tools/smoke_test.tscn
# Recorrido automático del nivel 1 (caída inicial, checkpoint, arena)
godot --headless --path . res://tools/playthrough_test.tscn
```

Para reemplazar arte, ver [ASSETS.md](ASSETS.md).

## Cómo agregar…

**Un arma**: duplica un `.tres` de `resources/weapons/` (ej. `hairball.tres`) y ajusta `WeaponData`: nombre, `fire_rate`, `damage`, `bullet_speed`, `pattern` (SINGLE / SPREAD / BOUNCE / PIERCE), `bullet_sprite`, `sfx`, etc. Si usa un sprite nuevo, agrégalo al catálogo (`scripts/art/sprite_catalog.gd`) y corre el generador. Para probarla rápido, súmala a `debug_weapons` del `WeaponHolder` en `scenes/player/player.tscn`.

**Un enemigo**:
1. Crea un script que extienda `Enemy` (`scripts/enemies/enemy.gd`) y sobrescribe `_on_activated()` y `_enemy_process(delta)`.
2. Crea su `EnemyStats` en `resources/enemies/` (salud, velocidad, arma, cadencia, drop…).
3. Duplica una escena de `scenes/enemies/` (necesita los nodos `Sprite`, `Hurtbox`, `ContactHitbox`) y cambia script, stats y `entity` del sprite.
4. Agrega su entrada al catálogo de sprites y regenera placeholders.
5. Para colocarlo en un nivel, asígnale un carácter en `spawns` del `LevelLayout` y úsalo en el mapa ASCII.

**Un poder**: crea un `.tres` en `resources/powerups/` con script `PowerUpData` y ajusta `duration`, `tint` (color del gato mientras dura) y los modificadores (`speed_multiplier`, `fire_rate_multiplier`, `jump_multiplier`, `damage_multiplier`, `shield_hits`, `extra_air_jumps` para salto doble). Los modificadores de varios poderes activos se combinan. Escucha `power_started` / `power_ended` en el `PowerUpController` del jugador (`$PowerUps`).

**Una cápsula con otro contenido**: crea una escena heredada de `scenes/pickups/capsule.tscn` (como `capsule_yarn.tscn`) y cambia su `item` a cualquier `WeaponData` o `PowerUpData`. Los enemigos también pueden soltar pickups con `drop_chance` y `drop_table` en su `EnemyStats`.

## Niveles

Los niveles son texto ASCII (`resources/levels/*.tres`, recurso `LevelLayout`), editables en el inspector o con cualquier editor de texto. Cada carácter es un tile de 16 px:

| Carácter | Significado |
|---|---|
| `#` / `:` | Suelo sólido (tierra / arena) |
| `=` | Plataforma one-way |
| `~` | Agua (mortal) |
| `P` | Inicio del jugador (cae del cielo si `intro_drop` está activo) |
| `A` | Entrada a la arena del jefe: la cámara se bloquea en la pantalla que empieza en esa columna |
| otros | Se buscan en `spawns`. En La isla: `R` corredor, `G` generador de corredores, `T` torreta, `F` volador, `C` checkpoint, cápsulas `N` catnip / `M` leche / `S` spread (`Y` estambre y `B` espina en el campo de pruebas) |

Caer bajo el nivel mata. La cámara solo avanza; el fondo es un `ParallaxBackdrop` con dos capas (`assets/sprites/backgrounds/far.png` y `near.png`). La música se pide con el campo `music` del nivel (`AudioManager.play_music`).

## Estructura

```
assets/sprites/…        arte (placeholders generados)      tools/          generador, input map, smoke test
assets/audio/{sfx,music} audio (AudioManager.play_sfx)     resources/      WeaponData, EnemyStats, PlayerConfig, niveles
scenes/                  escenas por tipo                   scripts/        código (autoload, player, weapons, enemies…)
```

Audio: `AudioManager.play_sfx("jump")` reproduce `assets/audio/sfx/jump.(wav|ogg|mp3)` si existe; si no, silencio. Hooks actuales: `jump`, `shoot`, `shoot_yarn`, `shoot_fishbone`, `shoot_spread`, `bounce`, `player_hurt`, `enemy_hit`, `enemy_die`, `enemy_shoot`, `enemy_bomb`, `pickup_weapon`, `power_catnip`, `power_milk`, `shield_break`, `land`, `checkpoint`. Música: `level_1`.
