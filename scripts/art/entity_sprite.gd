@tool
class_name EntitySprite
extends AnimatedSprite2D
## Sprite de una entidad: arma su SpriteFrames desde assets/sprites/<entity>/ vía SpriteLoader.
## El anclaje (pies o centro) se calcula con el tamaño real del frame, así el arte
## puede cambiar de tamaño sin mover hitboxes ni nodos.

const Loader := preload("res://scripts/autoload/sprite_loader.gd")

## Carpeta relativa a assets/sprites (ej. "player", "enemies/runner")
@export var entity: String = "":
	set(value):
		entity = value
		if is_inside_tree():
			apply_entity()


func _ready() -> void:
	apply_entity()


func apply_entity() -> void:
	if entity.is_empty():
		return
	sprite_frames = Loader.get_frames(entity)
	var default_anim := Loader.get_default_animation(entity, sprite_frames)
	var size := Loader.get_frame_size(sprite_frames, default_anim)
	centered = true
	if Loader.get_anchor(entity) == "feet":
		offset = Vector2(0, -floorf(size.y * 0.5))
	else:
		offset = Vector2.ZERO
	play(default_anim)


## Reproduce `anim`; si el arte no la trae usa `fallback` (o deja la actual).
func play_safe(anim: StringName, fallback: StringName = &"") -> void:
	if sprite_frames == null:
		return
	var target := anim
	if not sprite_frames.has_animation(target):
		if fallback != &"" and sprite_frames.has_animation(fallback):
			target = fallback
		else:
			return
	if animation != target:
		play(target)


func _validate_property(property: Dictionary) -> void:
	# El SpriteFrames se construye al vuelo: no se guarda dentro de la escena
	if property.name == "sprite_frames":
		property.usage &= ~PROPERTY_USAGE_STORAGE
