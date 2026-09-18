class_name CombatController
extends Node
## Idle combat rules: heroes attack, enemy counters, phase advances.

signal notice(texto: String)
signal coin_effect_requested(origem: Vector2, destino: Vector2, quantidade: int)
signal gold_gained(quantidade: int)
signal item_dropped(item: ItemData)
signal progression_changed
signal hud_refresh
signal save_needed
signal hero_level_changed(stage_index: int, nivel: int)
signal enemy_hp_changed(current: int, max_hp: int)
signal enemy_hit(damage: int, current: int, max_hp: int)
signal enemy_died

const INTERVALO_ATAQUE_INIMIGO := 1.35

var world: int = 1
var stage: int = 1
var difficulty: int = WorldProgress.Difficulty.EASY
var unlocked_stages: Array[int] = [1, 1, 1]
var repeat_stage: bool = false
var wave: int = 1
var current_enemy: Enemy

var party: PartyService
var enemy_visual: Sprite2D
var enemy_health_bar: ProgressBar
var hero_progress: HeroProgress
var get_character_index: Callable
var get_gold_destination: Callable
var get_skill_tree_bonus: Callable

var _drops := DropManager.new()
var _resolvendo_morte: bool = false
var _resolvendo_derrota: bool = false
var _timer_inimigo: Timer


func _ready() -> void:
	_timer_inimigo = Timer.new()
	_timer_inimigo.wait_time = INTERVALO_ATAQUE_INIMIGO
	_timer_inimigo.timeout.connect(on_enemy_attacked)
	add_child(_timer_inimigo)
	_timer_inimigo.start()


func on_hero_attacked(_slot_index: int, dano: int) -> void:
	if _resolvendo_morte or _resolvendo_derrota:
		return
	if current_enemy == null or current_enemy.is_dead():
		spawn_enemy()
	AudioManager.play_attack_sound()
	var morreu := current_enemy.take_damage(dano)
	_emit_enemy_hp()
	enemy_hit.emit(dano, current_enemy.vida_atual, current_enemy.vida_maxima)
	enemy_health_bar.update_hp(current_enemy.vida_atual)
	if enemy_visual.has_method("update_hp"):
		enemy_visual.update_hp(current_enemy.vida_atual, current_enemy.vida_maxima)
	DamageNumber.spawn(enemy_visual.get_parent(), enemy_visual.global_position, dano)
	enemy_visual.flash_hit()
	AudioManager.play_hit_sound()
	if morreu:
		enemy_died.emit()
		await _resolve_death()
	hud_refresh.emit()


func on_enemy_attacked() -> void:
	if _resolvendo_morte or _resolvendo_derrota:
		return
	if party.combat_paused:
		return
	if current_enemy == null or current_enemy.is_dead():
		return
	var alvo := party.right_target_index()
	if alvo < 0:
		await _resolve_defeat()
		return
	if enemy_visual.has_method("play_attack"):
		enemy_visual.play_attack()
	AudioManager.play_attack_sound()
	party.apply_damage_to_hero(alvo, current_enemy.dano)
	AudioManager.play_hit_sound()
	if party.right_target_index() < 0:
		await _resolve_defeat()


func start_stage(novo_mundo: int, nova_fase: int, nova_dificuldade: int) -> void:
	var m := clampi(novo_mundo, 1, WorldProgress.TOTAL_MUNDOS)
	var f := clampi(nova_fase, 1, WorldProgress.FASES_POR_MUNDO)
	var d := clampi(nova_dificuldade, 0, 2)
	if not WorldProgress.is_difficulty_unlocked(d, unlocked_stages):
		return
	if WorldProgress.stage_index(m, f) > unlocked_stages[d]:
		return
	world = m
	stage = f
	difficulty = d
	_resolvendo_morte = false
	_resolvendo_derrota = false
	party.combat_paused = false
	party.heal_party()
	spawn_enemy()
	enemy_visual.show_up()
	enemy_health_bar.show_up()
	progression_changed.emit()
	hud_refresh.emit()
	save_needed.emit()


func spawn_enemy() -> void:
	var stats := WorldProgress.enemy_stats(world, stage, difficulty)
	wave = int(stats["nivel"])
	current_enemy = Enemy.new()
	current_enemy.configure(
		str(stats["nome"]),
		int(stats["vida"]),
		int(stats["ouro"]),
		int(stats["xp"]),
		int(stats.get("dano", 1))
	)
	enemy_health_bar.initialize_bar(current_enemy.vida_maxima)
	_emit_enemy_hp()
	if enemy_visual and enemy_visual.has_method("update_hp"):
		enemy_visual.update_hp(current_enemy.vida_atual, current_enemy.vida_maxima)


func toggle_repeat() -> void:
	repeat_stage = not repeat_stage
	save_needed.emit()


func apply_state(dados: Dictionary) -> void:
	wave = maxi(1, int(dados.get("wave", dados.get("onda", 1))))
	world = clampi(int(dados.get("world", dados.get("mundo", 1))), 1, WorldProgress.TOTAL_MUNDOS)
	stage = clampi(int(dados.get("stage", dados.get("fase", 1))), 1, WorldProgress.FASES_POR_MUNDO)
	difficulty = clampi(int(dados.get("difficulty", dados.get("dificuldade", 0))), 0, 2)
	var liberadas: Variant = dados.get("unlocked_stages", dados.get("fases_liberadas", [1, 1, 1]))
	unlocked_stages = [1, 1, 1]
	if liberadas is Array:
		for i in mini(liberadas.size(), 3):
			unlocked_stages[i] = clampi(int(liberadas[i]), 1, WorldProgress.PROGRESSO_COMPLETO)
	while difficulty > 0 and not WorldProgress.is_difficulty_unlocked(difficulty, unlocked_stages):
		difficulty -= 1
	repeat_stage = bool(dados.get("repeat_stage", dados.get("repetir_fase", false)))


func _resolve_death() -> void:
	if _resolvendo_morte or _resolvendo_derrota:
		return
	_resolvendo_morte = true
	party.combat_paused = true
	AudioManager.play_death_sound()
	var ouro := _drops.gold_with_variance(current_enemy.ouro_recompensa)
	ouro = _apply_gold_bonus(ouro)
	var destino := Vector2.ZERO
	if get_gold_destination.is_valid():
		destino = get_gold_destination.call()
	coin_effect_requested.emit(enemy_visual.global_position, destino, 2 + ouro / 2)
	enemy_visual.esmaecer()
	enemy_health_bar.esmaecer()
	await get_tree().create_timer(0.4).timeout
	gold_gained.emit(ouro)
	_apply_xp(_apply_xp_bonus(current_enemy.xp_recompensa))
	_try_drop()
	_advance_stage()
	party.heal_party()
	spawn_enemy()
	enemy_visual.show_up()
	enemy_health_bar.show_up()
	_resolvendo_morte = false
	party.combat_paused = false
	save_needed.emit()


func _resolve_defeat() -> void:
	if _resolvendo_derrota or _resolvendo_morte:
		return
	_resolvendo_derrota = true
	party.combat_paused = true
	AudioManager.play_death_sound()
	notice.emit(tr(LocaleKeys.UI_TEAM_DEFEATED))
	await get_tree().create_timer(1.15).timeout
	party.heal_party()
	spawn_enemy()
	enemy_visual.show_up()
	enemy_health_bar.show_up()
	_resolvendo_derrota = false
	party.combat_paused = false
	hud_refresh.emit()


func _advance_stage() -> void:
	var progresso_antes := unlocked_stages[difficulty]
	unlocked_stages[difficulty] = WorldProgress.apply_stage_completion(progresso_antes, world, stage)
	var mundo_anterior := world
	if not repeat_stage:
		var next_stage := WorldProgress.next_stage(world, stage)
		world = next_stage.x
		stage = next_stage.y
	progression_changed.emit()
	if WorldProgress.is_difficulty_completed(unlocked_stages[difficulty]) and not WorldProgress.is_difficulty_completed(progresso_antes):
		if difficulty < int(WorldProgress.Difficulty.HELL):
			notice.emit(tr(LocaleKeys.COMBAT_DIFFICULTY_UNLOCKED) % WorldProgress.difficulty_name(difficulty + 1))
		else:
			notice.emit(tr(LocaleKeys.COMBAT_HELL_COMPLETED))
	elif not repeat_stage and world > mundo_anterior:
		notice.emit(tr(LocaleKeys.COMBAT_WORLD_UNLOCKED) % world)
	elif repeat_stage:
		var seguinte := WorldProgress.next_stage(mundo_anterior, stage)
		if seguinte.x > mundo_anterior and progresso_antes < WorldProgress.stage_index(seguinte.x, 1):
			notice.emit(tr(LocaleKeys.COMBAT_WORLD_UNLOCKED) % seguinte.x)


func _apply_xp(quantidade: int) -> void:
	if hero_progress == null:
		return
	var niveis: PackedInt32Array = hero_progress.apply_xp(quantidade, party.active_party)
	for stage_index in HeroProgress.SLOTS:
		if stage_index < niveis.size():
			hero_level_changed.emit(stage_index, niveis[stage_index])
	hud_refresh.emit()


func _skill_tree_bonus() -> Dictionary:
	if get_skill_tree_bonus.is_valid():
		var bonus: Variant = get_skill_tree_bonus.call()
		if bonus is Dictionary:
			return bonus
	return SkillTreeDefinition.bonus_vazio()


func _apply_gold_bonus(valor: int) -> int:
	var pct := float(_skill_tree_bonus().get("bonus_ouro", 0.0))
	return maxi(1, int(round(float(valor) * (1.0 + pct / 100.0))))


func _apply_xp_bonus(valor: int) -> int:
	var pct := float(_skill_tree_bonus().get("bonus_xp", 0.0))
	return maxi(1, int(round(float(valor) * (1.0 + pct / 100.0))))


func _try_drop() -> void:
	var item := _drops.try_drop_item(wave)
	if item:
		item_dropped.emit(item)


func _emit_enemy_hp() -> void:
	if current_enemy == null:
		return
	enemy_hp_changed.emit(current_enemy.vida_atual, current_enemy.vida_maxima)
