extends Node2D
## Orquestra HUD, inventário, combat_root e janela.

@onready var inventory_menu: InventoryMenu = $InventoryHud/InventoryMenu
@onready var menu_button_area: ColorRect = $ButtonHud/MenuButtonArea
@onready var open_inventory_button: Button = $ButtonHud/MenuButtonArea/OpenInventoryButton
@onready var battle_panel: PanelContainer = $BattleHud/BattlePanel
@onready var enemy_health_bar: ProgressBar = %EnemyHealthBar
@onready var stage_title_label: Label = %StageTitleLabel
@onready var stage_progress_label: Label = %StageProgressLabel
@onready var damage_label: Label = %DamageLabel
@onready var repeat_stage_button: Button = %RepeatStageButton
@onready var notice_label: Label = %NoticeLabel
@onready var stage_panel: Control = $BattleHud/StageArea
@onready var floor: FloorScroller = %Floor
@onready var stage_background: CombatBackground = %StageBackground
@onready var combat_root: Node2D = $BattleHud/StageArea/Combate
@onready var combat_actors: Node2D = %CombatActors
@onready var party: PartyService = %CombatActors/PartyService
@onready var enemy_visual: EnemyVisual = %CombatActors/EnemyVisual
@onready var elite_enemy_visual: EnemyVisual = %CombatActors/EliteEnemyVisual
@onready var flying_demon_enemy_visual: EnemyVisual = %CombatActors/FlyingDemonEnemyVisual
@onready var horde_visuals: EnemyHordeVisuals = %CombatActors/HordeEnemies
@onready var coin_effect_layer: Control = $BattleHud/EffectsLayer

var total_damage: int = 5
var _notice_tween: Tween
var _window_manager: WindowManager
var _combat: CombatController
var _hero_progress := HeroProgress.new()
var _game_state := GameState.new()
var _stat_calculator := StatCalculator.new()
var _event_log_bridge := EventLogBridge.new()


func _ready() -> void:
	_window_manager = WindowManager.new()
	_window_manager.name = "WindowManager"
	_window_manager.stage_panel = stage_panel
	_window_manager.battle_panel = battle_panel
	_window_manager.menu_button_area = menu_button_area
	_window_manager.combat_root = combat_root
	_window_manager.open_inventory_button = open_inventory_button
	_window_manager.get_menu_rects = func() -> Array[Rect2]: return inventory_menu.get_clickable_rects()
	_window_manager.is_menu_visible = func() -> bool: return inventory_menu.visible
	_window_manager.on_drag_released = _apply_menu_direction
	add_child(_window_manager)
	_window_manager.configure_flags()

	_combat = CombatController.new()
	_combat.name = "CombatController"
	_combat.party = party
	_combat.enemy_visual = enemy_visual
	_combat.elite_enemy_visual = elite_enemy_visual
	_combat.flying_demon_enemy_visual = flying_demon_enemy_visual
	_combat.horde_visuals = horde_visuals
	_combat.enemy_health_bar = enemy_health_bar
	elite_enemy_visual.hide_escort()
	flying_demon_enemy_visual.hide_escort()
	_combat.floor_scroller = floor
	_combat.combat_background = stage_background
	_combat.combat_actors = combat_actors
	party.floor_scroller = floor
	party.combat_background = stage_background
	stage_background.configure_stage_panel(stage_panel)
	if not stage_panel.resized.is_connected(_on_stage_panel_resized):
		stage_panel.resized.connect(_on_stage_panel_resized)
	call_deferred("_align_initial")
	if not enemy_visual.attack_impact.is_connected(_combat.on_attack_impact):
		enemy_visual.attack_impact.connect(_combat.on_attack_impact.bind("minion"))
	if not enemy_visual.attack_finished.is_connected(_combat.on_enemy_attack_finished):
		enemy_visual.attack_finished.connect(_combat.on_enemy_attack_finished)
	if not elite_enemy_visual.attack_impact.is_connected(_combat.on_elite_attack_impact):
		elite_enemy_visual.attack_impact.connect(_combat.on_attack_impact.bind("elite"))
	if not elite_enemy_visual.attack_finished.is_connected(_combat.on_elite_attack_finished):
		elite_enemy_visual.attack_finished.connect(_combat.on_elite_attack_finished)
	if not flying_demon_enemy_visual.attack_impact.is_connected(_combat.on_flying_demon_attack_impact):
		flying_demon_enemy_visual.attack_impact.connect(_combat.on_attack_impact.bind("flying"))
	if not flying_demon_enemy_visual.attack_finished.is_connected(_combat.on_flying_demon_attack_finished):
		flying_demon_enemy_visual.attack_finished.connect(_combat.on_flying_demon_attack_finished)
	if horde_visuals != null:
		horde_visuals.connect_attack_signals(
			_combat.on_attack_impact.bind("minion"),
			_combat.on_enemy_attack_finished,
			_combat.request_minion_attack
		)
	if not enemy_visual.ready_to_attack.is_connected(_combat.request_minion_attack):
		enemy_visual.ready_to_attack.connect(_combat.request_minion_attack)
	_combat.hero_progress = _hero_progress
	_combat.get_character_index = func() -> int: return inventory_menu.current_character_index()
	_combat.get_gold_destination = _gold_destination
	_combat.get_skill_tree_bonus = func() -> Dictionary: return inventory_menu.global_skill_tree_bonus()
	add_child(_combat)
	_combat.notice.connect(_show_notice)
	_combat.coin_effect_requested.connect(_on_coin_effect)
	_combat.gold_gained.connect(_on_combat_gold)
	_combat.item_dropped.connect(_on_item_dropped)
	_combat.progression_changed.connect(_on_progression_changed)
	_combat.hud_refresh.connect(_update_hud)
	_combat.save_needed.connect(SaveSystem.save_game)
	_combat.hero_level_changed.connect(_on_hero_level_changed)

	inventory_menu.hide()
	menu_button_area.show()
	open_inventory_button.pressed.connect(_toggle_inventory)
	inventory_menu.closed.connect(_close_inventory)
	inventory_menu.window_released.connect(_apply_menu_direction)
	inventory_menu.gold_gained.connect(_on_menu_gold_gained)
	inventory_menu.gold_spent.connect(_on_menu_gold_spent)
	inventory_menu.skill_tree_changed.connect(recalculate_attributes)
	inventory_menu.query_gold = func() -> int: return _game_state.get_gold()
	_game_state.gold_changed.connect(_on_gold_changed)
	_game_state.save_requested.connect(func() -> void: SaveSystem.save())
	_stat_calculator.get_equipped_damage = get_equipped_damage_slot
	_stat_calculator.get_equipped_hp = get_equipped_hp_slot
	_stat_calculator.get_level = get_level_slot
	_stat_calculator.get_skill_tree_bonus = get_skill_tree_bonus_slot
	inventory_menu.query_slot_progress = _progress_for_slot
	inventory_menu.menu_width_changed.connect(_on_menu_width_changed)
	inventory_menu.equipment_changed.connect(recalculate_attributes)
	inventory_menu.character_changed.connect(_on_character_changed)
	inventory_menu.hero_class_changed.connect(_on_hero_class_changed)
	inventory_menu.stage_started.connect(_combat.start_stage)
	repeat_stage_button.icon = RepeatIcon.create()
	repeat_stage_button.add_theme_constant_override("icon_max_width", 18)
	repeat_stage_button.pressed.connect(_on_repeat_button_pressed)
	_update_repeat_visual()

	party.stat_calculator = _stat_calculator
	party.get_equipped_damage = get_equipped_damage_for_slot
	party.get_equipped_hp = get_equipped_hp_for_slot
	party.get_level = get_level_for_slot
	party.get_skill_tree_bonus = get_skill_tree_bonus_for_slot
	party.hero_attack_windup.connect(func(_slot: int) -> void: AudioManager.play_attack_sound())
	party.hero_attacked.connect(_combat.on_hero_attacked)
	party.hero_skill_used.connect(_combat.on_hero_skill_used)
	party.dps_changed.connect(_on_dps_changed)
	inventory_menu.setup_party(party)

	_event_log_bridge.connect_combat(_combat, party)
	_event_log_bridge.connect_inventory(inventory_menu)
	_event_log_bridge.connect_hero_equipment()
	_event_log_bridge.set_snapshot_provider(_build_log_snapshot)
	_combat.save_needed.connect(func() -> void: call_deferred("_on_save_needed_log"))

	SaveSystem.register(self)
	if not SaveSystem.load_game():
		inventory_menu.fill_initial_item_if_empty()
	inventory_menu.call_deferred("add_armor_rarity_preview")

	_on_progression_changed()
	recalculate_attributes()
	party.heal_party()
	_combat.start_combat()
	stage_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	stage_panel.gui_input.connect(_window_manager.on_drag_area)
	battle_panel.gui_input.connect(_window_manager.on_drag_area)
	call_deferred("_emit_boot_log_snapshot")


func _emit_boot_log_snapshot() -> void:
	_event_log_bridge.emit_boot_snapshot()


func _on_save_needed_log() -> void:
	_event_log_bridge.emit_snapshot("save")


func _build_log_snapshot() -> Dictionary:
	var enemy_hp := 0
	var active: Enemy = _combat.get_active_enemy()
	if active != null:
		enemy_hp = active.current_hp
	return {
		"gold": _game_state.get_gold(),
		"world": _combat.world,
		"stage": _combat.stage,
		"enemy_hp": enemy_hp,
		"dps": party.party_dps(),
	}


func _align_initial() -> void:
	_window_manager.align_combat()
	_window_manager.update_click_through()
	_sync_combat_positions()


func _on_stage_panel_resized() -> void:
	_sync_combat_positions()


func _sync_combat_positions() -> void:
	_apply_combat_draw_order()
	if stage_background != null:
		stage_background.configure_stage_panel(stage_panel)
	if _combat != null:
		_combat.sync_combat_floor()
	else:
		party.sync_floor_positions()


func _apply_combat_draw_order() -> void:
	if stage_background != null:
		stage_background.z_index = -10
	combat_root.z_index = 1
	for visual in [enemy_visual, elite_enemy_visual, flying_demon_enemy_visual]:
		if visual != null:
			visual.z_index = PartyService.COMBAT_ENEMY_Z


func get_equipped_damage_slot(slot_index: int) -> int:
	return inventory_menu.get_equipped_damage(slot_index)


func get_equipped_hp_slot(slot_index: int) -> int:
	return inventory_menu.get_equipped_hp(slot_index)


func get_level_slot(slot_index: int) -> int:
	return _hero_progress.get_level_at_slot(slot_index, party.active_party)


func _progress_for_slot(slot_index: int) -> Dictionary:
	return _hero_progress.at_index(slot_index, party.active_party)


func get_skill_tree_bonus_slot(slot_index: int) -> Dictionary:
	return inventory_menu.skill_tree_bonus_for_slot(slot_index)


func get_equipped_damage_for_slot(slot_index: int) -> int:
	return get_equipped_damage_slot(slot_index)


func get_equipped_hp_for_slot(slot_index: int) -> int:
	return get_equipped_hp_slot(slot_index)


func get_level_for_slot(slot_index: int) -> int:
	return get_level_slot(slot_index)


func get_skill_tree_bonus_for_slot(slot_index: int) -> Dictionary:
	return get_skill_tree_bonus_slot(slot_index)


func recalculate_attributes() -> void:
	party.recalculate_stats()
	total_damage = party.total_party_damage()
	_update_hud()
	inventory_menu.refresh_attributes_if_open()


func _on_dps_changed(dps: float, dano_grupo: int) -> void:
	total_damage = dano_grupo
	damage_label.text = "DPS %.1f" % dps


func _on_hero_class_changed(_indice: int, _classe: ClassData) -> void:
	recalculate_attributes()


func _on_repeat_button_pressed() -> void:
	_combat.toggle_repeat()
	_update_repeat_visual()


func _update_repeat_visual() -> void:
	var estilo := StyleBoxFlat.new()
	estilo.content_margin_left = 3
	estilo.content_margin_top = 3
	estilo.content_margin_right = 3
	estilo.content_margin_bottom = 3
	estilo.set_corner_radius_all(4)
	estilo.set_border_width_all(2)
	if _combat.repeat_stage:
		estilo.bg_color = Color(0.32, 0.24, 0.16, 1)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
		repeat_stage_button.tooltip_text = tr(LocaleKeys.UI_ADVANCE_STAGE)
	else:
		estilo.bg_color = Color(0.16, 0.13, 0.1, 1)
		estilo.border_color = Color(0.62, 0.5, 0.28, 1)
		repeat_stage_button.tooltip_text = tr(LocaleKeys.UI_REPEAT_STAGE)
	repeat_stage_button.add_theme_stylebox_override("normal", estilo)
	repeat_stage_button.add_theme_stylebox_override("hover", estilo)
	repeat_stage_button.add_theme_stylebox_override("pressed", estilo)


func _apply_menu_direction() -> void:
	var abrir_para_baixo := _window_manager.apply_menu_direction()
	inventory_menu.set_below_combat(abrir_para_baixo)


func _gold_destination() -> Vector2:
	if inventory_menu.visible:
		return inventory_menu.gold_label.get_global_rect().get_center()
	return battle_panel.get_global_rect().get_center()


func _on_coin_effect(origem: Vector2, destino: Vector2, amount: int) -> void:
	coin_effect_layer.launch(origem, destino, amount)


func _on_combat_gold(amount: int) -> void:
	_game_state.add_gold(amount)
	AudioManager.play_coin_sound()
	_update_hud()


func _on_gold_changed(_new_amount: int) -> void:
	_update_hud()


func _on_item_dropped(item: ItemData) -> void:
	if inventory_menu.try_add_inventory_item(item):
		_show_notice(tr(LocaleKeys.UI_DROP_PREFIX) % item.get_display_name())
		AudioManager.play_coin_sound()


func _on_progression_changed() -> void:
	inventory_menu.update_world_progress(_combat.world, _combat.stage, _combat.difficulty, _combat.unlocked_stages)
	_update_hud()


func _on_hero_level_changed(stage_index: int, level: int) -> void:
	var hero_progress: Dictionary = _hero_progress.at_index(stage_index, party.active_party)
	if stage_index == inventory_menu.current_character_index():
		inventory_menu.update_displayed_level(
			level,
			int(hero_progress.get("xp", 0)),
			int(hero_progress.get("xp_next", HeroProgress.BASE_XP_PER_LEVEL)),
		)
	recalculate_attributes()


func _show_notice(texto: String) -> void:
	notice_label.visible = true
	notice_label.text = texto
	notice_label.modulate.a = 1.0
	if _notice_tween:
		_notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_interval(1.4)
	_notice_tween.tween_property(notice_label, "modulate:a", 0.0, 0.4)
	_notice_tween.tween_callback(func() -> void: notice_label.visible = false)


func _on_character_changed(_indice: int) -> void:
	var hero_progress: Dictionary = _hero_progress.at_index(inventory_menu.current_character_index(), party.active_party)
	inventory_menu.update_displayed_level(
		int(hero_progress["level"]),
		int(hero_progress.get("xp", 0)),
		int(hero_progress.get("xp_next", HeroProgress.BASE_XP_PER_LEVEL)),
	)
	recalculate_attributes()


func _on_menu_gold_gained(amount: int) -> void:
	_game_state.add_gold(maxi(0, amount))
	AudioManager.play_coin_sound()
	SaveSystem.save()


func _on_menu_gold_spent(amount: int) -> void:
	var spent := maxi(0, amount)
	if spent > 0:
		_game_state.set_gold(maxi(0, _game_state.get_gold() - spent))
		_game_state.save_requested.emit()


func _update_hud() -> void:
	inventory_menu.update_gold(_game_state.get_gold())
	var hero_progress: Dictionary = _hero_progress.at_index(inventory_menu.current_character_index(), party.active_party)
	inventory_menu.update_displayed_level(
		int(hero_progress["level"]),
		int(hero_progress["xp"]),
		int(hero_progress["xp_next"]),
	)
	stage_title_label.text = tr(LocaleKeys.UI_BATTLE_STAGE_FORMAT) % [_combat.world, _combat.stage]
	var enemy_progress: Vector2i = _combat.get_stage_enemy_progress()
	stage_progress_label.text = tr(LocaleKeys.UI_STAGE_ENEMY_PROGRESS) % [enemy_progress.x, enemy_progress.y]
	damage_label.text = tr(LocaleKeys.UI_DPS_FORMAT) % party.party_dps()


func _toggle_inventory() -> void:
	if inventory_menu.visible:
		_close_inventory()
	else:
		_open_inventory()


func _open_inventory() -> void:
	_apply_menu_direction()
	inventory_menu.show()
	menu_button_area.show()
	_window_manager.adjust_width(true, inventory_menu.width_for_window())
	_window_manager.update_click_through()


func _on_menu_width_changed() -> void:
	if inventory_menu.visible:
		_window_manager.adjust_width(true, inventory_menu.width_for_window())
	_window_manager.update_click_through()


func _close_inventory() -> void:
	inventory_menu.hide()
	menu_button_area.show()
	_window_manager.adjust_width(false, inventory_menu.width_for_window())
	_window_manager.update_click_through()
	SaveSystem.save_game()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if inventory_menu.visible:
			_close_inventory()
		return


func collect_save() -> Dictionary:
	_game_state.sync_from_combat({
		"world": _combat.world,
		"stage": _combat.stage,
		"difficulty": _combat.difficulty,
		"unlocked_stages": _combat.unlocked_stages.duplicate(),
		"repeat_stage": _combat.repeat_stage,
		"wave": _combat.wave,
	})
	return SaveService.normalize_keys({
		"gold": _game_state.get_gold(),
		"wave": _combat.wave,
		"world": _combat.world,
		"stage": _combat.stage,
		"difficulty": _combat.difficulty,
		"unlocked_stages": _combat.unlocked_stages.duplicate(),
		"repeat_stage": _combat.repeat_stage,
		"active_character_index": inventory_menu.current_character_index(),
		"progress": _hero_progress.serialize(),
		"inventory": inventory_menu.serialize_inventory(),
		"warehouse": inventory_menu.serialize_warehouse(),
		"equipment": inventory_menu.serialize_equipment(),
		"party": party.serialize(),
		"skill_tree": inventory_menu.serialize_skill_tree(),
		"hero_equipment": HeroEquipment.serialize(),
	})


func apply_from_save(data: Dictionary) -> void:
	var dados := SaveService.normalize_keys(data)
	_game_state.set_gold(int(dados.get("gold", dados.get("ouro", 0))))
	_combat.apply_state({
		"wave": dados.get("wave", dados.get("wave", 1)),
		"world": dados.get("world", dados.get("world", 1)),
		"stage": dados.get("stage", dados.get("stage", 1)),
		"difficulty": dados.get("difficulty", dados.get("difficulty", 0)),
		"unlocked_stages": dados.get("unlocked_stages", dados.get("unlocked_stages", [1, 1, 1])),
		"repeat_stage": dados.get("repeat_stage", dados.get("repeat_stage", false)),
	})
	var party_save: Variant = dados.get("party", dados.get("equipe", {}))
	var ids_equipe: Array = []
	if party_save is Dictionary:
		var classes: Variant = party_save.get("classes", [])
		if classes is Array:
			for id_classe in classes:
				ids_equipe.append(str(id_classe))
		party.apply_from_save(party_save)
	_hero_progress.apply(dados.get("progress", dados.get("hero_progress", [])), ids_equipe)
	inventory_menu.apply_inventory(dados.get("inventory", dados.get("inventario", [])))
	inventory_menu.apply_warehouse(dados.get("warehouse", dados.get("armazem", [])))
	inventory_menu.apply_equipment(dados.get("equipment", dados.get("equipamentos", [])))
	inventory_menu.apply_skill_tree(dados.get("skill_tree", dados.get("arvore", [])))
	if dados.has("hero_equipment"):
		HeroEquipment.deserialize(dados.get("hero_equipment", {}))
	inventory_menu.setup_party(party)
	inventory_menu.select_character(int(dados.get("active_character_index", dados.get("personagem_atual", 0))))
	var atual: Dictionary = _hero_progress.at_index(inventory_menu.current_character_index(), party.active_party)
	inventory_menu.update_displayed_level(
		int(atual["level"]),
		int(atual.get("xp", 0)),
		int(atual.get("xp_next", HeroProgress.BASE_XP_PER_LEVEL)),
	)
	_on_progression_changed()
	_update_repeat_visual()
	recalculate_attributes()
	_update_hud()
