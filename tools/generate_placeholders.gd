extends SceneTree
## Genera los PNG placeholder declarados en SpriteCatalog (y el tileset).
## Uso:
##   godot --headless --path . --script res://tools/generate_placeholders.gd
##   godot --headless --path . --script res://tools/generate_placeholders.gd -- --force
## Sin --force solo crea lo que falta: nunca pisa arte real que tenga el mismo nombre.
## Luego ejecuta `godot --headless --path . --import` (o abre el editor) para importarlos.

const Catalog := preload("res://scripts/art/sprite_catalog.gd")
const PixelFont := preload("res://tools/pixel_font.gd")

const GUN_COLOR := Color(0.15, 0.15, 0.2)
const GUN_DIRS := {
	"fwd": Vector2(1, 0), "up": Vector2(0, -1), "down": Vector2(0, 1),
	"diag_up": Vector2(0.7071, -0.7071), "diag_down": Vector2(0.7071, 0.7071),
	"back": Vector2(-1, 0),
}

var _force := false
var _created := 0
var _skipped := 0


func _initialize() -> void:
	_force = OS.get_cmdline_user_args().has("--force")
	for entity in Catalog.ENTITIES:
		_generate_entity(entity)
	_generate_tiles()
	_generate_backgrounds()
	print("Placeholders: %d creados, %d existentes respetados%s" % [_created, _skipped, " (--force)" if _force else ""])
	quit()


# --- Entidades ------------------------------------------------------------

func _generate_entity(entity: String) -> void:
	var spec: Dictionary = Catalog.get_spec(entity)
	var dir: String = Catalog.home_dir(entity).trim_suffix("/")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var anims: Dictionary = spec.get("anims", {})
	for anim_name in anims:
		var anim: Dictionary = anims[anim_name]
		# Si el artista ya dejó una hoja <anim>.png no se generan frames sueltos
		if not _force and FileAccess.file_exists("%s/%s.png" % [dir, anim_name]):
			_skipped += 1
			continue
		var count: int = anim.get("frames", 1)
		for i in count:
			var path := "%s/%s_%d.png" % [dir, anim_name, i]
			if not _force and FileAccess.file_exists(path):
				_skipped += 1
				continue
			_save(_draw_frame(spec, String(anim_name), anim, i, count), path)


func _draw_frame(spec: Dictionary, anim_name: String, anim: Dictionary, frame: int, count: int) -> Image:
	var size: Vector2i = spec.get("size", Vector2i(16, 16))
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var base := Color.html(spec.get("color", "ff00ff"))
	if anim.has("tint"):
		base = base.lerp(Color.html(anim["tint"]), 0.65)
	var shape: String = anim.get("shape", "box")
	var info := _draw_shape(img, shape, base, frame, count)
	if shape != "ring":
		_outline(img, base.darkened(0.65))

	var gun: String = anim.get("gun", "")
	if gun != "" and info.has("gun"):
		_draw_gun(img, info["gun"], GUN_DIRS.get(gun, Vector2.RIGHT))

	# Etiqueta de la entidad sobre el cuerpo
	var label: String = spec.get("label", "")
	var body: Rect2i = info.get("body", Rect2i())
	if label != "" and PixelFont.text_width(label) <= body.size.x + 2 and body.size.y >= 5:
		var pos := body.get_center() - Vector2i(PixelFont.text_width(label) / 2, 2)
		PixelFont.draw_text(img, label, pos, base.darkened(0.75))
	# Nombre de animación y número de frame (solo si hay espacio)
	if size.x >= 24 and size.y >= 20:
		PixelFont.draw_text(img, _anim_tag(anim_name), Vector2i(1, 1), Color.WHITE, Color(0, 0, 0, 0.8))
		PixelFont.draw_text(img, str(frame % 10), Vector2i(size.x - 4, 1), Color(1, 1, 0.5), Color(0, 0, 0, 0.8))
	return img


## "run" → RUN, "run_aim_up" → RAU (iniciales si hay varias palabras)
func _anim_tag(anim_name: String) -> String:
	var parts := anim_name.split("_", false)
	if parts.size() <= 1:
		return anim_name.substr(0, 4)
	var tag := ""
	for part in parts:
		tag += part[0]
	return tag.substr(0, 4)


## Dibuja la silueta. Devuelve {"body": Rect2i, "gun": Vector2i}
func _draw_shape(img: Image, shape: String, c: Color, f: int, n: int) -> Dictionary:
	var w := img.get_width()
	var h := img.get_height()
	var light := c.lightened(0.45)
	match shape:
		"stand":
			var bw := maxi(6, int(w * 0.45))
			var bh := int(h * 0.75)
			var x0 := int((w - bw) * 0.5)
			var y0 := h - bh + (f % 2)
			_rect(img, x0, y0, bw, h - y0, c)
			_rect(img, x0, y0 - 3, 3, 3, c)
			_rect(img, x0 + bw - 3, y0 - 3, 3, 3, c)
			_rect(img, x0 + bw - 4, y0 + 3, 2, 2, light)
			_rect(img, x0 - 4, y0 + int(bh * 0.55), 4, 2, c)
			return {"body": Rect2i(x0, y0, bw, h - y0), "gun": Vector2i(x0 + int(bw * 0.5), y0 + int(bh * 0.3))}
		"walker":
			var bw := maxi(6, int(w * 0.5))
			var bh := int(h * 0.62)
			var x0 := int((w - bw) * 0.5)
			var y0 := h - bh - 5
			_rect(img, x0, y0, bw, bh, c)
			_rect(img, x0 + bw - 4, y0 + 3, 2, 2, light)
			var stride := 2 if f % 2 == 0 else -2
			_rect(img, x0 + 1 + stride, y0 + bh, 3, 5, c)
			_rect(img, x0 + bw - 4 - stride, y0 + bh, 3, 5, c)
			return {"body": Rect2i(x0, y0, bw, bh), "gun": Vector2i(x0 + bw - 2, y0 + int(bh * 0.4))}
		"quad":
			var bw := int(w * 0.72)
			var bh := maxi(5, int(h * 0.34))
			var x0 := int((w - bw) * 0.5) - 1
			var y0 := h - 3 - bh
			_rect(img, x0, y0, bw, bh, c)
			var hx := x0 + bw - 4
			_rect(img, hx, y0 - 5, 7, 8, c)
			_rect(img, hx, y0 - 8, 2, 3, c)
			_rect(img, hx + 5, y0 - 8, 2, 3, c)
			_rect(img, hx + 4, y0 - 3, 2, 2, light)
			var legs := [x0 + 1, x0 + 5, x0 + bw - 8, x0 + bw - 4]
			for i in legs.size():
				var off := 1 if (f + i) % 2 == 0 else -1
				_rect(img, legs[i] + off, y0 + bh, 2, 3, c)
			_rect(img, x0 - 4, y0 - 2 + (f % 2), 4, 2, c)
			return {"body": Rect2i(x0, y0, bw - 4, bh), "gun": Vector2i(hx + 2, y0)}
		"prone":
			var bw := int(w * 0.85)
			var bh := maxi(4, int(h * 0.25))
			var x0 := int((w - bw) * 0.5)
			var y0 := h - bh
			_rect(img, x0, y0, bw, bh, c)
			_rect(img, x0 + bw - 6, y0 - 3, 2, 3, c)
			_rect(img, x0 + bw - 2, y0 - 3, 2, 3, c)
			_rect(img, x0 + bw - 3, y0 + 1, 2, 2, light)
			return {"body": Rect2i(x0, y0, bw - 6, bh), "gun": Vector2i(x0 + bw - 4, y0 + 1)}
		"flat":
			var gray := c.lerp(Color(0.5, 0.5, 0.5), 0.6)
			var bw := int(w * 0.85)
			var x0 := int((w - bw) * 0.5)
			_rect(img, x0, h - 5, bw, 5, gray)
			PixelFont.draw_text(img, "X", Vector2i(x0 + bw - 5, h - 5), Color.BLACK)
			return {"body": Rect2i(x0, h - 5, bw, 5)}
		"ball":
			var r := int(minf(w, h) * 0.36)
			var center := Vector2i(int(w * 0.5), h - r - 2)
			_circle(img, center, r, c)
			var angle := TAU * float(f) / float(maxi(n, 1))
			var dot := Vector2(center) + Vector2(cos(angle), sin(angle)) * r * 0.55
			_rect(img, int(dot.x) - 1, int(dot.y) - 1, 3, 3, light)
			return {"body": Rect2i(center.x - r, center.y - r, r * 2, r * 2), "gun": center}
		"orb":
			var r := int(minf(w, h) * 0.5) - 1
			var center := Vector2i(int(w * 0.5), int(h * 0.5))
			_circle(img, center, maxi(r, 1), c)
			var angle := TAU * float(f) / float(maxi(n, 1))
			var hp := Vector2(center) + Vector2(cos(angle), sin(angle)) * r * 0.4
			img.set_pixelv(Vector2i(hp).clamp(Vector2i.ZERO, Vector2i(w - 1, h - 1)), light)
			return {"body": Rect2i(0, 0, w, h)}
		"bone":
			var mid := int(h * 0.5)
			_rect(img, 1, mid, w - 4, 1, c)
			for x in range(2, w - 4, 3):
				_rect(img, x, mid - 2, 1, 5, c)
			_rect(img, w - 4, mid - 1, 3, 3, light)
			return {"body": Rect2i(0, 0, w, h)}
		"turret":
			var base_h := int(h * 0.4)
			_rect(img, int(w * 0.1), h - base_h, w - int(w * 0.2), base_h, c.darkened(0.25))
			var center := Vector2i(int(w * 0.5), h - base_h)
			_circle(img, center, int(w * 0.3), c)
			if f % 2 == 1:
				_circle(img, Vector2i(center.x, 3), 3, Color(1, 0.9, 0.3))
			return {"body": Rect2i(int(w * 0.1), h - base_h, w - int(w * 0.2), base_h), "gun": center}
		"wing":
			var center := Vector2i(int(w * 0.5), int(h * 0.5))
			_ellipse(img, center, int(w * 0.28), int(h * 0.32), c)
			var wy := 1 if f % 2 == 0 else h - 5
			_rect(img, 1, wy, int(w * 0.3), 4, c.lightened(0.2))
			_rect(img, w - 1 - int(w * 0.3), wy, int(w * 0.3), 4, c.lightened(0.2))
			_rect(img, center.x + 3, center.y - 1, 2, 2, light)
			return {"body": Rect2i(center.x - int(w * 0.28), center.y - int(h * 0.32), int(w * 0.56), int(h * 0.64))}
		"flag_down", "flag_up":
			# Checkpoint: mástil con bandera abajo o izada (ondea por frame)
			_rect(img, 2, 2, 2, h - 2, Color("d8d8d8"))
			_rect(img, 0, h - 3, 7, 3, Color("707070"))
			var fy := h - 12 if shape == "flag_down" else 3
			var wave := f % 2
			_rect(img, 4, fy + wave, w - 5, 7, c)
			_rect(img, w - 3, fy + 1 - wave, 2, 5, c.darkened(0.2))
			return {"body": Rect2i()}
		"mech":
			# Perro mecha: cuerpo blindado, cabeza al frente, cañón en el lomo y 4 patas
			var bw := int(w * 0.62)
			var bh := int(h * 0.42)
			var x0 := int(w * 0.12)
			var y0 := h - 10 - bh
			var bob := f % 2
			_rect(img, x0, y0 + bob, bw, bh, c)
			_rect(img, x0 + 2, y0 + bob + 3, bw - 4, 2, c.darkened(0.3))
			var hx := x0 + bw - 2
			_rect(img, hx, y0 - 8 + bob, 16, 14, c.lightened(0.1))
			_rect(img, hx + 10, y0 + 6 + bob, 8, 4, c.darkened(0.2))
			_rect(img, hx + 4, y0 - 12 + bob, 4, 5, c)
			_rect(img, hx + 11, y0 - 4 + bob, 3, 3, Color(1, 0.2, 0.2))
			_rect(img, x0 + 8, y0 - 10, 8, 10, c.darkened(0.15))
			_rect(img, x0 + 10, y0 - 16, 4, 7, GUN_COLOR)
			for i in 4:
				var lx := x0 + 4 + i * int((bw - 10) / 3.0)
				var off := 2 if (f + i) % 2 == 0 else 0
				_rect(img, lx, y0 + bh + bob, 5, 10 - bob - off, c.darkened(0.35))
			_rect(img, x0 - 8, y0 + 2, 8, 3, c)
			return {"body": Rect2i(x0, y0 + bob, bw, bh), "gun": Vector2i(hx + 14, y0 + 2)}
		"head":
			# Ícono de vida: cabeza de gato con orejas
			_rect(img, 1, 2, w - 2, h - 2, c)
			_rect(img, 1, 0, 2, 2, c)
			_rect(img, w - 3, 0, 2, 2, c)
			img.set_pixel(3, 4, Color.BLACK)
			img.set_pixel(w - 4, 4, Color.BLACK)
			return {"body": Rect2i()}
		"pill":
			# Cápsula de pickup: caja redondeada con brillo que se mueve
			_rect(img, 1, 0, w - 2, h, c)
			_rect(img, 0, 1, w, h - 2, c)
			_rect(img, 2 + (f % 2) * (w - 6), 1, 2, 2, light)
			return {"body": Rect2i(0, 0, w, h)}
		"ring":
			# Escudo: anillo semitransparente que late
			var center := Vector2i(int(w * 0.5), int(h * 0.5))
			var r := int(minf(w, h) * 0.5) - 2 - (f % 2)
			var ring := Color(c, 0.85)
			for a in 64:
				var ang := TAU * a / 64.0
				var pt := Vector2(center) + Vector2(cos(ang), sin(ang)) * r
				_rect(img, int(pt.x), int(pt.y), 2, 2, ring)
			var spark := Vector2(center) + Vector2.RIGHT.rotated(TAU * f / maxf(n, 1)) * r
			_rect(img, int(spark.x) - 1, int(spark.y) - 1, 2, 2, Color.WHITE)
			return {"body": Rect2i()}
		_:
			_rect(img, 0, 0, w, h, c)
			return {"body": Rect2i(0, 0, w, h)}


func _draw_gun(img: Image, from: Vector2i, dir: Vector2) -> void:
	var length := int(img.get_width() * 0.4)
	for i in length:
		var p := Vector2(from) + dir * i
		_rect(img, int(p.x), int(p.y), 2, 2, GUN_COLOR)


# --- Tileset (tira de 5 tiles 16x16, ver TilesetFactory.Tile) -------------

func _generate_tiles() -> void:
	var tiles_dir := Catalog.level_dir(Catalog.DEFAULT_LEVEL) + "tiles"
	var path := tiles_dir + "/tileset.png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(tiles_dir))
	if not _force and FileAccess.file_exists(path):
		_skipped += 1
		return
	var t := 16
	var img := Image.create(t * 7, t, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var dirt := Color("8a5a32")
	var grass := Color("4caf50")
	var water := Color("2f6fd0")
	# 0: suelo con pasto, 1: relleno de tierra
	for i in 2:
		_rect(img, i * t, 0, t, t, dirt)
		for k in 6:
			img.set_pixel(i * t + rng.randi_range(1, 14), rng.randi_range(5 if i == 0 else 1, 14), dirt.darkened(0.3))
	_rect(img, 0, 0, t, 4, grass)
	for x in range(0, t, 3):
		img.set_pixel(x, 4, grass.darkened(0.2))
	_rect(img, 0, 0, t, 1, grass.lightened(0.3))
	# 2: plataforma one-way (tablón de 4px + soportes)
	var wood := Color("b07a3c")
	_rect(img, 2 * t, 0, t, 4, wood)
	_rect(img, 2 * t, 0, t, 1, wood.lightened(0.3))
	_rect(img, 2 * t, 3, t, 1, wood.darkened(0.4))
	_rect(img, 2 * t + 2, 4, 2, 5, wood.darkened(0.3))
	_rect(img, 2 * t + 12, 4, 2, 5, wood.darkened(0.3))
	# 3: superficie de agua, 4: agua profunda
	_rect(img, 3 * t, 4, t, t - 4, water)
	for x in t:
		if (x / 3) % 2 == 0:
			img.set_pixel(3 * t + x, 4, water.lightened(0.5))
	_rect(img, 4 * t, 0, t, t, water.darkened(0.2))
	for k in 4:
		img.set_pixel(4 * t + rng.randi_range(1, 14), rng.randi_range(1, 14), water.lightened(0.2))
	# 5: arena con superficie, 6: relleno de arena
	var sand := Color("e8cf8a")
	for i in [5, 6]:
		_rect(img, i * t, 0, t, t, sand.darkened(0.08 if i == 6 else 0.0))
		for k in 7:
			img.set_pixel(i * t + rng.randi_range(1, 14), rng.randi_range(2, 14), sand.darkened(0.25))
	_rect(img, 5 * t, 0, t, 2, sand.lightened(0.35))
	_save(img, path)


# --- Fondos parallax (384x216) ---------------------------------------------

func _generate_backgrounds() -> void:
	var dir := Catalog.level_dir(Catalog.DEFAULT_LEVEL) + "backgrounds"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var w := 384
	var h := 216
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var far_path := dir + "/far.png"
	if _force or not FileAccess.file_exists(far_path):
		# Capa lejana: cielo en degradé, sol, islas lejanas y mar
		var far := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var top := Color("4d8fd6")
		var bottom := Color("a8dcf5")
		for y in h:
			_rect(far, 0, y, w, 1, top.lerp(bottom, float(y) / h))
		_circle(far, Vector2i(300, 46), 14, Color("fff2a8"))
		for k in 6:
			var cx := rng.randi_range(0, w)
			_ellipse(far, Vector2i(cx, 128), rng.randi_range(30, 70), rng.randi_range(10, 22), Color("6a9a8c"))
		_rect(far, 0, 128, w, h - 128, Color("2f78c4"))
		for k in 40:
			_rect(far, rng.randi_range(0, w), rng.randi_range(132, h), rng.randi_range(3, 8), 1, Color("5d9ad8"))
		PixelFont.draw_text(far, "FAR", Vector2i(180, 70), Color(1, 1, 1, 0.5))
		_save(far, far_path)
	var near_path := dir + "/near.png"
	if _force or not FileAccess.file_exists(near_path):
		# Capa cercana: palmeras y arbustos (transparente arriba)
		var near := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var trunk := Color("6b4a2b")
		var leaf := Color("2e8b4a")
		for k in 5:
			var x := 30 + k * 76 + rng.randi_range(-10, 10)
			var top_y := rng.randi_range(70, 110)
			for y in range(top_y, h):
				_rect(near, x + int(sin(y * 0.05) * 3.0), y, 4, 1, trunk)
			for a in 5:
				var dir_v := Vector2.RIGHT.rotated(PI + a * PI / 4.0)
				for i in 18:
					var p := Vector2(x + 2, top_y) + dir_v * i + Vector2(0, i * i * 0.03)
					_rect(near, int(p.x), int(p.y), 3, 2, leaf)
		for k in 14:
			_ellipse(near, Vector2i(rng.randi_range(0, w), h - 8), rng.randi_range(14, 26), rng.randi_range(8, 14), leaf.darkened(0.2))
		PixelFont.draw_text(near, "NEAR", Vector2i(180, 78), Color(1, 1, 1, 0.5))
		_save(near, near_path)


# --- Utilidades de dibujo -------------------------------------------------

func _rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if r.has_area():
		img.fill_rect(r, color)


func _circle(img: Image, center: Vector2i, r: int, color: Color) -> void:
	_ellipse(img, center, r, r, color)


func _ellipse(img: Image, center: Vector2i, rx: int, ry: int, color: Color) -> void:
	for y in range(-ry, ry + 1):
		for x in range(-rx, rx + 1):
			var nx := float(x) / maxf(rx, 0.5)
			var ny := float(y) / maxf(ry, 0.5)
			if nx * nx + ny * ny <= 1.05:
				var p := center + Vector2i(x, y)
				if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
					img.set_pixelv(p, color)


func _outline(img: Image, color: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var src := img.duplicate() as Image
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in dirs:
				var p: Vector2i = Vector2i(x, y) + d
				if p.x >= 0 and p.y >= 0 and p.x < w and p.y < h and src.get_pixelv(p).a > 0.0:
					img.set_pixel(x, y, color)
					break


func _save(img: Image, path: String) -> void:
	var err := img.save_png(ProjectSettings.globalize_path(path))
	if err != OK:
		push_error("No se pudo guardar %s (%d)" % [path, err])
		return
	_created += 1
