extends Node
## SpriteLoader (autoload): construye el SpriteFrames de cada entidad leyendo su carpeta.
##   assets/sprites/<entidad>/<anim>_<n>.png  → frames sueltos (run_0.png, run_1.png, ...)
##   assets/sprites/<entidad>/<anim>.png      → hoja horizontal (tiene prioridad sobre los sueltos)
##   assets/sprites/<entidad>/<anim>.json     → metadata opcional de la hoja
## Un PNG real con el mismo nombre que el placeholder lo reemplaza sin tocar código.
## Las funciones son estáticas para poder usarlas también desde el editor (@tool).

const Catalog := preload("res://scripts/art/sprite_catalog.gd")
const MAX_FRAMES := 64

static var _frames_cache: Dictionary = {}
static var _texture_cache: Dictionary = {}
static var _frame_regex: RegEx


static func get_frames(entity: String) -> SpriteFrames:
	if not _frames_cache.has(entity):
		_frames_cache[entity] = build_frames(entity)
	return _frames_cache[entity]


static func clear_cache() -> void:
	_frames_cache.clear()
	_texture_cache.clear()


static func get_anchor(entity: String) -> String:
	return Catalog.get_spec(entity).get("anchor", "feet")


static func get_default_animation(entity: String, frames: SpriteFrames) -> StringName:
	var wanted: String = Catalog.get_spec(entity).get("default", "")
	if wanted != "" and frames.has_animation(wanted):
		return StringName(wanted)
	var names := frames.get_animation_names()
	return StringName(names[0]) if names.size() > 0 else &"default"


static func get_frame_size(frames: SpriteFrames, anim: StringName) -> Vector2:
	if frames.has_animation(anim) and frames.get_frame_count(anim) > 0:
		var tex := frames.get_frame_texture(anim, 0)
		if tex:
			return tex.get_size()
	return Vector2(16, 16)


static func build_frames(entity: String) -> SpriteFrames:
	var spec := Catalog.get_spec(entity)
	var dir := Catalog.ROOT + entity + "/"
	var anims: Dictionary = spec.get("anims", {})
	var names: Array = anims.keys()
	# Animaciones extra que el artista agregue y no estén en el catálogo
	for found in _discover_animations(dir):
		if not names.has(found):
			names.append(found)

	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim_name in names:
		_add_animation(frames, dir, String(anim_name), spec, anims.get(anim_name, {}))

	if frames.get_animation_names().is_empty():
		push_warning("SpriteLoader: no hay sprites para '%s' en %s (ejecuta tools/generate_placeholders.gd)" % [entity, dir])
		frames.add_animation(&"default")
		frames.add_frame(&"default", _missing_texture(spec.get("size", Vector2i(16, 16))))
	return frames


## Carga una textura suelta (tiles, fondos, UI) con la misma lógica de reemplazo.
static func load_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex == null and FileAccess.file_exists(path):
		# PNG recién copiado y aún sin importar: se lee directo del disco
		var img := Image.load_from_file(path)
		if img:
			tex = ImageTexture.create_from_image(img)
	_texture_cache[path] = tex
	return tex


static func resource_exists(path: String) -> bool:
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)


static func _add_animation(frames: SpriteFrames, dir: String, anim_name: String, spec: Dictionary, anim_spec: Dictionary) -> void:
	var fps: float = anim_spec.get("fps", 8.0)
	var loop: bool = anim_spec.get("loop", true)
	var textures: Array[Texture2D] = []

	var sheet_path := dir + anim_name + ".png"
	if resource_exists(sheet_path):
		var sheet := load_texture(sheet_path)
		if sheet:
			var meta := _read_json(dir + anim_name + ".json")
			var size: Vector2i = spec.get("size", Vector2i(sheet.get_height(), sheet.get_height()))
			var fw := int(meta.get("frame_width", size.x))
			var fh := int(meta.get("frame_height", sheet.get_height()))
			var count := int(meta.get("frames", floori(sheet.get_width() / float(maxi(fw, 1)))))
			fps = float(meta.get("fps", fps))
			loop = bool(meta.get("loop", loop))
			for i in count:
				var atlas := AtlasTexture.new()
				atlas.atlas = sheet
				atlas.region = Rect2(i * fw, 0, fw, fh)
				textures.append(atlas)
	else:
		for i in MAX_FRAMES:
			var path := "%s%s_%d.png" % [dir, anim_name, i]
			if not resource_exists(path):
				break
			var tex := load_texture(path)
			if tex:
				textures.append(tex)

	if textures.is_empty():
		return
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)
	for tex in textures:
		frames.add_frame(anim_name, tex)


static func _discover_animations(dir: String) -> Array:
	var result := []
	if not DirAccess.dir_exists_absolute(dir):
		return result
	if _frame_regex == null:
		_frame_regex = RegEx.new()
		_frame_regex.compile("^(.+)_(\\d+)$")
	for file in DirAccess.get_files_at(dir):
		var f := file.trim_suffix(".import").trim_suffix(".remap")
		if f.get_extension().to_lower() != "png":
			continue
		var base := f.get_basename()
		var m := _frame_regex.search(base)
		var anim := m.get_string(1) if m else base
		if not result.has(anim):
			result.append(anim)
	return result


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


static func _missing_texture(size: Vector2i) -> Texture2D:
	var img := Image.create(maxi(size.x, 1), maxi(size.y, 1), false, Image.FORMAT_RGBA8)
	img.fill(Color.MAGENTA)
	return ImageTexture.create_from_image(img)
