class_name SpriteCatalog
extends RefCounted
## Catálogo de arte por entidad: tamaño de frame, anclaje y animaciones (frames, fps, loop).
## Es la fuente única que usan SpriteLoader (runtime) y tools/generate_placeholders.gd.
## La clave de cada entidad es su carpeta relativa a assets/sprites/.
## "color", "label", "shape", "gun" y "tint" solo afectan al placeholder generado.
## Todo el arte mira hacia la DERECHA; el código voltea con flip_h.

const ROOT := "res://assets/sprites/"

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
}


static func has_entity(entity: String) -> bool:
	return ENTITIES.has(entity)


static func get_spec(entity: String) -> Dictionary:
	return ENTITIES.get(entity, {})


static func get_anim_spec(entity: String, anim: String) -> Dictionary:
	return get_spec(entity).get("anims", {}).get(anim, {})
