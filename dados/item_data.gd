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
	RARO,
	EPICO,
	LENDARIO,
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

@export var id: String = ""
@export var nome: String = ""
@export var icone: Texture2D
@export var tipo: Tipo = Tipo.ARMA
@export var raridade: Raridade = Raridade.COMUM
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


func nome_raridade() -> String:
	match raridade:
		Raridade.RARO:
			return "Raro"
		Raridade.EPICO:
			return "Épico"
		Raridade.LENDARIO:
			return "Lendário"
		_:
			return "Comum"


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
	match raridade:
		Raridade.RARO:
			return Color(0.28, 0.52, 0.98, 1)
		Raridade.EPICO:
			return Color(0.68, 0.28, 0.92, 1)
		Raridade.LENDARIO:
			return Color(0.95, 0.78, 0.22, 1)
		_:
			return Color(0.78, 0.78, 0.82, 1)


func valor_desmonte() -> int:
	var base := 8
	match raridade:
		Raridade.RARO:
			base = 28
		Raridade.EPICO:
			base = 90
		Raridade.LENDARIO:
			base = 240
		_:
			base = 8
	return maxi(1, base + dano_bonus + vida_bonus)


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
	item.raridade = int(dados.get("raridade", Raridade.COMUM)) as Raridade
	item.dano_bonus = int(dados.get("dano_bonus", 0))
	item.vida_bonus = int(dados.get("vida_bonus", 0))
	item.classe_requerida = int(dados.get("classe_requerida", ClasseRequerida.TODAS)) as ClasseRequerida
	item.icone = item.gerar_icone()
	return item


func gerar_icone() -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cor := cor_raridade().lerp(_cor_tipo(), 0.4)
	for y in range(6, 26):
		for x in range(6, 26):
			img.set_pixel(x, y, cor)
	return ImageTexture.create_from_image(img)


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
