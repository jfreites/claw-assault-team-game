# Contra But Cats

Vertical slice de un run & gun 2D estilo Contra protagonizado por un gato guerrero. Godot 4.3+ (probado con 4.7.2), solo GDScript, sin plugins.

> Estado: etapas 1–3 (jugador, armas, enemigos) en un nivel de prueba. Pickups, nivel 1, jefe y pulido llegan en las siguientes etapas.

## Ejecutar

Abre la carpeta en Godot y presiona F5, o desde la terminal:

```bash
godot --path .
```

La escena principal es `scenes/levels/test_range.tscn`.

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
# Prueba automática de movimiento, armas y enemigos
godot --headless --path . res://tools/smoke_test.tscn
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

**Un poder**: *(etapa 4)*.

## Niveles

Los niveles son texto ASCII (`resources/levels/*.tres`, recurso `LevelLayout`): `#` suelo, `=` plataforma one-way, `~` agua mortal, `P` inicio, y cualquier otro carácter se busca en `spawns` (ej. `R` corredor, `T` torreta, `F` volador). Caer bajo el nivel mata.

## Estructura

```
assets/sprites/…        arte (placeholders generados)      tools/          generador, input map, smoke test
assets/audio/{sfx,music} audio (AudioManager.play_sfx)     resources/      WeaponData, EnemyStats, PlayerConfig, niveles
scenes/                  escenas por tipo                   scripts/        código (autoload, player, weapons, enemies…)
```

Audio: `AudioManager.play_sfx("jump")` reproduce `assets/audio/sfx/jump.(wav|ogg|mp3)` si existe; si no, silencio. Hooks actuales: `jump`, `shoot`, `shoot_yarn`, `shoot_fishbone`, `shoot_spread`, `bounce`, `player_hurt`, `enemy_hit`, `enemy_die`, `enemy_shoot`, `enemy_bomb`.
