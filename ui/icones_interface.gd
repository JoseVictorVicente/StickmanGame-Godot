class_name IconesInterface
extends RefCounted
## Ícones recortados da interface de referência.

const PASTA := "res://sprites/ui/"

static var _cache: Dictionary = {}


static func slot_equipamento(tipo: ItemData.Tipo) -> Texture2D:
	var arquivo := ""
	match tipo:
		ItemData.Tipo.ARMA:
			arquivo = "arma.png"
		ItemData.Tipo.SECUNDARIA:
			arquivo = "secundaria.png"
		ItemData.Tipo.CAPACETE:
			arquivo = "capacete.png"
		ItemData.Tipo.PEITORAL:
			arquivo = "peitoral.png"
		ItemData.Tipo.LUVA:
			arquivo = "luva.png"
		ItemData.Tipo.CALCA:
			arquivo = "calca.png"
		ItemData.Tipo.BOTA:
			arquivo = "bota.png"
		ItemData.Tipo.CINTO:
			arquivo = "cinto.png"
		ItemData.Tipo.PINGENTE:
			arquivo = "pingente.png"
		ItemData.Tipo.ANEL:
			arquivo = "anel.png"
		ItemData.Tipo.BRACELETE:
			arquivo = "bracelete.png"
		ItemData.Tipo.PET:
			arquivo = "pet.png"
		_:
			arquivo = "arma.png"
	return _carregar(arquivo)


static func barra(nome: String) -> Texture2D:
	return _carregar("nav_%s.png" % nome)


static func _carregar(arquivo: String) -> Texture2D:
	if _cache.has(arquivo):
		return _cache[arquivo]
	var tex := load(PASTA + arquivo) as Texture2D
	_cache[arquivo] = tex
	return tex
