class_name SpriteCatalog
extends RefCounted
## Catálogo de arte por entidad: tamaño de frame, anclaje y animaciones (frames, fps, loop).
## Es la fuente única que usan SpriteLoader (runtime) y tools/generate_placeholders.gd.
## La clave de cada entidad es su carpeta relativa a assets/sprites/ (arte compartido) o a
## assets/sprites/levels/<nivel>/ (arte propio de un nivel, marcado con "level").
## "color", "label", "shape", "gun" y "tint" solo afectan al placeholder generado.
## Todo el arte mira hacia la DERECHA; el código voltea con flip_h.

const ROOT := "res://assets/sprites/"
const LEVELS_ROOT := ROOT + "levels/"
## Nivel cuyo arte se usa cuando el nivel actual no trae el suyo (editor, campo de pruebas)
const DEFAULT_LEVEL := "level_01"

const ENTITIES := {
	"player": {
		"size": Vector2i(32, 32),
		"anchor": "feet",
		"color": "f0a030",
		"label": "CAT",
		"default": "idle",
		"anims": {
			"idle": {"frames": 2, "fps": 4.0, "loop": true, "shape": "stand", "gun": "fwd"},
			"aim_up": {"frames": 2, "fps": 4.0, "loop": true, "shape": "stand", "gun": "up"},
			"run": {"frames": 6, "fps": 12.0, "loop": true, "shape": "quad", "gun": "fwd"},
			"run_aim_up": {"frames": 6, "fps": 12.0, "loop": true, "shape": "quad", "gun": "diag_up"},
			"run_aim_down": {"frames": 6, "fps": 12.0, "loop": true, "shape": "quad", "gun": "diag_down"},
			"jump": {"frames": 4, "fps": 14.0, "loop": true, "shape": "ball"},
			"fall": {"frames": 2, "fps": 8.0, "loop": true, "shape": "stand", "gun": "fwd"},
			"prone": {"frames": 1, "fps": 1.0, "loop": true, "shape": "prone", "gun": "fwd"},
			"hurt": {"frames": 2, "fps": 8.0, "loop": true, "shape": "ball", "tint": "ff3030"},
			"dead": {"frames": 1, "fps": 1.0, "loop": false, "shape": "flat"},
		},
	},
	# --- Enemigos (arte propio del nivel 1) ---
	"enemies/runner": {
		"level": "level_01",
		"size": Vector2i(24, 28), "anchor": "feet", "color": "d04848", "label": "R", "default": "run",
		"anims": {
			"run": {"frames": 4, "fps": 10.0, "loop": true, "shape": "walker"},
			"fall": {"frames": 1, "fps": 1.0, "loop": true, "shape": "walker"},
		},
	},
	"enemies/turret": {
		"level": "level_01",
		"size": Vector2i(24, 24), "anchor": "feet", "color": "8a8aa8", "label": "T", "default": "idle",
		"anims": {
			"idle": {"frames": 1, "fps": 1.0, "loop": true, "shape": "turret"},
			"fire": {"frames": 2, "fps": 10.0, "loop": false, "shape": "turret"},
		},
	},
	"enemies/flyer": {
		"level": "level_01",
		"size": Vector2i(28, 18), "anchor": "center", "color": "3fbfbf", "label": "F", "default": "fly",
		"anims": {"fly": {"frames": 2, "fps": 8.0, "loop": true, "shape": "wing"}},
	},
	# --- Pickups (anclaje al centro) y cápsula ---
	"pickups/capsule": {
		"size": Vector2i(26, 16), "anchor": "center", "color": "d0d0d8", "label": "C", "default": "fly",
		"anims": {"fly": {"frames": 2, "fps": 8.0, "loop": true, "shape": "wing"}},
	},
	"pickups/weapon_hairball": {
		"size": Vector2i(16, 14), "anchor": "center", "color": "c08a5a", "label": "H", "default": "idle",
		"anims": {"idle": {"frames": 2, "fps": 4.0, "loop": true, "shape": "pill"}},
	},
	"pickups/weapon_yarn": {
		"size": Vector2i(16, 14), "anchor": "center", "color": "ff5fc0", "label": "E", "default": "idle",
		"anims": {"idle": {"frames": 2, "fps": 4.0, "loop": true, "shape": "pill"}},
	},
	"pickups/weapon_fishbone": {
		"size": Vector2i(16, 14), "anchor": "center", "color": "b8c4ff", "label": "P", "default": "idle",
		"anims": {"idle": {"frames": 2, "fps": 4.0, "loop": true, "shape": "pill"}},
	},
	"pickups/weapon_sardine": {
		"size": Vector2i(16, 14), "anchor": "center", "color": "5fa8ff", "label": "S", "default": "idle",
		"anims": {"idle": {"frames": 2, "fps": 4.0, "loop": true, "shape": "pill"}},
	},
	"pickups/power_catnip": {
		"size": Vector2i(16, 14), "anchor": "center", "color": "7fd34e", "label": "N", "default": "idle",
		"anims": {"idle": {"frames": 2, "fps": 4.0, "loop": true, "shape": "pill"}},
	},
	"pickups/power_milk": {
		"size": Vector2i(16, 14), "anchor": "center", "color": "f4f4f4", "label": "L", "default": "idle",
		"anims": {"idle": {"frames": 2, "fps": 4.0, "loop": true, "shape": "pill"}},
	},
	# --- Props del nivel ---
	"props/checkpoint": {
		"size": Vector2i(16, 32), "anchor": "feet", "color": "ff5a3c", "default": "idle",
		"anims": {
			"idle": {"frames": 1, "fps": 1.0, "loop": true, "shape": "flag_down"},
			"active": {"frames": 2, "fps": 6.0, "loop": true, "shape": "flag_up"},
		},
	},
	# --- Efectos ---
	"fx/shield": {
		"size": Vector2i(32, 32), "anchor": "center", "color": "ffe066", "default": "idle",
		"anims": {"idle": {"frames": 4, "fps": 10.0, "loop": true, "shape": "ring"}},
	},
	# --- Jefe del nivel 1 ---
	"boss/mecha_dog": {
		"level": "level_01",
		"size": Vector2i(72, 52), "anchor": "feet", "color": "7f8a99", "label": "MECHA", "default": "idle",
		"anims": {
			"idle": {"frames": 2, "fps": 4.0, "loop": true, "shape": "mech"},
			"fire": {"frames": 2, "fps": 10.0, "loop": true, "shape": "mech", "gun": "fwd"},
			"windup": {"frames": 2, "fps": 12.0, "loop": true, "shape": "mech", "tint": "ffaa33"},
			"charge": {"frames": 4, "fps": 14.0, "loop": true, "shape": "mech", "tint": "ffaa33"},
			"mortar": {"frames": 2, "fps": 8.0, "loop": true, "shape": "mech", "gun": "up"},
			"roar": {"frames": 2, "fps": 10.0, "loop": true, "shape": "mech", "tint": "ff4040"},
			"dying": {"frames": 2, "fps": 12.0, "loop": true, "shape": "mech", "tint": "402020"},
		},
	},
	"boss/weak_point": {
		"level": "level_01",
		"size": Vector2i(12, 14), "anchor": "center", "color": "ff3366", "default": "open",
		"anims": {
			"open": {"frames": 2, "fps": 6.0, "loop": true, "shape": "orb"},
			"closed": {"frames": 1, "fps": 1.0, "loop": true, "shape": "box", "tint": "50505a"},
		},
	},
	# --- Proyectiles (anclaje al centro, animación "fly") ---
	"projectiles/hairball": {
		"size": Vector2i(6, 6), "anchor": "center", "color": "c08a5a", "default": "fly",
		"anims": {"fly": {"frames": 2, "fps": 12.0, "loop": true, "shape": "orb"}},
	},
	"projectiles/yarn": {
		"size": Vector2i(8, 8), "anchor": "center", "color": "ff5fc0", "default": "fly",
		"anims": {"fly": {"frames": 4, "fps": 12.0, "loop": true, "shape": "orb"}},
	},
	"projectiles/fishbone": {
		"size": Vector2i(14, 6), "anchor": "center", "color": "e8ecff", "default": "fly",
		"anims": {"fly": {"frames": 1, "fps": 1.0, "loop": true, "shape": "bone"}},
	},
	"projectiles/sardine": {
		"size": Vector2i(7, 7), "anchor": "center", "color": "5fa8ff", "default": "fly",
		"anims": {"fly": {"frames": 2, "fps": 12.0, "loop": true, "shape": "orb"}},
	},
	"projectiles/enemy_shot": {
		"size": Vector2i(5, 5), "anchor": "center", "color": "ff3a3a", "default": "fly",
		"anims": {"fly": {"frames": 2, "fps": 10.0, "loop": true, "shape": "orb"}},
	},
	"projectiles/boss_shell": {
		"size": Vector2i(10, 6), "anchor": "center", "color": "ffb030", "default": "fly",
		"anims": {"fly": {"frames": 2, "fps": 10.0, "loop": true, "shape": "bone"}},
	},
	"projectiles/enemy_bomb": {
		"size": Vector2i(7, 7), "anchor": "center", "color": "a050ff", "default": "fly",
		"anims": {"fly": {"frames": 2, "fps": 8.0, "loop": true, "shape": "orb"}},
	},
}


static func has_entity(entity: String) -> bool:
	return ENTITIES.has(entity)


static func get_spec(entity: String) -> Dictionary:
	return ENTITIES.get(entity, {})


static func level_dir(level_id: String) -> String:
	return LEVELS_ROOT + level_id + "/"


## Carpeta donde vive (o se genera) el arte base de una entidad
static func home_dir(entity: String) -> String:
	var level: String = get_spec(entity).get("level", "")
	return (level_dir(level) if level != "" else ROOT) + entity + "/"


static func get_anim_spec(entity: String, anim: String) -> Dictionary:
	return get_spec(entity).get("anims", {}).get(anim, {})
