class_name Hud
extends CanvasLayer
## HUD mínimo (se completa en la etapa 7): vidas y mensajes centrales.

var _player: Player

@onready var info: Label = $Info
@onready var message: Label = $Message


func _ready() -> void:
	message.visible = false
	GameState.lives_changed.connect(_on_lives_changed)
	_refresh()


func bind_player(p: Player) -> void:
	_player = p
	_refresh()


func show_message(text: String) -> void:
	message.text = text
	message.visible = true


func _on_lives_changed(_lives: int) -> void:
	_refresh()


func _refresh() -> void:
	info.text = "VIDAS x%d" % GameState.lives
