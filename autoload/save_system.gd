extends Node
## Persistência de ouro, progresso, inventário e equipamentos.

const CAMINHO_SAVE := "user://save.cfg"
const INTERVALO_AUTOSAVE := 30.0

var _jogo: Node = null
var _timer: Timer


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	_timer = Timer.new()
	_timer.wait_time = INTERVALO_AUTOSAVE
	_timer.autostart = true
	_timer.timeout.connect(salvar)
	add_child(_timer)


func registrar(jogo: Node) -> void:
	_jogo = jogo


func _notification(o_que: int) -> void:
	if o_que == NOTIFICATION_WM_CLOSE_REQUEST:
		salvar()
		get_tree().quit()


func salvar() -> void:
	if _jogo == null or not is_instance_valid(_jogo):
		return
	if not _jogo.has_method("coletar_save"):
		return
	var dados: Dictionary = _jogo.coletar_save()
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(CAMINHO_SAVE):
		cfg.load(CAMINHO_SAVE)
	cfg.set_value("jogo", "ouro", int(dados.get("ouro", 0)))
	cfg.set_value("jogo", "onda", int(dados.get("onda", 1)))
	cfg.set_value("jogo", "mundo", int(dados.get("mundo", 1)))
	cfg.set_value("jogo", "fase", int(dados.get("fase", 1)))
	cfg.set_value("jogo", "dificuldade", int(dados.get("dificuldade", 0)))
	cfg.set_value("jogo", "fases_liberadas", JSON.stringify(dados.get("fases_liberadas", [1, 1, 1])))
	cfg.set_value("jogo", "repetir_fase", bool(dados.get("repetir_fase", false)))
	cfg.set_value("jogo", "personagem_atual", int(dados.get("personagem_atual", 0)))
	cfg.set_value("progresso", "personagens", JSON.stringify(dados.get("progresso", [])))
	cfg.set_value("inventario", "itens", JSON.stringify(dados.get("inventario", [])))
	cfg.set_value("inventario", "armazem", JSON.stringify(dados.get("armazem", [])))
	cfg.set_value("equipamentos", "dados", JSON.stringify(dados.get("equipamentos", [])))
	cfg.set_value("equipe", "dados", JSON.stringify(dados.get("equipe", {})))
	var erro := cfg.save(CAMINHO_SAVE)
	if erro != OK:
		push_warning("Falha ao salvar o jogo: %s" % erro)


func carregar() -> bool:
	if _jogo == null or not is_instance_valid(_jogo):
		return false
	if not FileAccess.file_exists(CAMINHO_SAVE):
		return false
	var cfg := ConfigFile.new()
	if cfg.load(CAMINHO_SAVE) != OK:
		return false
	var dados := {
		"ouro": int(cfg.get_value("jogo", "ouro", 0)),
		"onda": int(cfg.get_value("jogo", "onda", 1)),
		"mundo": int(cfg.get_value("jogo", "mundo", 1)),
		"fase": int(cfg.get_value("jogo", "fase", 1)),
		"dificuldade": int(cfg.get_value("jogo", "dificuldade", 0)),
		"fases_liberadas": _parse_json(str(cfg.get_value("jogo", "fases_liberadas", "[1,1,1]")), [1, 1, 1]),
		"repetir_fase": bool(cfg.get_value("jogo", "repetir_fase", false)),
		"personagem_atual": int(cfg.get_value("jogo", "personagem_atual", 0)),
		"progresso": _parse_json(str(cfg.get_value("progresso", "personagens", "[]")), []),
		"inventario": _parse_json(str(cfg.get_value("inventario", "itens", "[]")), []),
		"armazem": _parse_json(str(cfg.get_value("inventario", "armazem", "[]")), []),
		"equipamentos": _parse_json(str(cfg.get_value("equipamentos", "dados", "[]")), []),
		"equipe": _parse_json(str(cfg.get_value("equipe", "dados", "{}")), {}),
	}
	if _jogo.has_method("aplicar_save"):
		_jogo.aplicar_save(dados)
		return true
	return false


func _parse_json(texto: String, padrao: Variant) -> Variant:
	var resultado: Variant = JSON.parse_string(texto)
	return resultado if resultado != null else padrao
