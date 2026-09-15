class_name GerenciadorDrops
extends RefCounted
## Ouro com variação e chance de drop via ItemDatabase.

const CHANCE_DROP := 0.30
const VARIACAO_OURO := 0.15


func ouro_com_variacao(ouro_base: int) -> int:
	var fator := randf_range(1.0 - VARIACAO_OURO, 1.0 + VARIACAO_OURO)
	return maxi(1, int(round(float(ouro_base) * fator)))


func tentar_drop_item(nivel_inimigo: int) -> ItemData:
	if randf() > CHANCE_DROP:
		return null
	return ItemDatabase.gerar_item_aleatorio(nivel_inimigo)
