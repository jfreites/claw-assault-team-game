class_name ParallaxBackdrop
extends Node2D
## Fondo parallax de varias capas. Cada capa es un PNG (cargado vía SpriteLoader,
## así el arte se reemplaza sin tocar código) que se repite horizontalmente.

## Rutas de las texturas, de la más lejana a la más cercana
@export var textures: PackedStringArray = [
	"res://assets/sprites/backgrounds/far.png",
	"res://assets/sprites/backgrounds/near.png",
]
## Factor de desplazamiento horizontal de cada capa (0 = fija, 1 = como el mundo)
@export var scroll_factors: PackedFloat32Array = [0.15, 0.45]

const Loader := preload("res://scripts/autoload/sprite_loader.gd")


func _ready() -> void:
	z_index = -100
	for i in textures.size():
		var tex := Loader.load_texture(textures[i])
		if tex == null:
			continue
		var layer := Parallax2D.new()
		layer.scroll_scale = Vector2(scroll_factors[i] if i < scroll_factors.size() else 0.5, 0.0)
		layer.repeat_size = Vector2(tex.get_width(), 0)
		layer.repeat_times = 3
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.centered = false
		layer.add_child(sprite)
		add_child(layer)
