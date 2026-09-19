"""Shared skill catalog (PT display + EN i18n) for generate_skills.py and gen_locales.py."""

ACTIVE_COOLDOWNS = [5.0, 16.0, 6.0, 10.0, 12.0]

# (pt_name, pt_desc, en_name, en_desc)
ACTIVE_ID_OVERRIDES: dict[str, list[str]] = {
    "archer": [
        "instant_double_shot",
        "dark_volley",
        "precision_shot",
        "hunter_stance",
        "neon_vision",
    ],
}

ICON_INNER_ONLY: dict[str, set[str]] = {
    "archer": {"precision_shot", "hunter_stance"},
}

CATALOG: dict[str, dict[str, list[tuple[str, str, str, str]]]] = {
    "archer": {
        "active": [
            ("Tiro Duplo Instantaneo", "Executa dois disparos rapidos consecutivos com 200% de dano critico.", "Instant Double Shot", "Fires two rapid consecutive shots with 200% critical damage."),
            ("Voleio Sombrio", "Entra em postura de foco por 2 segundos e dispara uma rajada de 10 flechas energizadas em alta velocidade direto no alvo mais forte.", "Dark Volley", "Enters focus stance for 2 seconds and fires a burst of 10 energized arrows at the strongest target."),
            ("Tiro de Precisao", "Um disparo carregado de 0.4s que garante acerto critico e ignora 30% da armadura.", "Precision Shot", "A 0.4s charged shot that guarantees a critical hit and ignores 30% armor."),
            ("Postura do Cacador", "A Arqueira finca levemente os pes no chao e ganha um surto de 30% de Velocidade de Ataque e 10% de Dano Fisico por 3.5 segundos.", "Hunter Stance", "Plants feet lightly and gains 30% Attack Speed and 10% Physical Damage for 3.5 seconds."),
            ("Visao Neon", "Seus olhos brilham em verde neon intenso, aumentando a Taxa de Acerto Critico em 30% e fazendo todas as flechas atravessarem o primeiro inimigo por 4 segundos.", "Neon Vision", "Eyes glow intense neon green, increasing Critical Hit Rate by 30% and making all arrows pierce the first enemy for 4 seconds."),
        ],
        "passive": [
            ("Penetracao de Armadura", "Ataques basicos e habilidades ignoram uma porcentagem da defesa de inimigos blindados ou chefes.", "Armor Penetration", "Basic attacks and skills ignore a portion of armored or boss enemy defense."),
            ("Recuo Reflexo", "Quando a vida do arqueiro fica abaixo de 25%, ele ganha um escudo temporario e um aumento drastico na velocidade de movimento por 3 segundos.", "Reflex Recoil", "When HP drops below 25%, gains a temporary shield and a large movement speed boost for 3 seconds."),
            ("Execucao Acelerada", "Causa 20% a mais de dano contra inimigos que estejam com menos de 30% da vida maxima.", "Swift Execution", "Deals 20% more damage to enemies below 30% max HP."),
            ("Maos Ageis", "Reduz o tempo de recarga (cooldown) de todas as habilidades ativas em 15%.", "Nimble Hands", "Reduces cooldown of all active skills by 15%."),
            ("Olho de Aguia", "Aumenta a taxa de acerto critico e o alcance de visao na tela.", "Eagle Eye", "Increases critical hit rate and on-screen vision range."),
            ("Cordeiro Esticado", "Reduz a animacao dos disparos frontais, aumentando a Velocidade de Ataque basica em 15%.", "Drawstring Tension", "Reduces frontal shot animation time, increasing basic Attack Speed by 15%."),
            ("Veneno Desgastante", "Tem 5% de chance de aplicar veneno no ataque basico.", "Wearing Poison", "5% chance to apply poison on basic attacks."),
            ("Caca aos Fracos", "Causa 15% a mais de dano contra monstros que estejam com menos de 25% da vida.", "Weak Prey", "Deals 15% more damage to monsters below 25% HP."),
            ("Impacto Acumulativo", "Cada flecha que atinge o mesmo alvo em menos de 2s aumenta o dano da proxima em 5% (max 25%).", "Stacking Impact", "Each arrow hitting the same target within 2s increases next hit damage by 5% (max 25%)."),
            ("Mira Cirurgica", "Aumenta a Taxa de Acerto Critico em 30% contra alvos que estejam com a vida maior que 70%.", "Surgical Aim", "Increases Critical Hit Rate by 30% against targets above 70% HP."),
        ],
    },
    "assassin": {
        "active": [
            ("Corte Duplo Executor", "Um ataque cruzado em X com as duas adagas. Causa o dobro de dano contra inimigos que estejam com menos de 30% da vida.", "Twin Execution Cut", "An X-shaped cross slash with both daggers. Deals double damage to enemies below 30% HP."),
            ("Marca da Presa", "Marca um alvo por 4 segundos. Todo o dano que o Assassino causar nesse periodo e acumulado e explode ao final do efeito, causando 30% de dano bonus equivalente ao total causado.", "Prey Mark", "Marks a target for 4 seconds. Damage dealt is stored and explodes for 30% bonus damage at the end."),
            ("Corte Duplo Rapido", "Dois golpes cruzados ultra-rapidos com as adagas no peito do alvo.", "Quick Twin Cut", "Two ultra-fast cross strikes to the target's chest."),
            ("Sequencia Desperta", "Ganha um surto imediato de 60% de Velocidade de Ataque que dura exatamente 4 golpes ou 3 segundos.", "Awakened Sequence", "Gains an immediate 60% Attack Speed surge for 4 hits or 3 seconds."),
            ("Decaptacao Celerada", "Um golpe alto mirado no pescoco que causa 50% de dano extra se o alvo estiver com menos de 30% de vida.", "Swift Decapitation", "A high neck strike dealing 50% extra damage if the target is below 30% HP."),
        ],
        "passive": [
            ("Reflexos Sombrios", "Aumenta a taxa de Acerto Critico base e a Velocidade de Ataque.", "Shadow Reflexes", "Increases base Critical Hit Rate and Attack Speed."),
            ("Impulso de Adrenalina", "Eliminar um inimigo restaura 50% do tempo de recarga (cooldown) de todas as habilidades ativas.", "Adrenaline Surge", "Killing an enemy restores 50% cooldown on all active skills."),
            ("Veia Venenosa", "Aumenta em 25% o dano de acerto critico contra alvos que estejam envenenados ou sangrando.", "Venomous Vein", "Increases critical damage by 25% against poisoned or bleeding targets."),
            ("Ataque Furtivo", "O primeiro golpe disparado ao entrar em combate contra qualquer inimigo causa 50% de dano critico adicional.", "Stealth Strike", "First hit when entering combat deals 50% additional critical damage."),
            ("Lethal Execution", "Ataques em alvos abaixo de 15% da vida maxima tem chance de causar execucao instantanea (exceto em chefes de fase).", "Lethal Execution", "Attacks on targets below 15% max HP may instantly execute (except stage bosses)."),
            ("Corte Profundo", "Sangramentos aplicados pelas adagas duram 1.5s a mais.", "Deep Cut", "Bleeds from daggers last 1.5s longer."),
            ("Mapeamento de Pontos Frais", "Ignora 20% da armadura base dos inimigos.", "Weak Point Mapping", "Ignores 20% of enemy base armor."),
            ("Adrenalina", "Matar um inimigo reseta 1 segundo do cooldown de todas as habilidades ativas.", "Adrenaline", "Killing an enemy resets 1 second of cooldown on all active skills."),
            ("Ritmo Assassino", "Cada acerto de habilidade ativa adiciona um acumulo de 10% de Velocidade de Ataque (acumula ate 5 vezes, totalizando +50% por 4s).", "Assassin Rhythm", "Each active skill hit adds 10% Attack Speed (stacks up to 5 times, +50% for 4s)."),
            ("Lamina Leve", "Aumenta o dano em 10%.", "Light Blade", "Increases damage by 10%."),
        ],
    },
    "priest": {
        "active": [
            ("Posicao Sagrada", "Restaura uma porcentagem da vida do aliado com a menor vida na tela instantaneamente.", "Sacred Position", "Instantly restores a portion of the lowest-HP ally's health."),
            ("Escudo Solar", "Concede um escudo de luz brilhante ao aliado mais vulneravel que absorve dano por 3 segundos.", "Solar Shield", "Grants a bright light shield to the most vulnerable ally, absorbing damage for 3 seconds."),
            ("Punicao Divina", "Invoca um feixe de luz vertical do ceu que atinge o grupo mais denso de inimigos, causando dano elemental.", "Divine Punishment", "Calls a vertical beam of light on the densest enemy group, dealing elemental damage."),
            ("Aura de Inviolabilidade", "Cria um domo temporario de 1.5s que reduz todo o dano recebido pelo grupo em 15% e cura por segundo a equipe.", "Inviolability Aura", "Creates a 1.5s dome that reduces all party damage taken by 15% and heals over time."),
            ("Fervor Sagrado", "O Priest ergue o cetro e canaliza uma aura brilhante, aumentando o dano de todo o grupo em 15% por 4 segundos.", "Sacred Fervor", "Raises the staff and channels a bright aura, increasing party damage by 15% for 4 seconds."),
        ],
        "passive": [
            ("Toque do Sol", "Aumenta o poder de cura e a eficacia de todos os escudos aplicados em 20%.", "Sun Touch", "Increases healing power and shield effectiveness by 20%."),
            ("Barreira Reativa", "Quando a vida do Priest cai abaixo de 30%, ele ganha automaticamente um escudo divino equivalente a 35% da sua vida maxima (cooldown de 30s).", "Reactive Barrier", "When HP drops below 30%, automatically gains a divine shield equal to 35% max HP (30s cooldown)."),
            ("Presenca Iluminada", "Aliados proximos ganham 10% de resistencia a dano fisico e magico.", "Radiant Presence", "Nearby allies gain 10% physical and magic damage resistance."),
            ("Devocao Inabalavel", "Reduz o tempo de recarga (cooldown) de todas as habilidades de cura e escudo em 15%.", "Unshakable Devotion", "Reduces cooldown of all heal and shield skills by 15%."),
            ("Vigor Divino", "Converter excesso de cura (quando o aliado ja esta com vida cheia) em um pequeno escudo temporario.", "Divine Vigor", "Converts overheal into a small temporary shield."),
            ("Toque Sagrado", "Ataques basicos do Priest tem 15% de chance de aplicar uma pequena cura no aliado mais ferido.", "Sacred Touch", "Priest basic attacks have 15% chance to heal the most wounded ally."),
            ("Cura Critica", "As habilidades de cura do Priest tem 15% de chance de causar um Critico de Cura (cura o dobro do valor).", "Critical Heal", "Priest heal skills have 15% chance to critically heal (double value)."),
            ("Pacto Celestial", "Se o Priest morrer, libera uma onda de luz final que cura 100% da vida de um aliado aleatorio e congela a horda por 2s.", "Celestial Pact", "On death, releases a final wave that fully heals a random ally and freezes the horde for 2s."),
            ("Luz Protetora", "Aliados curados pelo Priest ganham 10% de Armadura bonus por 3 segundos.", "Protective Light", "Allies healed by the Priest gain 10% bonus armor for 3 seconds."),
            ("Misericordia", "Aumenta em 20% a quantidade de cura realizada em aliados que estejam com menos de 50% de vida.", "Mercy", "Increases healing by 20% on allies below 50% HP."),
        ],
    },
    "warrior": {
        "active": [
            ("Sequencia Frenetica", "Desfere 3 cortes rapidos e profundos consecutivos em menos de 1 segundo.", "Frenzied Sequence", "Delivers 3 fast deep consecutive slashes in under 1 second."),
            ("Corte Rapido", "Um golpe horizontal simples e veloz com a espada que atinge os inimigos a frente.", "Quick Slash", "A simple fast horizontal sword strike hitting enemies ahead."),
            ("Perfuracao Dupla", "Duas estocadas ultra-rapidas sem sair do lugar.", "Double Thrust", "Two ultra-fast thrusts without moving."),
            ("Lamina Pesada", "Um ataque lento e carregado de 0.5s que causa dano duplo.", "Heavy Blade", "A slow 0.5s charged attack that deals double damage."),
            ("Grito de Guerra", "Erguer a espada para cima e emite um pulso de poder que aumenta o Dano Fisico em 20% por 5 segundos.", "War Cry", "Raises the sword and emits a power pulse, increasing Physical Damage by 20% for 5 seconds."),
        ],
        "passive": [
            ("Mestre das Laminas", "Aumenta o Dano Fisico base e o alcance de corte da espada.", "Blade Master", "Increases base Physical Damage and sword slash range."),
            ("Afiacao Extrema", "Aumenta a taxa de Acerto Critico e o Dano Critico de todos os ataques de espada em 15%.", "Extreme Sharpening", "Increases Critical Hit Rate and Critical Damage of sword attacks by 15%."),
            ("Armadura de Ferro", "Concede 15% de reducao de dano fisico direto vindo de ataques corpo a corpo.", "Iron Armor", "Grants 15% reduction to direct melee physical damage."),
            ("Postura Inquebravel", "Confere imunidade a efeitos de atordoamento e empurrao (Knockback) enquanto estiver no meio da animacao de uma habilidade ativa.", "Unbreakable Stance", "Immune to stun and knockback during active skill animations."),
            ("Execucao Precisa", "Causa 20% a mais de dano contra alvos que estejam com menos de 35% da vida maxima.", "Precise Execution", "Deals 20% more damage to targets below 35% max HP."),
            ("Vontade de Ferro", "Ao ficar com menos de 25% de vida, ganha 30% de Velocidade de Ataque e 15% de Roubo de Vida (Lifesteal) por 5 segundos (60 segundos de cooldown).", "Iron Will", "Below 25% HP, gains 30% Attack Speed and 15% Lifesteal for 5 seconds (60s cooldown)."),
            ("Postura de Defesa", "Ganha 10% de armadura extra enquanto estiver com menos de 50% de vida.", "Defensive Stance", "Gains 10% extra armor while below 50% HP."),
            ("Forca Bruta", "Causa 10% a mais de dano contra inimigos do tipo Elite ou Chefes.", "Brute Force", "Deals 10% more damage to Elite enemies or bosses."),
            ("Resistencia Media", "Reduz todo o dano fisico recebido em 8%.", "Medium Resistance", "Reduces all physical damage taken by 8%."),
            ("Musculos de Aco", "Aumenta a vida maxima do guerreiro em 10%.", "Steel Muscles", "Increases warrior max HP by 10%."),
        ],
    },
    "mage": {
        "active": [
            ("Meteoro Abissal", "Evoca uma pedra magica do topo da tela que cai sobre o grupo mais denso de inimigos.", "Abyssal Meteor", "Summons a magic stone from above onto the densest enemy group."),
            ("Portal de Dano", "Dispara um raio continuo de 1 segundo direto do cajado.", "Damage Portal", "Fires a 1-second continuous beam from the staff."),
            ("Bola de Fogo Negra", "Dispara uma grande esfera que causa dano em area no impacto.", "Black Fireball", "Fires a large sphere that deals area damage on impact."),
            ("Nova de Gelo", "Uma onda circular de gelo que congela tudo ao redor por 1s.", "Ice Nova", "A circular ice wave that freezes everything nearby for 1s."),
            ("Lanca de Gelo", "Dispara uma estaca de gelo fina e rapida que atravessa ate 2 inimigos em linha reta.", "Ice Lance", "Fires a thin fast ice stake piercing up to 2 enemies in a line."),
        ],
        "passive": [
            ("Amplificacao Arcana", "Aumenta o Dano Magico base e o Alcance de Ataque do cajado.", "Arcane Amplification", "Increases base Magic Damage and staff attack range."),
            ("Ressoar de Runas", "Toda vez que uma habilidade ativa e disparada, concede 5% de Velocidade de Convocacao (cooldown reduction) por 3s (acumula ate 4 vezes).", "Rune Resonance", "Each active skill cast grants 5% cooldown reduction for 3s (stacks up to 4 times)."),
            ("Penetracao Magica", "Suas magias ignoram 25% da resistencia magica/armadura dos inimigos e chefes.", "Magic Penetration", "Spells ignore 25% of enemy magic resistance/armor."),
            ("Foco Critico", "Aumenta a chance de Acerto Critico Magico em 15% contra inimigos com mais de 70% da vida.", "Critical Focus", "Increases magic Critical Hit chance by 15% against enemies above 70% HP."),
            ("Dreno de Alma", "Matar um inimigo com qualquer magia restaura 5% da vida maxima do Mago instantaneamente.", "Soul Drain", "Killing an enemy with any spell instantly restores 5% max HP."),
            ("Fluxo de Mana", "A cada 5 magias lancadas, a proxima causa 50% a mais de dano.", "Mana Flow", "Every 5 spells cast, the next deals 50% more damage."),
            ("Sintonizacao", "Reduz em 0.1s o cooldown de todas as habilidades ao acertar um acerto critico.", "Tuning", "Reduces all skill cooldowns by 0.1s on a critical hit."),
            ("Presenca do Vazio", "Inimigos na tela tem suas defesas reduzidas em 10% passivamente.", "Void Presence", "Enemies on screen have defenses reduced by 10% passively."),
            ("Mente Aberta", "Aumenta a taxa de acerto critico bonus contra alvos imobilizados ou congelados em 25%.", "Open Mind", "Increases bonus critical hit rate by 25% against immobilized or frozen targets."),
            ("Sinfonia Elementar", "Alternar entre magias de elementos diferentes aumenta o dano geral em 5% (acumula ate 4 vezes).", "Elemental Symphony", "Alternating spell elements increases overall damage by 5% (stacks up to 4 times)."),
        ],
    },
    "tank": {
        "active": [
            ("Barreira de Runas", "Ganha um escudo magico de energia proporcional a 25% da sua vida maxima por 4 segundos.", "Rune Barrier", "Gains a magic energy shield equal to 25% max HP for 4 seconds."),
            ("Provocacao Sombria", "Forca todos os inimigos da tela a atacarem o Tank e converte 20% do dano recebido durante o efeito em vida.", "Dark Taunt", "Forces all enemies to attack the Tank and converts 20% damage taken into HP during the effect."),
            ("Postura Inviolavel", "Trava as pernas e usa o escudo como parede, ficando totalmente imune a dano e controle de grupo por 2.5s.", "Inviolable Stance", "Plants legs and uses the shield as a wall, immune to damage and crowd control for 2.5s."),
            ("Supressao Total", "Bate o escudo e a maca um contra o outro, emitindo um estrondo de metal que causa dano aos inimigos na area.", "Total Suppression", "Slams shield and mace together, dealing area damage with a metal thunder."),
            ("Moinho Esmagador", "Executa uma sequencia rapida de 3 golpes de maca alternados (esquerda, direita, cima).", "Crushing Mill", "Performs a fast sequence of 3 alternating mace strikes (left, right, up)."),
        ],
        "passive": [
            ("Casca de Titanio", "Concede 5% de chance fixa de bloquear totalmente o dano de qualquer ataque.", "Titanium Shell", "Grants a fixed 5% chance to fully block any attack damage."),
            ("Espinhos da Superficie", "Reflete 20% do dano fisico de ataques corpo a corpo recebidos na parte frontal do escudo.", "Surface Thorns", "Reflects 20% of frontal melee physical damage taken on the shield."),
            ("Inabalavel", "Imunidade total a qualquer efeito de empurrao (knockback) causado por inimigos comuns ou projeteis leves.", "Unshakable", "Fully immune to knockback from common enemies or light projectiles."),
            ("Absorcao no Impacto", "Derrotar um inimigo usando uma habilidade com o escudo restaura 8% da vida maxima instantaneamente.", "Impact Absorption", "Defeating an enemy with a shield skill instantly restores 8% max HP."),
            ("Liga Magica", "Aumenta a resistencia a danos elementais (fogo, veneno e magia).", "Magic Alloy", "Increases resistance to elemental damage (fire, poison, and magic)."),
            ("Ultima Trincheira", "Ao receber dano fatal, o Tank se esconde atras do escudo e fica totalmente invulneravel por 2 segundos (cooldown longo / 1 vez por fase).", "Last Trench", "On fatal damage, hides behind the shield and becomes invulnerable for 2 seconds (long cooldown / once per stage)."),
            ("Peso Pesado", "Golpes de maca tem 15% de chance fixa de atordoar inimigos comuns por 0.5s a cada impacto.", "Heavy Weight", "Mace hits have a fixed 15% chance to stun common enemies for 0.5s."),
            ("Inercia de Batalha", "Cada golpe acertado com a maca concede 3% de armadura bonus por 4 segundos (acumula ate 5 vezes).", "Battle Inertia", "Each mace hit grants 3% bonus armor for 4 seconds (stacks up to 5 times)."),
            ("Casca Dura", "Reduz em 20% o dano recebido de ataques criticos.", "Hard Shell", "Reduces damage taken from critical attacks by 20%."),
            ("Esmagamento Vital", "Inimigos atingidos por habilidades de maca perdem 10% da armadura por 4 segundos.", "Vital Crush", "Enemies hit by mace skills lose 10% armor for 4 seconds."),
        ],
    },
}
