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
}

const MUSIC := {
	"cordillera": "res://audio/music/cordillera.ogg",
	"llanuras": "res://audio/music/llanuras.ogg",
	"puna": "res://audio/music/puna.ogg",
}

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8

func _ready() -> void:
	# Configurar reproductor de música
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)
	
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

func _get_available_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_pool:
		if not p.playing:
			return p
	# Si todos están ocupados, reutilizar el primero (el más antiguo)
	return _sfx_pool[0]
