extends Node
## AudioManager (autoload): punto único para SFX y música.
## play_sfx("jump") busca assets/audio/sfx/jump.(wav|ogg|mp3). Si no existe, no suena nada:
## basta con soltar el archivo con ese nombre para enchufar el audio real.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const EXTENSIONS := ["wav", "ogg", "mp3"]
const POOL_SIZE := 12

var sfx_volume_db := 0.0
var music_volume_db := -6.0

var _cache: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)
	_music = AudioStreamPlayer.new()
	add_child(_music)


func play_sfx(sfx_name: String, volume_db := 0.0, pitch := 1.0) -> void:
	if sfx_name.is_empty():
		return
	var stream := _get_stream(SFX_DIR, sfx_name)
	if stream == null:
		return
	var player := _pool[_next]
	_next = (_next + 1) % _pool.size()
	player.stream = stream
	player.volume_db = sfx_volume_db + volume_db
	player.pitch_scale = pitch
	player.play()


func play_music(music_name: String) -> void:
	var stream := _get_stream(MUSIC_DIR, music_name)
	if stream == null or _music.stream == stream and _music.playing:
		return
	_music.stream = stream
	_music.volume_db = music_volume_db
	_music.play()


func stop_music() -> void:
	_music.stop()


func _get_stream(dir: String, sound_name: String) -> AudioStream:
	var key := dir + sound_name
	if _cache.has(key):
		return _cache[key]
	var stream: AudioStream = null
	for ext in EXTENSIONS:
		var path := "%s%s.%s" % [dir, sound_name, ext]
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	_cache[key] = stream
	return stream
