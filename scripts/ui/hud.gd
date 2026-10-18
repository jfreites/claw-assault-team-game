class_name Hud
extends CanvasLayer
## HUD mínimo (se completa en la etapa 7): vidas, arma, poderes activos con
## temporizador, barra del jefe y mensajes centrales.

var _player: Player

@onready var info: Label = $Info
@onready var power: Label = $Power
@onready var message: Label = $Message
@onready var boss_bar: Control = $BossBar
@onready var boss_name: Label = $BossBar/Name
@onready var boss_fill: ColorRect = $BossBar/Fill
@onready var boss_back: ColorRect = $BossBar/Back


var _message_time := 0.0


func _ready() -> void:
	add_to_group("hud")
	message.visible = false
	boss_bar.visible = false
	power.text = ""
	GameState.lives_changed.connect(_on_lives_changed)
	_refresh()


func _process(delta: float) -> void:
	_refresh_powers()
	if _message_time > 0.0:
		_message_time -= delta
		if _message_time <= 0.0:
			message.visible = false


func bind_player(p: Player) -> void:
	_player = p
	p.weapon_holder.weapon_changed.connect(func(_w): _refresh())
	p.powers.power_started.connect(func(_p): _refresh_powers())
	p.powers.power_ended.connect(func(_p): _refresh_powers())
	_refresh()


func show_message(text: String) -> void:
	message.text = text
	message.visible = true
	_message_time = 0.0


## Mensaje central que se oculta solo
func flash_message(text: String, seconds: float) -> void:
	show_message(text)
	_message_time = seconds


func show_boss_bar(display_name: String) -> void:
	boss_name.text = display_name
	boss_fill.size.x = boss_back.size.x
	boss_bar.visible = true


func set_boss_health(current: int, max_health: int) -> void:
	boss_fill.size.x = boss_back.size.x * clampf(float(current) / maxf(max_health, 1), 0.0, 1.0)


func hide_boss_bar() -> void:
	boss_bar.visible = false


func _on_lives_changed(_lives: int) -> void:
	_refresh()


func _refresh() -> void:
	var text := "VIDAS x%d" % GameState.lives
	if _player and _player.weapon_holder.current:
		text += "   ARMA: %s" % _player.weapon_holder.current.display_name
	info.text = text


func _refresh_powers() -> void:
	if _player == null or not is_instance_valid(_player):
		power.text = ""
		return
	var parts: PackedStringArray = []
	for p: PowerUpData in _player.powers.get_active():
		parts.append("%s %.1fs" % [p.display_name.to_upper(), _player.powers.get_remaining(p)])
	power.text = "   ".join(parts)
