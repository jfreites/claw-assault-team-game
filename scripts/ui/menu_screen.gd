class_name MenuScreen
extends Control
## Pantalla simple (título / game over / victoria): texto parpadeante y START para continuar.

enum OnStart { START_GAME, GO_TO_TITLE, RETRY_LEVEL }

@export var on_start: OnStart = OnStart.START_GAME
## Evita que una pulsación de la escena anterior se cuele
@export var input_delay := 0.4
## Escribe el nombre del nivel actual en el nodo LevelName (si existe)
@export var show_level_name := false
## Música opcional de la pantalla (assets/audio/music)
@export var music := ""

var _time := 0.0
var _done := false

@onready var prompt: Label = $Prompt


func _ready() -> void:
	var level_label := get_node_or_null("LevelName") as Label
	if show_level_name and level_label and LevelManager.current_level():
		level_label.text = LevelManager.current_level().get_display_name().to_upper()
	if music != "":
		AudioManager.play_music(music)
	else:
		AudioManager.stop_music()


func _process(delta: float) -> void:
	_time += delta
	prompt.visible = int(_time * 2.0) % 2 == 0
	if _done or _time < input_delay:
		return
	for action in ["start", "jump", "shoot", "ui_accept"]:
		if Input.is_action_just_pressed(action):
			_done = true
			AudioManager.play_sfx("menu_start")
			match on_start:
				OnStart.START_GAME:
					LevelManager.start_game()
				OnStart.RETRY_LEVEL:
					LevelManager.retry_current_level()
				_:
					LevelManager.go_to_title()
			return
