class_name ItemData
extends Resource
## Resource de item (equipamento) usado pelo inventário e pelo banco de dados.

enum Tipo {
	CAPACETE,
	PEITORAL,
	ARMA,
	SECUNDARIA,
	LUVA,
	CALCA,
	BOTA,
	CINTO,
	PINGENTE,
	ANEL,
	BRACELETE,
	PET,
}

enum Raridade {
	COMUM,
	INCOMUM,
	RARO,
	EPICO,
	LENDARIO,
	MITICO,
	PRIMORDIAL,
	ASTRAL,
	DIVINO,
	TRANSCENDENTAL,
}

enum ClasseRequerida {
	TODAS,
	GUERREIRO,
	MAGO,
	ARQUEIRO,
	ASSASSINO,
	TANQUE,
	SACERDOTE,
}

enum Categoria {
	EQUIPAMENTO,
	ACESSORIO,
}

const NIVEIS_ITEM: Array[int] = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 70, 80]

@export var id: String = ""
@export var nome: String = ""
@export var icone: Texture2D
@export var tipo: Tipo = Tipo.ARMA
@export var raridade: Raridade = Raridade.COMUM
@export var nivel_item: int = 5
@export var dano_bonus: int = 0
@export var vida_bonus: int = 0
@export var classe_requerida: ClasseRequerida = ClasseRequerida.TODAS


func descricao() -> String:
	return texto_tooltip()


func texto_tooltip() -> String:
	var linhas: PackedStringArray = [
		nome,
		nome_raridade(),
		"Dano Bônus: +%d" % dano_bonus,
	]
	if vida_bonus != 0:
		linhas.append("Vida Bônus: +%d" % vida_bonus)
	if classe_requerida != ClasseRequerida.TODAS:
		linhas.append("Classe: %s" % nome_classe_requerida())
	linhas.append("Nível: %d" % nivel_item)
	linhas.append("Valor: %d ouro" % valor_desmonte())
	return "\n".join(linhas)


func nome_tipo() -> String:
	match tipo:
		Tipo.CAPACETE:
			return "Capacete"
		Tipo.PEITORAL:
			return "Peitoral"
		Tipo.ARMA:
			return "Arma"
		Tipo.SECUNDARIA:
			return "Secundaria"
		Tipo.LUVA:
			return "Luva"
		Tipo.CALCA:
			return "Calca"
		Tipo.BOTA:
			return "Bota"
		Tipo.CINTO:
			return "Cinto"
		Tipo.PINGENTE:
			return "Pingente"
		Tipo.ANEL:
			return "Anel"
		Tipo.BRACELETE:
			return "Bracelete"
		Tipo.PET:
			return "Pet"
		_:
			return "Item"


func categoria() -> Categoria:
	return categoria_do_tipo(tipo)


static func categoria_do_tipo(p_tipo: Tipo) -> Categoria:
	match p_tipo:
		Tipo.CINTO, Tipo.PINGENTE, Tipo.ANEL, Tipo.BRACELETE:
			return Categoria.ACESSORIO
		_:
			return Categoria.EQUIPAMENTO


static func nome_categoria(p_categoria: Categoria) -> String:
	match p_categoria:
		Categoria.ACESSORIO:
			return "Acessório"
		_:
			return "Equipamento"


static func tipos_da_categoria(p_categoria: Categoria) -> Array[Tipo]:
	var lista: Array[Tipo] = []
	for tipo_valor in Tipo.values():
		if categoria_do_tipo(tipo_valor as Tipo) == p_categoria:
			lista.append(tipo_valor as Tipo)
	return lista


func nome_raridade() -> String:
	return nome_de_raridade(raridade)


static func nome_de_raridade(p_raridade: Raridade) -> String:
	match p_raridade:
		Raridade.INCOMUM:
			return "Incomum"
		Raridade.RARO:
			return "Raro"
		Raridade.EPICO:
			return "Épico"
		Raridade.LENDARIO:
			return "Lendário"
		Raridade.MITICO:
			return "Mítico"
		Raridade.PRIMORDIAL:
			return "Primordial"
		Raridade.ASTRAL:
			return "Astral"
		Raridade.DIVINO:
			return "Divino"
		Raridade.TRANSCENDENTAL:
			return "Transcendental"
		_:
			return "Comum"


static func nomes_filtro_ferraria() -> PackedStringArray:
	var nomes := PackedStringArray(["Todos"])
	for i in Raridade.size():
		nomes.append(nome_de_raridade(i as Raridade))
	return nomes


static func raridade_maxima() -> Raridade:
	return Raridade.TRANSCENDENTAL


static func eh_raridade_maxima(p_raridade: Raridade) -> bool:
	return p_raridade >= Raridade.TRANSCENDENTAL


static func proxima_raridade(p_raridade: Raridade) -> Raridade:
	if eh_raridade_maxima(p_raridade):
		return p_raridade
	return (int(p_raridade) + 1) as Raridade


static func chance_forja_sucesso(p_raridade: Raridade) -> float:
	match p_raridade:
		Raridade.COMUM, Raridade.INCOMUM, Raridade.RARO:
			return 1.0
		Raridade.EPICO:
			return 0.9
		Raridade.LENDARIO:
			return 0.5
		Raridade.MITICO:
			return 0.45
		Raridade.PRIMORDIAL:
			return 0.4
		Raridade.ASTRAL:
			return 0.35
		Raridade.DIVINO:
			return 0.3
		Raridade.TRANSCENDENTAL:
			return 0.25
		_:
			return 1.0


static func chance_forja_sucesso_pct(p_raridade: Raridade) -> int:
	return int(round(chance_forja_sucesso(p_raridade) * 100.0))


static func migrar_raridade_salva(valor: int) -> Raridade:
	if valor >= 0 and valor <= 3:
		var legado: Array[Raridade] = [
			Raridade.COMUM,
			Raridade.RARO,
			Raridade.EPICO,
			Raridade.LENDARIO,
		]
		return legado[valor]
	return clampi(valor, 0, int(Raridade.TRANSCENDENTAL)) as Raridade


static func multiplicador_stats(p_raridade: Raridade) -> float:
	return pow(1.22, float(int(p_raridade)))


static func normalizar_nivel_item(valor: int) -> int:
	if NIVEIS_ITEM.has(valor):
		return valor
	var melhor := NIVEIS_ITEM[0]
	var menor_dist := absi(valor - melhor)
	for nivel in NIVEIS_ITEM:
		var dist := absi(valor - nivel)
		if dist < menor_dist:
			menor_dist = dist
			melhor = nivel
	return melhor


static func indice_nivel_item(nivel: int) -> int:
	var normalizado := normalizar_nivel_item(nivel)
	var indice := NIVEIS_ITEM.find(normalizado)
	return indice if indice >= 0 else 0


static func multiplicador_nivel_item(nivel: int) -> float:
	return pow(1.088, float(indice_nivel_item(nivel)))


static func nivel_item_maximo(progresso: int) -> int:
	var maximo := NIVEIS_ITEM[0]
	for nivel in NIVEIS_ITEM:
		if nivel <= progresso + 4:
			maximo = nivel
	return maximo


static func sortear_nivel_item(progresso: int) -> int:
	var maximo := nivel_item_maximo(maxi(1, progresso))
	var opcoes: Array[int] = []
	for nivel in NIVEIS_ITEM:
		if nivel <= maximo:
			opcoes.append(nivel)
	if opcoes.is_empty():
		return NIVEIS_ITEM[0]
	var pesos: Array[float] = []
	var total := 0.0
	for i in opcoes.size():
		var peso := pow(0.62, float(opcoes.size() - 1 - i))
		pesos.append(peso)
		total += peso
	var rolagem := randf() * total
	var acumulado := 0.0
	for i in opcoes.size():
		acumulado += pesos[i]
		if rolagem <= acumulado:
			return opcoes[i]
	return opcoes[0]


func pode_equipar(nivel_heroi: int) -> bool:
	return nivel_heroi >= normalizar_nivel_item(nivel_item)


func nome_classe_requerida() -> String:
	match classe_requerida:
		ClasseRequerida.GUERREIRO:
			return "Guerreiro"
		ClasseRequerida.MAGO:
			return "Mago"
		ClasseRequerida.ARQUEIRO:
			return "Arqueiro"
		ClasseRequerida.ASSASSINO:
			return "Assassino"
		ClasseRequerida.TANQUE:
			return "Tanque"
		ClasseRequerida.SACERDOTE:
			return "Sacerdote"
		_:
			return "Todas"


func cor_raridade() -> Color:
	return cor_de_raridade(raridade)


static func cor_de_raridade(p_raridade: Raridade) -> Color:
	match p_raridade:
		Raridade.INCOMUM:
			return Color(0.35, 0.85, 0.42, 1)
		Raridade.RARO:
			return Color(0.28, 0.52, 0.98, 1)
		Raridade.EPICO:
			return Color(0.68, 0.28, 0.92, 1)
		Raridade.LENDARIO:
			return Color(0.95, 0.78, 0.22, 1)
		Raridade.MITICO:
			return Color(0.95, 0.52, 0.18, 1)
		Raridade.PRIMORDIAL:
			return Color(0.92, 0.22, 0.22, 1)
		Raridade.ASTRAL:
			return Color(0.28, 0.88, 0.92, 1)
		Raridade.DIVINO:
			return Color(0.92, 0.22, 0.78, 1)
		Raridade.TRANSCENDENTAL:
			return Color(1.0, 0.45, 0.82, 1)
		_:
			return Color(0.92, 0.92, 0.95, 1)


func valor_desmonte() -> int:
	var bases: Array[int] = [8, 14, 28, 90, 240, 600, 1500, 3800, 9500, 24000]
	var indice := clampi(int(raridade), 0, bases.size() - 1)
	return maxi(1, bases[indice] + dano_bonus + vida_bonus)


func sigla_tipo() -> String:
	return sigla_do_tipo(tipo)


static func sigla_do_tipo(p_tipo: Tipo) -> String:
	match p_tipo:
		Tipo.ARMA:
			return "ESP"
		Tipo.SECUNDARIA:
			return "ADG"
		Tipo.CAPACETE:
			return "CAP"
		Tipo.PEITORAL:
			return "PEI"
		Tipo.LUVA:
			return "LUV"
		Tipo.CALCA:
			return "CAL"
		Tipo.BOTA:
			return "BOT"
		Tipo.CINTO:
			return "CIN"
		Tipo.PINGENTE:
			return "PIN"
		Tipo.ANEL:
			return "ANL"
		Tipo.BRACELETE:
			return "BRA"
		Tipo.PET:
			return "PET"
		_:
			return "ITM"


func para_dicionario() -> Dictionary:
	return {
		"id": id,
		"nome": nome,
		"tipo": int(tipo),
		"raridade": int(raridade),
		"nivel_item": nivel_item,
		"dano_bonus": dano_bonus,
		"vida_bonus": vida_bonus,
		"classe_requerida": int(classe_requerida),
	}


static func de_dicionario(dados: Dictionary) -> ItemData:
	if dados.is_empty():
		return null
	var item := ItemData.new()
	item.id = str(dados.get("id", ""))
	item.nome = str(dados.get("nome", ""))
	item.tipo = int(dados.get("tipo", Tipo.ARMA)) as Tipo
	item.raridade = migrar_raridade_salva(int(dados.get("raridade", Raridade.COMUM)))
	item.nivel_item = normalizar_nivel_item(int(dados.get("nivel_item", NIVEIS_ITEM[0])))
	item.dano_bonus = int(dados.get("dano_bonus", 0))
	item.vida_bonus = int(dados.get("vida_bonus", 0))
	item.classe_requerida = int(dados.get("classe_requerida", ClasseRequerida.TODAS)) as ClasseRequerida
	item.icone = item.gerar_icone()
	return item


func gerar_icone() -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(6, 26):
		for x in range(6, 26):
			var cor := _cor_icone_pixel(x, y)
			img.set_pixel(x, y, cor)
	return ImageTexture.create_from_image(img)


func _cor_icone_pixel(x: int, y: int) -> Color:
	if raridade == Raridade.TRANSCENDENTAL:
		var matiz := fmod(float(x + y) * 0.08 + float(x - y) * 0.05, 1.0)
		return Color.from_hsv(matiz, 0.85, 1.0, 1.0).lerp(_cor_tipo(), 0.25)
	var cor := cor_raridade().lerp(_cor_tipo(), 0.4)
	return cor


func _cor_tipo() -> Color:
	match tipo:
		Tipo.ARMA:
			return Color(0.55, 0.58, 0.65)
		Tipo.SECUNDARIA:
			return Color(0.45, 0.38, 0.28)
		Tipo.CAPACETE:
			return Color(0.5, 0.32, 0.18)
		Tipo.PEITORAL:
			return Color(0.35, 0.4, 0.5)
		Tipo.ANEL:
			return Color(0.75, 0.62, 0.2)
		_:
			return Color(0.6, 0.55, 0.45)
