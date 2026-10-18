extends Node
## GameState (autoload): vidas, checkpoint y datos globales de la partida.

signal lives_changed(lives: int)
signal game_over

const START_LIVES := 3

var lives := START_LIVES
## Posición del último checkpoint; INF = usar el inicio del nivel
var checkpoint_position := Vector2.INF
## true mientras la escena se recarga tras perder una vida
var respawning := false
## Límite inferior del nivel actual (lo fija Level); por debajo todo muere
var level_bottom_y := 10000.0


func reset_run() -> void:
	lives = START_LIVES
	checkpoint_position = Vector2.INF
	respawning = false
	lives_changed.emit(lives)


func has_checkpoint() -> bool:
	return checkpoint_position != Vector2.INF


func set_checkpoint(pos: Vector2) -> void:
	checkpoint_position = pos


## Resta una vida. Devuelve true si aún quedan vidas.
func lose_life() -> bool:
	lives = maxi(lives - 1, 0)
	lives_changed.emit(lives)
	if lives <= 0:
		game_over.emit()
		return false
	return true
