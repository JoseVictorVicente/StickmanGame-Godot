extends Node
## Toca SFX de combat_root sem cortar o som anterior.
## Pitch levemente aleatório para o ataque não ficar repetitivo.

const PITCH_MIN := 0.9
const PITCH_MAX := 1.1
const INITIAL_PLAYERS := 6
const AUDIO_PATH := "user://save.cfg"

var _som_ataque: AudioStream
var _damage_sound: AudioStream
var _som_morte: AudioStream
var _som_moeda: AudioStream
var _pool: Array[AudioStreamPlayer2D] = []
var volume_linear: float = 1.0


func _ready() -> void:
	_load_volume()
	_apply_volume()
	_som_ataque = _load_or_generate("res://audio/ataque.wav", 420.0, 0.09)
	_damage_sound = _load_or_generate("res://audio/dano.wav", 180.0, 0.12)
	_som_morte = _load_or_generate("res://audio/morte.wav", 90.0, 0.22)
	_som_moeda = _load_or_generate("res://audio/moeda.wav", 880.0, 0.08)
	for i in INITIAL_PLAYERS:
		_pool.append(_create_player())


func play_attack_sound() -> void:
	_play(_som_ataque, true)


func play_hit_sound() -> void:
	_play(_damage_sound, true)


func play_death_sound() -> void:
	_play(_som_morte, false)


func play_coin_sound() -> void:
	_play(_som_moeda, true)


func get_volume_percent() -> int:
	return int(round(volume_linear * 100.0))


func set_volume_percent(valor: int) -> void:
	volume_linear = clampf(float(valor) / 100.0, 0.0, 1.0)
	_apply_volume()
	_save_volume()


func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	if volume_linear <= 0.001:
		AudioServer.set_bus_mute(bus, true)
		AudioServer.set_bus_volume_db(bus, -80.0)
	else:
		AudioServer.set_bus_mute(bus, false)
		AudioServer.set_bus_volume_db(bus, linear_to_db(volume_linear))


func _load_volume() -> void:
	if not FileAccess.file_exists(AUDIO_PATH):
		return
	var cfg := ConfigFile.new()
	if cfg.load(AUDIO_PATH) != OK:
		return
	volume_linear = clampf(float(cfg.get_value("audio", "volume", 1.0)), 0.0, 1.0)


func _save_volume() -> void:
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(AUDIO_PATH):
		cfg.load(AUDIO_PATH)
	cfg.set_value("audio", "volume", volume_linear)
	cfg.save(AUDIO_PATH)


func _play(stream: AudioStream, variar_pitch: bool) -> void:
	if stream == null:
		return
	var player := _get_free_player()
	player.stream = stream
	player.pitch_scale = randf_range(PITCH_MIN, PITCH_MAX) if variar_pitch else 1.0
	player.play()


func _get_free_player() -> AudioStreamPlayer2D:
	for player in _pool:
		if not player.playing:
			return player
	var extra := _create_player()
	_pool.append(extra)
	return extra


func _create_player() -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()
	player.bus = "Master"
	player.max_distance = 100000.0
	add_child(player)
	return player


func _load_or_generate(caminho: String, frequencia: float, duracao: float) -> AudioStream:
	if ResourceLoader.exists(caminho):
		var recurso := load(caminho)
		if recurso is AudioStream:
			return recurso
	return _generate_tone(frequencia, duracao)


func _generate_tone(frequencia: float, duracao: float) -> AudioStreamWAV:
	var taxa := 22050
	var amostras := int(taxa * duracao)
	var bytes := PackedByteArray()
	bytes.resize(amostras * 2)
	for i in amostras:
		var t := float(i) / taxa
		var envelope := 1.0 - (t / duracao)
		var amostra := int(sin(t * frequencia * TAU) * 12000.0 * envelope)
		bytes[i * 2] = amostra & 0xFF
		bytes[i * 2 + 1] = (amostra >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = taxa
	stream.stereo = false
	stream.data = bytes
	return stream
