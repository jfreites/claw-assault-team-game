class_name MenuScreen
extends Control
## Pantalla simple (título / victoria): texto parpadeante y START para continuar.

enum OnStart { START_GAME, GO_TO_TITLE }

@export var on_start: OnStart = OnStart.START_GAME
## Evita que una pulsación de la escena anterior se cuele
@export var input_delay := 0.4

var _time := 0.0
var _done := false

@onready var prompt: Label = $Prompt


func _process(delta: float) -> void:
	_time += delta
	prompt.visible = int(_time * 2.0) % 2 == 0
	if _done or _time < input_delay:
		return
	for action in ["start", "jump", "shoot", "ui_accept"]:
		if Input.is_action_just_pressed(action):
			_done = true
			AudioManager.play_sfx("menu_start")
			if on_start == OnStart.START_GAME:
				LevelManager.start_game()
			else:
				LevelManager.go_to_title()
			return
