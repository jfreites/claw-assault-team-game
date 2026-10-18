class_name Hud
extends CanvasLayer
## HUD: vidas (íconos), arma actual (ícono + nombre), poderes activos con barra de tiempo,
## barra del jefe y mensajes centrales. Los íconos salen de SpriteLoader (arte reemplazable).

const LIFE_ENTITY := "ui/life"
const MAX_LIFE_ICONS := 9
const POWER_BAR_WIDTH := 48.0

var _player: Player
var _message_time := 0.0
var _power_rows: Dictionary = {}  # PowerUpData → {row, label, fill}

@onready var lives_box: HBoxContainer = $Lives
@onready var weapon_icon: TextureRect = $Weapon/Icon
@onready var weapon_name: Label = $Weapon/Name
@onready var powers_box: VBoxContainer = $Powers
@onready var message: Label = $Message
@onready var boss_bar: Control = $BossBar
@onready var boss_name: Label = $BossBar/Name
@onready var boss_fill: ColorRect = $BossBar/Fill
@onready var boss_back: ColorRect = $BossBar/Back


func _ready() -> void:
	add_to_group("hud")
	message.visible = false
	boss_bar.visible = false
	GameState.lives_changed.connect(_on_lives_changed)
	_refresh_lives()


func _process(delta: float) -> void:
	_update_power_rows()
	if _message_time > 0.0:
		_message_time -= delta
		if _message_time <= 0.0:
			message.visible = false


func bind_player(p: Player) -> void:
	_player = p
	p.weapon_holder.weapon_changed.connect(_on_weapon_changed)
	p.powers.power_started.connect(_add_power_row)
	p.powers.power_ended.connect(_remove_power_row)
	_on_weapon_changed(p.weapon_holder.current)


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
	boss_fill.size.x = boss_back.size.x - 2.0
	boss_bar.visible = true


func set_boss_health(current: int, max_health: int) -> void:
	boss_fill.size.x = (boss_back.size.x - 2.0) * clampf(float(current) / maxf(max_health, 1), 0.0, 1.0)


func hide_boss_bar() -> void:
	boss_bar.visible = false


## Texto de los poderes activos (para pruebas y depuración)
func get_power_text() -> String:
	var parts: PackedStringArray = []
	for power in _power_rows:
		parts.append(_power_rows[power].label.text)
	return "   ".join(parts)


# --- Vidas ----------------------------------------------------------------

func _on_lives_changed(_lives: int) -> void:
	_refresh_lives()


func _refresh_lives() -> void:
	for child in lives_box.get_children():
		child.queue_free()
	var tex := _icon(LIFE_ENTITY)
	for i in mini(GameState.lives, MAX_LIFE_ICONS):
		var icon := TextureRect.new()
		icon.texture = tex
		icon.stretch_mode = TextureRect.STRETCH_KEEP
		lives_box.add_child(icon)
	if GameState.lives > MAX_LIFE_ICONS:
		lives_box.add_child(_make_label("+%d" % (GameState.lives - MAX_LIFE_ICONS), Color.WHITE))


# --- Arma -----------------------------------------------------------------

func _on_weapon_changed(weapon: WeaponData) -> void:
	if weapon == null:
		return
	weapon_icon.texture = _icon(weapon.pickup_sprite)
	weapon_name.text = weapon.display_name.to_upper()


# --- Poderes --------------------------------------------------------------

func _add_power_row(power: PowerUpData) -> void:
	if _power_rows.has(power):
		return
	var color := power.tint if power.tint != Color.WHITE else Color(0.7, 0.9, 1.0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.alignment = BoxContainer.ALIGNMENT_END
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	var label := _make_label("", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var bar_back := ColorRect.new()
	bar_back.color = Color(0, 0, 0, 0.6)
	bar_back.custom_minimum_size = Vector2(POWER_BAR_WIDTH, 3)
	bar_back.size_flags_horizontal = Control.SIZE_SHRINK_END
	var fill := ColorRect.new()
	fill.color = color
	fill.size = Vector2(POWER_BAR_WIDTH, 3)
	bar_back.add_child(fill)
	column.add_child(label)
	column.add_child(bar_back)
	var icon := TextureRect.new()
	icon.texture = _icon(power.pickup_sprite)
	icon.stretch_mode = TextureRect.STRETCH_KEEP
	row.add_child(column)
	row.add_child(icon)
	powers_box.add_child(row)
	_power_rows[power] = {"row": row, "label": label, "fill": fill}
	_update_power_rows()


func _remove_power_row(power: PowerUpData) -> void:
	if _power_rows.has(power):
		_power_rows[power].row.queue_free()
		_power_rows.erase(power)


func _update_power_rows() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	for power: PowerUpData in _power_rows:
		var remaining := _player.powers.get_remaining(power)
		var row: Dictionary = _power_rows[power]
		row.label.text = "%s %.1fs" % [power.display_name.to_upper(), remaining]
		row.fill.size.x = POWER_BAR_WIDTH * clampf(remaining / maxf(power.duration, 0.01), 0.0, 1.0)


# --- Utilidades -----------------------------------------------------------

func _icon(entity: String) -> Texture2D:
	var frames := SpriteLoader.get_frames(entity)
	var anim := SpriteLoader.get_default_animation(entity, frames)
	return frames.get_frame_texture(anim, 0) if frames.get_frame_count(anim) > 0 else null


func _make_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	return label
