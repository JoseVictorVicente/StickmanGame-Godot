extends Node
## Toca SFX de combate sem cortar o som anterior.
## Pitch levemente aleatório para o ataque não ficar repetitivo.

const PITCH_MIN := 0.9
const PITCH_MAX := 1.1
const JOGADORES_INICIAIS := 6
const CAMINHO_AUDIO := "user://save.cfg"

var _som_ataque: AudioStream
var _som_dano: AudioStream
var _som_morte: AudioStream
var _som_moeda: AudioStream
var _pool: Array[AudioStreamPlayer2D] = []
var volume_linear: float = 1.0


func _ready() -> void:
	_carregar_volume()
	_aplicar_volume()
	_som_ataque = _carregar_ou_gerar("res://audio/ataque.wav", 420.0, 0.09)
	_som_dano = _carregar_ou_gerar("res://audio/dano.wav", 180.0, 0.12)
	_som_morte = _carregar_ou_gerar("res://audio/morte.wav", 90.0, 0.22)
	_som_moeda = _carregar_ou_gerar("res://audio/moeda.wav", 880.0, 0.08)
	for i in JOGADORES_INICIAIS:
		_pool.append(_criar_jogador())


func tocar_som_ataque() -> void:
	_tocar(_som_ataque, true)


func tocar_som_dano() -> void:
	_tocar(_som_dano, true)


func tocar_som_morte() -> void:
	_tocar(_som_morte, false)


func tocar_som_moeda() -> void:
	_tocar(_som_moeda, true)


func volume_percentual() -> int:
	return int(round(volume_linear * 100.0))


func definir_volume_percentual(valor: int) -> void:
	volume_linear = clampf(float(valor) / 100.0, 0.0, 1.0)
	_aplicar_volume()
	_salvar_volume()


func _aplicar_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	if volume_linear <= 0.001:
		AudioServer.set_bus_mute(bus, true)
		AudioServer.set_bus_volume_db(bus, -80.0)
	else:
		AudioServer.set_bus_mute(bus, false)
		AudioServer.set_bus_volume_db(bus, linear_to_db(volume_linear))


func _carregar_volume() -> void:
	if not FileAccess.file_exists(CAMINHO_AUDIO):
		return
	var cfg := ConfigFile.new()
	if cfg.load(CAMINHO_AUDIO) != OK:
		return
	volume_linear = clampf(float(cfg.get_value("audio", "volume", 1.0)), 0.0, 1.0)


func _salvar_volume() -> void:
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(CAMINHO_AUDIO):
		cfg.load(CAMINHO_AUDIO)
	cfg.set_value("audio", "volume", volume_linear)
	cfg.save(CAMINHO_AUDIO)


func _tocar(stream: AudioStream, variar_pitch: bool) -> void:
	if stream == null:
		return
	var player := _obter_jogador_livre()
	player.stream = stream
	player.pitch_scale = randf_range(PITCH_MIN, PITCH_MAX) if variar_pitch else 1.0
	player.play()


func _obter_jogador_livre() -> AudioStreamPlayer2D:
	for player in _pool:
		if not player.playing:
			return player
	var extra := _criar_jogador()
	_pool.append(extra)
	return extra


func _criar_jogador() -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()
	player.bus = "Master"
	player.max_distance = 100000.0
	add_child(player)
	return player


func _carregar_ou_gerar(caminho: String, frequencia: float, duracao: float) -> AudioStream:
	if ResourceLoader.exists(caminho):
		var recurso := load(caminho)
		if recurso is AudioStream:
			return recurso
	return _gerar_tom(frequencia, duracao)


func _gerar_tom(frequencia: float, duracao: float) -> AudioStreamWAV:
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
