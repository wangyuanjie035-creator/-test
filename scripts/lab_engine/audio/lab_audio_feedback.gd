class_name LabAudioFeedback
extends Node

const MIX_RATE := 22050
const POOL_SIZE := 5
const CUE_CATALOG_SCRIPT := preload("res://scripts/lab_engine/audio/lab_audio_cue_catalog.gd")

var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _cues: Dictionary[StringName, Resource] = {}
var _sounds: Dictionary[StringName, AudioStreamWAV] = {}
var _important_player: AudioStreamPlayer

func _ready() -> void:
	_ensure_sfx_bus()
	for _index: int in range(POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = &"SFX"
		player.volume_db = -9.0
		add_child(player)
		_players.append(player)
	_important_player = AudioStreamPlayer.new()
	_important_player.bus = &"SFX"
	add_child(_important_player)
	_cues = CUE_CATALOG_SCRIPT.new().build_cues()
	for cue_id: StringName in _cues:
		var cue: Resource = _cues[cue_id]
		_sounds[cue_id] = _make_tone(cue.get(&"frequencies"), float(cue.get(&"duration")), float(cue.get(&"amplitude")))

func play_success() -> void:
	_play(&"success")

func play_failure() -> void:
	_play(&"failure")

func play_combo(level: int) -> void:
	_play(&"combo", level)

func play_breakthrough() -> void:
	_play(&"breakthrough")

func play_victory() -> void:
	_play(&"victory")

func _play(sound_id: StringName, level: int = 0) -> void:
	if _players.is_empty() or not _sounds.has(sound_id) or not _cues.has(sound_id):
		return
	var cue: Resource = _cues[sound_id]
	var boost := minf(float(cue.get(&"max_level_boost_db")), maxf(0.0, level - 2) * float(cue.get(&"level_volume_step_db")))
	var volume_db := float(cue.get(&"volume_db")) + boost
	if bool(cue.get(&"important")):
		_play_important(sound_id, volume_db)
		return
	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = _sounds[sound_id]
	player.volume_db = volume_db
	player.play()

func _play_important(sound_id: StringName, volume_db: float) -> void:
	if _important_player == null or not _sounds.has(sound_id):
		return
	_important_player.stream = _sounds[sound_id]
	_important_player.volume_db = volume_db
	_important_player.play()

func _make_tone(frequencies: Array[float], duration: float, amplitude: float) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	var sample_count: int = int(duration * MIX_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count * 2)
	for sample_index: int in range(sample_count):
		var time: float = float(sample_index) / MIX_RATE
		var section: int = mini(frequencies.size() - 1, int(float(sample_index) / sample_count * frequencies.size()))
		var envelope: float = minf(1.0, time / 0.006) * minf(1.0, (duration - time) / 0.018)
		var sample_value: int = int(sin(TAU * frequencies[section] * time) * amplitude * envelope * 32767.0)
		var unsigned_value: int = sample_value & 0xffff
		data[sample_index * 2] = unsigned_value & 0xff
		data[sample_index * 2 + 1] = (unsigned_value >> 8) & 0xff
	stream.data = data
	return stream

func _ensure_sfx_bus() -> void:
	if AudioServer.get_bus_index("SFX") >= 0:
		return
	AudioServer.lock()
	AudioServer.add_bus()
	var bus_index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, "SFX")
	AudioServer.set_bus_send(bus_index, "Master")
	AudioServer.unlock()
