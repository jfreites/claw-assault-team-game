# C.A.T. — Operation Island

**C.A.T. (Claw Assault Team): Operation Island.** Vertical slice de un run & gun 2D estilo Contra protagonizado por un gato guerrero. Toda la acción ocurre en una misma isla, dividida en niveles (stages): playa, selva, cuevas, base… Godot 4.3+ (probado con 4.7.2), solo GDScript, sin plugins.

> Estado: etapas 1–6 (jugador, armas, enemigos, pickups, poderes, Nivel 1: Playa de desembarco y jefe perro mecha) + título, lista de niveles y victoria. Falta la etapa 7 (HUD final, game feel, audio placeholder, pulido).

## Ejecutar

Abre la carpeta en Godot y presiona F5, o desde la terminal:

```bash
godot --path .
```

El juego arranca en la pantalla de título (`scenes/ui/title_screen.tscn`): **START** (Enter / START del gamepad, también saltar o disparar) empieza el Nivel 1. El nivel se puede abrir directo con `scenes/levels/level_01.tscn` + F6. El campo de pruebas con una muestra de todo sigue en `scenes/levels/test_range.tscn`.

**Nivel 1: Playa de desembarco**: el gato cae del cielo a la playa → tramo plano con corredores → plataformas sobre agua y abismo con voladores → torretas y cápsula de arma (spread) → zona de checkpoint (bandera) → arena del jefe con cámara bloqueada: el **perro mecha** cae del cielo.

**Jefe — MECHA-DOG**: solo recibe daño en el **punto débil** (el núcleo rojo del hocico); la armadura detiene las balas. Fase 1: abanico de balas y embestida (parpadea antes de embestir y cierra el punto débil; sáltalo o súbete a una plataforma). Bajo la mitad de vida ruge y pasa a la fase 2: más rápido, abanicos más grandes y un ataque nuevo de **mortero** que llueve alrededor tuyo. Al morir explota y pasa a la pantalla de victoria.

## Controles

| Acción | Teclado | Gamepad |
|---|---|---|
| Moverse | WASD / flechas | Cruceta / stick izq. |
| Apuntar arriba | W / ↑ | Arriba |
| Agacharse / echarse | S / ↓ | Abajo |
| Saltar | K / Z / Espacio | A |
| Disparar (mantener) | J / X | X / B / gatillo der. |
| Fijar dirección de disparo | L / C / Shift | LB / RB |
| Empezar (título / victoria) | Enter | START |
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
# Pelea automática contra el jefe (fases, punto débil, muerte)
godot --headless --path . res://tools/boss_test.tscn
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

**Ajustar la dificultad del jefe**: `resources/boss/mecha_dog.tres` (vida, umbral de fase 2, tiempos de intro/muerte) y `mecha_dog_phase1.tres` / `mecha_dog_phase2.tres` (secuencia de ataques `pattern`, pausas, volleys del abanico, aviso y velocidad de embestida, cantidad y dispersión del mortero). Las balas son `WeaponData` en `resources/weapons/enemy/boss_*.tres`.

**Un jefe para otro nivel**: duplica `scenes/boss/mecha_dog.tscn` (o extiende `Boss`), crea su `BossData`, y colócalo en el layout con un carácter (en el nivel 1 es `X`) dentro de la arena (`A`). El nivel lo despierta al bloquearse la cámara y conecta su barra de vida y la victoria.

**Una cápsula con otro contenido**: crea una escena heredada de `scenes/pickups/capsule.tscn` (como `capsule_yarn.tscn`) y cambia su `item` a cualquier `WeaponData` o `PowerUpData`. Los enemigos también pueden soltar pickups con `drop_chance` y `drop_table` en su `EnemyStats`.

## Niveles

La campaña es una lista de `LevelInfo` en `resources/levels/level_list.tres`, que recorre el autoload `LevelManager`:

- `LevelManager.start_game()` empieza en el primer nivel (lo usa el título).
- `LevelManager.complete_current_level()` pasa al siguiente o, si era el último, muestra la pantalla de victoria (`scenes/ui/victory_screen.tscn`). La llama el nivel cuando su jefe es derrotado.

**Agregar un nivel** (ej. selva):
1. Crea `resources/levels/level_02_info.tres` (`LevelInfo`: número, título, `scene_path`, `art_dir = res://assets/sprites/levels/level_02`).
2. Crea su layout `resources/levels/level_02_layout.tres` y su escena `scenes/levels/level_02.tscn` (duplica `level_01.tscn` y cambia `info` y `layout`).
3. Súmalo al arreglo `levels` de `level_list.tres`.
4. Pon su arte propio en `assets/sprites/levels/level_02/` (tileset, fondos, enemigos con otra piel). Lo que no tenga se toma del arte compartido o del nivel 1.

### Layout ASCII

Los niveles son texto ASCII (`resources/levels/*.tres`, recurso `LevelLayout`), editables en el inspector o con cualquier editor de texto. Cada carácter es un tile de 16 px:

| Carácter | Significado |
|---|---|
| `#` / `:` | Suelo sólido (tierra / arena) |
| `=` | Plataforma one-way |
| `~` | Agua (mortal) |
| `P` | Inicio del jugador (cae del cielo si `intro_drop` está activo) |
| `A` | Entrada a la arena del jefe: la cámara se bloquea en la pantalla que empieza en esa columna |
| otros | Se buscan en `spawns`. En el Nivel 1: `X` jefe, `R` corredor, `G` generador de corredores, `T` torreta, `F` volador, `C` checkpoint, cápsulas `N` catnip / `M` leche / `S` spread (`Y` estambre y `B` espina en el campo de pruebas) |

Caer bajo el nivel mata. La cámara solo avanza; el fondo es un `ParallaxBackdrop` con dos capas (`backgrounds/far.png` y `near.png` dentro de la carpeta de arte del nivel). La música se pide con el campo `music` del nivel (`AudioManager.play_music`).

## Estructura

```
assets/sprites/…        arte compartido (placeholders)     tools/          generador, input map, tests
assets/sprites/levels/   arte propio de cada nivel          scenes/ui/      título, victoria, HUD
assets/audio/{sfx,music} audio (AudioManager.play_sfx)     resources/      WeaponData, EnemyStats, PlayerConfig, niveles
scenes/                  escenas por tipo                   scripts/        código (autoload, player, weapons, enemies…)
```

Audio: `AudioManager.play_sfx("jump")` reproduce `assets/audio/sfx/jump.(wav|ogg|mp3)` si existe; si no, silencio. Hooks actuales: `jump`, `shoot`, `shoot_yarn`, `shoot_fishbone`, `shoot_spread`, `bounce`, `player_hurt`, `enemy_hit`, `enemy_die`, `enemy_shoot`, `enemy_bomb`, `pickup_weapon`, `power_catnip`, `power_milk`, `shield_break`, `land`, `checkpoint`, `menu_start`, `boss_land`, `boss_fan`, `boss_charge`, `boss_crash`, `boss_mortar`, `boss_hit`, `boss_roar`, `armor_hit`, `explosion`, `boss_explode`, `stage_clear`. Música: `level_01`, `boss`.
