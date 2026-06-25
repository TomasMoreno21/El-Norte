extends Node

# AudioManager - Gestión centralizada de audio para El Norte
# Permite reproducir SFX y música desde cualquier script mediante AudioManager.play_sfx() y AudioManager.play_music()

enum SoundType { SFX, MUSIC }

# Definición de rutas de audio (Placeholders - El usuario los llenará)
const SOUNDS := {
	"flap": "res://audio/sfx/flap.wav",
	"collect": "res://audio/sfx/collect.wav",
	"hit": "res://audio/sfx/hit.wav",
	"storm_start": "res://audio/sfx/storm_start.wav",
	"storm_end": "res://audio/sfx/storm_end.wav",
	"kiwi_appear": "res://audio/sfx/kiwi_appear.wav",
	"revive": "res://audio/sfx/revive.wav",
	"achievement": "res://audio/sfx/achievement.wav",
	"wind_ambient": "res://audio/sfx/sonido de viento.mp3",
	"buy": "res://audio/sfx/sonido de compra.mp3",
	"popup": "res://audio/sfx/sonido de popup logro.mp3",
	"storm_wind": "res://audio/sfx/sonido de viento de tormenta.mp3",
}

const MUSIC := {
	"cordillera": "res://audio/music/cordillera.ogg",
	"llanuras": "res://audio/music/llanuras.ogg",
	"puna": "res://audio/music/puna.ogg",
}

var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _storm_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8

func _ready() -> void:
	# Configurar reproductor de música
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	# Configurar reproductor de ambiente (loop)
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "SFX"
	add_child(_ambient_player)

	# Configurar reproductor de viento de tormenta
	_storm_player = AudioStreamPlayer.new()
	_storm_player.bus = "SFX"
	_storm_player.volume_db = -80.0
	add_child(_storm_player)
	
	# Configurar pool de SFX para permitir sonidos solapados
	for i in range(SFX_POOL_SIZE):
		var asp := AudioStreamPlayer.new()
		asp.bus = "SFX"
		add_child(asp)
		_sfx_pool.append(asp)

## Reproduce un efecto de sonido breve
func play_sfx(sound_name: String) -> void:
	if not DataManager.sound_enabled:
		return
	if not SOUNDS.has(sound_name):
		push_warning("AudioManager: Sound name '%s' not found in SOUNDS dictionary." % sound_name)
		return
		
	# Buscar un reproductor disponible en el pool (que no esté reproduciendo)
	var player = _get_available_sfx_player()
	
	var stream = load(SOUNDS[sound_name])
	if stream is AudioStream:
		player.stream = stream
		player.play()
	else:
		push_error("AudioManager: Failed to load stream for '%s' at %s" % [sound_name, SOUNDS[sound_name]])

## Reproduce un SFX incluso cuando el árbol está pausado
func play_sfx_unpaused(sound_name: String) -> void:
	if not SOUNDS.has(sound_name):
		return
	var p := AudioStreamPlayer.new()
	p.process_mode = PROCESS_MODE_WHEN_PAUSED
	p.bus = "SFX"
	add_child(p)
	var stream = load(SOUNDS[sound_name])
	if stream is AudioStream:
		p.stream = stream
		p.play()
		await p.finished
	p.queue_free()

## Reproduce música de fondo con crossfade simple
func play_music(track_name: String, fade_time: float = 1.0) -> void:
	if not DataManager.sound_enabled:
		return
	if not MUSIC.has(track_name):
		push_warning("AudioManager: Music track '%s' not found in MUSIC dictionary." % track_name)
		return
		
	var stream = load(MUSIC[track_name])
	if not stream is AudioStream:
		push_error("AudioManager: Failed to load music stream for '%s' at %s" % [track_name, MUSIC[track_name]])
		return
	
	# Si ya está sonando la misma pista, no hacer nada
	if _music_player.stream == stream:
		return
		
	# Fade out y cambio de pista
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -80.0, fade_time)
	tween.tween_callback(func(): 
		_music_player.stream = stream
		_music_player.play()
	)
	tween.tween_property(_music_player, "volume_db", 0.0, fade_time)

func stop_music(fade_time: float = 1.0) -> void:
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -80.0, fade_time)
	tween.tween_callback(func(): _music_player.stop())

func start_ambient_wind() -> void:
	if not DataManager.sound_enabled:
		return
	var stream = load(SOUNDS["wind_ambient"])
	if stream is AudioStream:
		_enable_loop(stream)
		_ambient_player.stream = stream
		_ambient_player.volume_db = -24.0
		_ambient_player.play()

func stop_ambient_wind() -> void:
	_ambient_player.stop()

func _enable_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream.has_method("set_loop"):
		stream.set_loop(true)

func start_storm_wind(fade_time: float = 0.3) -> void:
	if not DataManager.sound_enabled:
		return
	stop_ambient_wind()
	var stream = load(SOUNDS["storm_wind"])
	if stream is AudioStream:
		_enable_loop(stream)
		_storm_player.stream = stream
		_storm_player.volume_db = -80.0
		_storm_player.play()
		var tw := create_tween()
		tw.tween_property(_storm_player, "volume_db", -6.0, fade_time)

func stop_storm_wind(fade_time: float = 0.3) -> void:
	var tw := create_tween()
	tw.tween_property(_storm_player, "volume_db", -80.0, fade_time)
	tw.tween_callback(func():
		_storm_player.stop()
		start_ambient_wind()
	)

func _get_available_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_pool:
		if not p.playing:
			return p
	# Si todos están ocupados, reutilizar el primero (el más antiguo)
	return _sfx_pool[0]
