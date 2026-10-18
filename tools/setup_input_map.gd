extends SceneTree
## Escribe el Input Map (teclado + gamepad) en project.godot.
## Uso: godot --headless --path . --script res://tools/setup_input_map.gd
## Después se puede seguir editando desde Project Settings > Input Map.

const STICK_DEADZONE := 0.5


func _initialize() -> void:
	# Movimiento: WASD / flechas / cruceta / stick izquierdo
	_action("move_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_action("move_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_action("move_up", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1.0]])
	_action("crouch", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	# Acciones: K/Z/Espacio saltar, J/X disparar, L/C/Shift fijar dirección
	_action("jump", [KEY_K, KEY_Z, KEY_SPACE], [JOY_BUTTON_A], [])
	_action("shoot", [KEY_J, KEY_X], [JOY_BUTTON_X, JOY_BUTTON_B], [[JOY_AXIS_TRIGGER_RIGHT, 1.0]])
	_action("lock_aim", [KEY_L, KEY_C, KEY_SHIFT], [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER], [])
	# Depuración: cambiar de arma
	_action("debug_next_weapon", [KEY_TAB], [JOY_BUTTON_BACK], [])
	var err := ProjectSettings.save()
	print("Input map guardado en project.godot (err=%d)" % err)
	quit()


func _action(action: String, keys: Array, buttons: Array, axes: Array) -> void:
	var events := []
	for key in keys:
		var ev := InputEventKey.new()
		ev.device = -1
		ev.physical_keycode = key
		events.append(ev)
	for button in buttons:
		var ev := InputEventJoypadButton.new()
		ev.device = -1
		ev.button_index = button
		events.append(ev)
	for axis in axes:
		var ev := InputEventJoypadMotion.new()
		ev.device = -1
		ev.axis = axis[0]
		ev.axis_value = axis[1]
		events.append(ev)
	ProjectSettings.set_setting("input/" + action, {"deadzone": STICK_DEADZONE, "events": events})
