#!/usr/bin/env python3
"""Gera arquivos .tres de habilidades para todas as classes."""

from pathlib import Path
import re
import unicodedata

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "data" / "skills"

ACTIVE_COOLDOWNS = [5.0, 16.0, 6.0, 10.0, 12.0]

CATALOG = {
    "arqueiro": {
        "active": [
            ("Tiro Duplo Instantaneo", "Executa dois disparos rapidos consecutivos com 200% de dano critico."),
            ("Voleio Sombrio", "Entra em postura de foco por 2 segundos e dispara uma rajada de 10 flechas energizadas em alta velocidade direto no alvo mais forte."),
            ("Tiro de Precisao", "Um disparo carregado de 0.4s que garante acerto critico e ignora 30% da armadura."),
            ("Postura do Cacador", "A Arqueira finca levemente os pes no chao e ganha um surto de 30% de Velocidade de Ataque e 10% de Dano Fisico por 3.5 segundos."),
            ("Visao Neon", "Seus olhos brilham em verde neon intenso, aumentando a Taxa de Acerto Critico em 30% e fazendo todas as flechas atravessarem o primeiro inimigo por 4 segundos."),
        ],
        "passive": [
            ("Penetracao de Armadura", "Ataques basicos e habilidades ignoram uma porcentagem da defesa de inimigos blindados ou chefes."),
            ("Recuo Reflexo", "Quando a vida do arqueiro fica abaixo de 25%, ele ganha um escudo temporario e um aumento drastico na velocidade de movimento por 3 segundos."),
            ("Execucao Acelerada", "Causa 20% a mais de dano contra inimigos que estejam com menos de 30% da vida maxima."),
            ("Maos Ageis", "Reduz o tempo de recarga (cooldown) de todas as habilidades ativas em 15%."),
            ("Olho de Aguia", "Aumenta a taxa de acerto critico e o alcance de visao na tela."),
            ("Cordeiro Esticado", "Reduz a animacao dos disparos frontais, aumentando a Velocidade de Ataque basica em 15%."),
            ("Veneno Desgastante", "Tem 5% de chance de aplicar veneno no ataque basico."),
            ("Caca aos Fracos", "Causa 15% a mais de dano contra monstros que estejam com menos de 25% da vida."),
            ("Impacto Acumulativo", "Cada flecha que atinge o mesmo alvo em menos de 2s aumenta o dano da proxima em 5% (max 25%)."),
            ("Mira Cirurgica", "Aumenta a Taxa de Acerto Critico em 30% contra alvos que estejam com a vida maior que 70%."),
        ],
    },
    "assassino": {
        "active": [
            ("Corte Duplo Executor", "Um ataque cruzado em X com as duas adagas. Causa o dobro de dano contra inimigos que estejam com menos de 30% da vida."),
            ("Marca da Presa", "Marca um alvo por 4 segundos. Todo o dano que o Assassino causar nesse periodo e acumulado e explode ao final do efeito, causando 30% de dano bonus equivalente ao total causado."),
            ("Corte Duplo Rapido", "Dois golpes cruzados ultra-rapidos com as adagas no peito do alvo."),
            ("Sequencia Desperta", "Ganha um surto imediato de 60% de Velocidade de Ataque que dura exatamente 4 golpes ou 3 segundos."),
            ("Decaptacao Celerada", "Um golpe alto mirado no pescoco que causa 50% de dano extra se o alvo estiver com menos de 30% de vida."),
        ],
        "passive": [
            ("Reflexos Sombrios", "Aumenta a taxa de Acerto Critico base e a Velocidade de Ataque."),
            ("Impulso de Adrenalina", "Eliminar um inimigo restaura 50% do tempo de recarga (cooldown) de todas as habilidades ativas."),
            ("Veia Venenosa", "Aumenta em 25% o dano de acerto critico contra alvos que estejam envenenados ou sangrando."),
            ("Ataque Furtivo", "O primeiro golpe disparado ao entrar em combate contra qualquer inimigo causa 50% de dano critico adicional."),
            ("Lethal Execution", "Ataques em alvos abaixo de 15% da vida maxima tem chance de causar execucao instantanea (exceto em chefes de fase)."),
            ("Corte Profundo", "Sangramentos aplicados pelas adagas duram 1.5s a mais."),
            ("Mapeamento de Pontos Frais", "Ignora 20% da armadura base dos inimigos."),
            ("Adrenalina", "Matar um inimigo reseta 1 segundo do cooldown de todas as habilidades ativas."),
            ("Ritmo Assassino", "Cada acerto de habilidade ativa adiciona um acumulo de 10% de Velocidade de Ataque (acumula ate 5 vezes, totalizando +50% por 4s)."),
            ("Lamina Leve", "Aumenta o dano em 10%."),
        ],
    },
    "sacerdote": {
        "active": [
            ("Posicao Sagrada", "Restaura uma porcentagem da vida do aliado com a menor vida na tela instantaneamente."),
            ("Escudo Solar", "Concede um escudo de luz brilhante ao aliado mais vulneravel que absorve dano por 3 segundos."),
            ("Punicao Divina", "Invoca um feixe de luz vertical do ceu que atinge o grupo mais denso de inimigos, causando dano elemental."),
            ("Aura de Inviolabilidade", "Cria um domo temporario de 1.5s que reduz todo o dano recebido pelo grupo em 15% e cura por segundo a equipe."),
            ("Fervor Sagrado", "O Priest ergue o cetro e canaliza uma aura brilhante, aumentando o dano de todo o grupo em 15% por 4 segundos."),
        ],
        "passive": [
            ("Toque do Sol", "Aumenta o poder de cura e a eficacia de todos os escudos aplicados em 20%."),
            ("Barreira Reativa", "Quando a vida do Priest cai abaixo de 30%, ele ganha automaticamente um escudo divino equivalente a 35% da sua vida maxima (cooldown de 30s)."),
            ("Presenca Iluminada", "Aliados proximos ganham 10% de resistencia a dano fisico e magico."),
            ("Devocao Inabalavel", "Reduz o tempo de recarga (cooldown) de todas as habilidades de cura e escudo em 15%."),
            ("Vigor Divino", "Converter excesso de cura (quando o aliado ja esta com vida cheia) em um pequeno escudo temporario."),
            ("Toque Sagrado", "Ataques basicos do Priest tem 15% de chance de aplicar uma pequena cura no aliado mais ferido."),
            ("Cura Critica", "As habilidades de cura do Priest tem 15% de chance de causar um Critico de Cura (cura o dobro do valor)."),
            ("Pacto Celestial", "Se o Priest morrer, libera uma onda de luz final que cura 100% da vida de um aliado aleatorio e congela a horda por 2s."),
            ("Luz Protetora", "Aliados curados pelo Priest ganham 10% de Armadura bonus por 3 segundos."),
            ("Misericordia", "Aumenta em 20% a quantidade de cura realizada em aliados que estejam com menos de 50% de vida."),
        ],
    },
    "guerreiro": {
        "active": [
            ("Sequencia Frenetica", "Desfere 3 cortes rapidos e profundos consecutivos em menos de 1 segundo."),
            ("Corte Rapido", "Um golpe horizontal simples e veloz com a espada que atinge os inimigos a frente."),
            ("Perfuracao Dupla", "Duas estocadas ultra-rapidas sem sair do lugar."),
            ("Lamina Pesada", "Um ataque lento e carregado de 0.5s que causa dano duplo."),
            ("Grito de Guerra", "Erguer a espada para cima e emite um pulso de poder que aumenta o Dano Fisico em 20% por 5 segundos."),
        ],
        "passive": [
            ("Mestre das Laminas", "Aumenta o Dano Fisico base e o alcance de corte da espada."),
            ("Afiacao Extrema", "Aumenta a taxa de Acerto Critico e o Dano Critico de todos os ataques de espada em 15%."),
            ("Armadura de Ferro", "Concede 15% de reducao de dano fisico direto vindo de ataques corpo a corpo."),
            ("Postura Inquebravel", "Confere imunidade a efeitos de atordoamento e empurrao (Knockback) enquanto estiver no meio da animacao de uma habilidade ativa."),
            ("Execucao Precisa", "Causa 20% a mais de dano contra alvos que estejam com menos de 35% da vida maxima."),
            ("Vontade de Ferro", "Ao ficar com menos de 25% de vida, ganha 30% de Velocidade de Ataque e 15% de Roubo de Vida (Lifesteal) por 5 segundos (60 segundos de cooldown)."),
            ("Postura de Defesa", "Ganha 10% de armadura extra enquanto estiver com menos de 50% de vida."),
            ("Forca Bruta", "Causa 10% a mais de dano contra inimigos do tipo Elite ou Chefes."),
            ("Resistencia Media", "Reduz todo o dano fisico recebido em 8%."),
            ("Musculos de Aco", "Aumenta a vida maxima do guerreiro em 10%."),
        ],
    },
    "mago": {
        "active": [
            ("Meteoro Abissal", "Evoca uma pedra magica do topo da tela que cai sobre o grupo mais denso de inimigos."),
            ("Portal de Dano", "Dispara um raio continuo de 1 segundo direto do cajado."),
            ("Bola de Fogo Negra", "Dispara uma grande esfera que causa dano em area no impacto."),
            ("Nova de Gelo", "Uma onda circular de gelo que congela tudo ao redor por 1s."),
            ("Lanca de Gelo", "Dispara uma estaca de gelo fina e rapida que atravessa ate 2 inimigos em linha reta."),
        ],
        "passive": [
            ("Amplificacao Arcana", "Aumenta o Dano Magico base e o Alcance de Ataque do cajado."),
            ("Ressoar de Runas", "Toda vez que uma habilidade ativa e disparada, concede 5% de Velocidade de Convocacao (cooldown reduction) por 3s (acumula ate 4 vezes)."),
            ("Penetracao Magica", "Suas magias ignoram 25% da resistencia magica/armadura dos inimigos e chefes."),
            ("Foco Critico", "Aumenta a chance de Acerto Critico Magico em 15% contra inimigos com mais de 70% da vida."),
            ("Dreno de Alma", "Matar um inimigo com qualquer magia restaura 5% da vida maxima do Mago instantaneamente."),
            ("Fluxo de Mana", "A cada 5 magias lancadas, a proxima causa 50% a mais de dano."),
            ("Sintonizacao", "Reduz em 0.1s o cooldown de todas as habilidades ao acertar um acerto critico."),
            ("Presenca do Vazio", "Inimigos na tela tem suas defesas reduzidas em 10% passivamente."),
            ("Mente Aberta", "Aumenta a taxa de acerto critico bonus contra alvos imobilizados ou congelados em 25%."),
            ("Sinfonia Elementar", "Alternar entre magias de elementos diferentes aumenta o dano geral em 5% (acumula ate 4 vezes)."),
        ],
    },
    "tanque": {
        "active": [
            ("Barreira de Runas", "Ganha um escudo magico de energia proporcional a 25% da sua vida maxima por 4 segundos."),
            ("Provocacao Sombria", "Forca todos os inimigos da tela a atacarem o Tank e converte 20% do dano recebido durante o efeito em vida."),
            ("Postura Inviolavel", "Trava as pernas e usa o escudo como parede, ficando totalmente imune a dano e controle de grupo por 2.5s."),
            ("Supressao Total", "Bate o escudo e a maca um contra o outro, emitindo um estrondo de metal que causa dano aos inimigos na area."),
            ("Moinho Esmagador", "Executa uma sequencia rapida de 3 golpes de maca alternados (esquerda, direita, cima)."),
        ],
        "passive": [
            ("Casca de Titanio", "Concede 5% de chance fixa de bloquear totalmente o dano de qualquer ataque."),
            ("Espinhos da Superficie", "Reflete 20% do dano fisico de ataques corpo a corpo recebidos na parte frontal do escudo."),
            ("Inabalavel", "Imunidade total a qualquer efeito de empurrao (knockback) causado por inimigos comuns ou projeteis leves."),
            ("Absorcao no Impacto", "Derrotar um inimigo usando uma habilidade com o escudo restaura 8% da vida maxima instantaneamente."),
            ("Liga Magica", "Aumenta a resistencia a danos elementais (fogo, veneno e magia)."),
            ("Ultima Trincheira", "Ao receber dano fatal, o Tank se esconde atras do escudo e fica totalmente invulneravel por 2 segundos (cooldown longo / 1 vez por fase)."),
            ("Peso Pesado", "Golpes de maca tem 15% de chance fixa de atordoar inimigos comuns por 0.5s a cada impacto."),
            ("Inercia de Batalha", "Cada golpe acertado com a maca concede 3% de armadura bonus por 4 segundos (acumula ate 5 vezes)."),
            ("Casca Dura", "Reduz em 20% o dano recebido de ataques criticos."),
            ("Esmagamento Vital", "Inimigos atingidos por habilidades de maca perdem 10% da armadura por 4 segundos."),
        ],
    },
}


def slugify(text: str) -> str:
    text = unicodedata.normalize("NFKD", text)
    text = text.encode("ascii", "ignore").decode("ascii")
    text = re.sub(r"[^a-zA-Z0-9]+", "_", text).strip("_").lower()
    return text


def write_tres(path: Path, skill_id: str, name: str, desc: str, tipo: int, cooldown: float, sort_order: int, classe: str) -> None:
    icon_path = f"res://sprites/ui/skills/{classe}/{skill_id}.png"
    content = f"""[gd_resource type="Resource" script_class="SkillResource" load_steps=2 format=3]

[ext_resource type="Script" path="res://data/skill_resource.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
skill_id = "{skill_id}"
skill_name = "{name}"
description = "{desc}"
type = {tipo}
cooldown = {cooldown}
icon_path = "{icon_path}"
sort_order = {sort_order}
stat_value = 0.0
"""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def main() -> None:
    for classe, grupos in CATALOG.items():
        pasta = OUT / classe
        if pasta.exists():
            for arquivo in pasta.glob("*.tres"):
                arquivo.unlink()
        for indice, (nome, desc) in enumerate(grupos["active"], start=1):
            skill_id = slugify(nome)
            write_tres(
                pasta / f"{indice:02d}_{skill_id}.tres",
                skill_id,
                nome,
                desc,
                0,
                ACTIVE_COOLDOWNS[indice - 1],
                indice,
                classe,
            )
        for indice, (nome, desc) in enumerate(grupos["passive"], start=1):
            skill_id = slugify(nome)
            write_tres(
                pasta / f"p{indice:02d}_{skill_id}.tres",
                skill_id,
                nome,
                desc,
                1,
                0.0,
                indice,
                classe,
            )
    print("Gerados recursos de habilidades para", len(CATALOG), "classes.")


if __name__ == "__main__":
    main()
