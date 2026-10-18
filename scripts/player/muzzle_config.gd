@tool
class_name MuzzleConfig
extends Resource
## Puntos de disparo del jugador, medidos desde su origen (los pies, centrado en x)
## y mirando a la DERECHA (el código espeja x al mirar a la izquierda).
## Son independientes del sprite: cambiar el arte no mueve la línea de disparo.
## idle, run, jump y fall comparten la misma altura horizontal; solo el estado
## echado y las direcciones diagonales/verticales usan offsets propios.

## Altura de la línea de disparo horizontal (px sobre los pies)
@export var horizontal_height := 14.0
## Distancia al frente desde la que sale la bala horizontal
@export var forward_distance := 14.0

@export_group("Diagonales y verticales")
@export var up := Vector2(2, -30)
@export var up_forward := Vector2(12, -24)
@export var down_forward := Vector2(12, -6)
## Solo se usa en el aire (en el suelo abajo = echarse)
@export var down := Vector2(0, -2)

@export_group("Echado")
## Disparo horizontal estando echado/agachado
@export var prone := Vector2(17, -4)

@export_group("Ajustes por estado")
## Desplazamiento extra por estado ("idle", "run", "jump", "fall", "prone"...),
## sumado a cualquier dirección. Vacío por defecto para que la línea sea idéntica.
@export var state_offsets: Dictionary = {}


## Offset local (pies → punto de disparo) para un estado y una dirección de apuntado.
## `aim` es la dirección normalizada; `facing` es 1 (derecha) o -1 (izquierda).
func get_offset(state_name: String, aim: Vector2, facing: int) -> Vector2:
	var offset := get_base_offset(state_name, aim)
	offset += state_offsets.get(state_name, Vector2.ZERO)
	offset.x *= facing
	return offset


## Offset mirando a la derecha, sin ajustes por estado
func get_base_offset(state_name: String, aim: Vector2) -> Vector2:
	if state_name == "prone":
		return prone
	if aim.y < -0.9:
		return up
	if aim.y > 0.9:
		return down
	if aim.y < 0.0:
		return up_forward
	if aim.y > 0.0:
		return down_forward
	return Vector2(forward_distance, -horizontal_height)


## Todos los puntos con nombre (para la guía del editor)
func get_named_points() -> Dictionary:
	return {
		"fwd": Vector2(forward_distance, -horizontal_height),
		"up": up, "up_fwd": up_forward, "dn_fwd": down_forward, "down": down, "prone": prone,
	}
