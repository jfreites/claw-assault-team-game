extends SceneTree
## Genera SFX placeholder (sintetizados, estilo 8 bits) para cada hook de AudioManager.
## Uso:
##   godot --headless --path . --script res://tools/generate_sfx.gd
##   godot --headless --path . --script res://tools/generate_sfx.gd -- --force
## Sin --force solo crea los que faltan: un .wav/.ogg/.mp3 real con el mismo nombre se respeta.

const DIR := "res://assets/audio/sfx/"
const RATE := 22050

## nombre → lista de capas {wave, f0, f1, dur, vol, [notes], [delay], [vibrato]}
## wave: square | triangle | noise. f0→f1: barrido de frecuencia. notes: arpegio (Hz) de `dur` c/u.
const SOUNDS := {
	"jump": [{"wave": "square", "f0": 280, "f1": 720, "dur": 0.12, "vol": 0.25}],
	"land": [{"wave": "noise", "f0": 900, "f1": 300, "dur": 0.07, "vol": 0.25}],
	"shoot": [{"wave": "square", "f0": 980, "f1": 280, "dur": 0.06, "vol": 0.18}],
	"shoot_yarn": [{"wave": "triangle", "f0": 520, "f1": 240, "dur": 0.1, "vol": 0.35}],
	"shoot_fishbone": [{"wave": "square", "f0": 1500, "f1": 600, "dur": 0.05, "vol": 0.16}],
	"shoot_spread": [{"wave": "square", "f0": 760, "f1": 220, "dur": 0.08, "vol": 0.16}, {"wave": "noise", "f0": 3000, "f1": 1500, "dur": 0.05, "vol": 0.12}],
	"bounce": [{"wave": "triangle", "f0": 380, "f1": 640, "dur": 0.05, "vol": 0.3}],
	"player_hurt": [{"wave": "square", "f0": 640, "f1": 70, "dur": 0.45, "vol": 0.3}, {"wave": "noise", "f0": 2000, "f1": 400, "dur": 0.2, "vol": 0.2}],
	"enemy_hit": [{"wave": "noise", "f0": 2500, "f1": 1200, "dur": 0.04, "vol": 0.22}],
	"enemy_die": [{"wave": "noise", "f0": 1600, "f1": 200, "dur": 0.28, "vol": 0.35}],
	"enemy_shoot": [{"wave": "square", "f0": 520, "f1": 360, "dur": 0.07, "vol": 0.14}],
	"enemy_bomb": [{"wave": "triangle", "f0": 320, "f1": 140, "dur": 0.14, "vol": 0.3}],
	"pickup_weapon": [{"wave": "square", "notes": [523, 659, 784, 1046], "dur": 0.06, "vol": 0.22}],
	"power_catnip": [{"wave": "square", "notes": [440, 554, 659, 880, 1108], "dur": 0.05, "vol": 0.22}],
	"power_milk": [{"wave": "triangle", "notes": [392, 523, 659, 784], "dur": 0.08, "vol": 0.4}],
	"shield_break": [{"wave": "noise", "f0": 4000, "f1": 800, "dur": 0.22, "vol": 0.3}, {"wave": "square", "f0": 1300, "f1": 200, "dur": 0.2, "vol": 0.15}],
	"checkpoint": [{"wave": "square", "notes": [659, 784, 988, 1318], "dur": 0.08, "vol": 0.22}],
	"menu_start": [{"wave": "square", "notes": [523, 784, 1046], "dur": 0.07, "vol": 0.25}],
	"boss_land": [{"wave": "noise", "f0": 700, "f1": 60, "dur": 0.6, "vol": 0.5}, {"wave": "triangle", "f0": 90, "f1": 40, "dur": 0.5, "vol": 0.5}],
	"boss_fan": [{"wave": "square", "f0": 320, "f1": 180, "dur": 0.1, "vol": 0.2}],
	"boss_charge": [{"wave": "square", "f0": 90, "f1": 420, "dur": 0.4, "vol": 0.22}],
	"boss_crash": [{"wave": "noise", "f0": 1200, "f1": 80, "dur": 0.4, "vol": 0.45}],
	"boss_mortar": [{"wave": "triangle", "f0": 220, "f1": 110, "dur": 0.16, "vol": 0.4}, {"wave": "noise", "f0": 900, "f1": 300, "dur": 0.08, "vol": 0.15}],
	"boss_hit": [{"wave": "square", "f0": 220, "f1": 180, "dur": 0.04, "vol": 0.18}],
	"boss_roar": [{"wave": "square", "f0": 160, "f1": 55, "dur": 0.9, "vol": 0.28, "vibrato": 18.0}, {"wave": "noise", "f0": 600, "f1": 150, "dur": 0.9, "vol": 0.15}],
	"armor_hit": [{"wave": "triangle", "f0": 1900, "f1": 1500, "dur": 0.04, "vol": 0.25}],
	"explosion": [{"wave": "noise", "f0": 1400, "f1": 120, "dur": 0.3, "vol": 0.35}],
	"boss_explode": [{"wave": "noise", "f0": 1600, "f1": 40, "dur": 1.3, "vol": 0.55}, {"wave": "triangle", "f0": 120, "f1": 30, "dur": 1.0, "vol": 0.5}],
	"stage_clear": [{"wave": "square", "notes": [523, 659, 784, 1046, 0, 784, 1046], "dur": 0.12, "vol": 0.22}],
}

var _force := false
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_force = OS.get_cmdline_user_args().has("--force")
	_rng.seed = 99
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var created := 0
	var skipped := 0
	for sfx_name: String in SOUNDS:
		if not _force and _has_audio(sfx_name):
			skipped += 1
			continue
		var stream := _synth(SOUNDS[sfx_name])
		var err := stream.save_to_wav(ProjectSettings.globalize_path(DIR + sfx_name + ".wav"))
		if err == OK:
			created += 1
		else:
			push_error("No se pudo guardar %s (%d)" % [sfx_name, err])
	print("SFX: %d creados, %d existentes respetados" % [created, skipped])
	quit()


func _has_audio(sfx_name: String) -> bool:
	for ext in ["wav", "ogg", "mp3"]:
		if FileAccess.file_exists("%s%s.%s" % [DIR, sfx_name, ext]):
			return true
	return false


func _synth(layers: Array) -> AudioStreamWAV:
	var total := 0.0
	for layer: Dictionary in layers:
		total = maxf(total, _layer_length(layer))
	var samples := PackedFloat32Array()
	samples.resize(int(total * RATE) + 1)
	for layer: Dictionary in layers:
		_render_layer(layer, samples)
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream


func _layer_length(layer: Dictionary) -> float:
	var notes: Array = layer.get("notes", [])
	return float(layer.dur) * maxi(notes.size(), 1)


func _render_layer(layer: Dictionary, out: PackedFloat32Array) -> void:
	var notes: Array = layer.get("notes", [])
	var segments: Array = []
	if notes.is_empty():
		segments.append([float(layer.get("f0", 440)), float(layer.get("f1", layer.get("f0", 440)))])
	else:
		for n in notes:
			segments.append([float(n), float(n)])
	var dur: float = layer.dur
	var vol: float = layer.vol
	var vibrato: float = layer.get("vibrato", 0.0)
	var wave: String = layer.wave
	var phase := 0.0
	var noise_value := 0.0
	var index := 0
	for seg: Array in segments:
		var count := int(dur * RATE)
		for i in count:
			var t := float(i) / count
			var f: float = lerpf(seg[0], seg[1], t)
			if vibrato > 0.0:
				f *= 1.0 + 0.06 * sin(TAU * vibrato * i / RATE)
			var env := (1.0 - t) * minf(1.0, i / (RATE * 0.003))  # ataque corto, caída lineal
			var prev_phase := phase
			phase = fmod(phase + f / RATE, 1.0)
			var v := 0.0
			if f > 0.0:
				match wave:
					"square":
						v = 1.0 if phase < 0.5 else -1.0
					"triangle":
						v = 4.0 * absf(phase - 0.5) - 1.0
					"noise":
						# Ruido "sample & hold": cambia de valor a la frecuencia dada
						if phase < prev_phase:
							noise_value = _rng.randf_range(-1.0, 1.0)
						v = noise_value
			if index < out.size():
				out[index] += v * vol * env
			index += 1
