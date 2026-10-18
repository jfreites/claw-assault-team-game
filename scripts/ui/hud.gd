class_name Hud
extends CanvasLayer
## HUD mínimo (se completa en la etapa 7): vidas, arma actual y mensajes centrales.

var _player: Player

@onready var info: Label = $Info
@onready var message: Label = $Message


func _ready() -> void:
	message.visible = false
	GameState.lives_changed.connect(_on_lives_changed)
	_refresh()


func bind_player(p: Player) -> void:
	_player = p
	p.weapon_holder.weapon_changed.connect(func(_w): _refresh())
	_refresh()


func show_message(text: String) -> void:
	message.text = text
	message.visible = true


func _on_lives_changed(_lives: int) -> void:
	_refresh()


func _refresh() -> void:
	var text := "VIDAS x%d" % GameState.lives
	if _player and _player.weapon_holder.current:
		text += "   ARMA: %s" % _player.weapon_holder.current.display_name
	info.text = text
