extends Node

# --- Константы ---
const PLAYER_SCENE = preload("res://Player/Scenes/player.tscn")
var INVENTORY_DATA: InventoryData = InventoryData.new()
@export var PLAYER_STATS: Stats = Stats.new()

# --- Сигналы ---
signal interact_pressed
signal player_assigned(player: Player)
signal manager_ready

# --- Переменные ---
var player: Player = null
var player_spawned: bool = false
var can_attack: bool = false

func _ready() -> void:
	PLAYER_STATS.init()
	
	# Регистрируем данные в Repository
	Repository.instance.register("player", "stats", PLAYER_STATS, true)
	Repository.instance.register("inventory", "data", INVENTORY_DATA, true)
	
	# Подключаем сигнал загрузки из SaveManager
	SaveManager.load_completed.connect(_on_load_completed)
	
	# Инициализируем сигналы и состояние
	_connect_inventory_signals()
	
	# Сигнализируем о готовности
	manager_ready.emit()

# Подключает сигналы INVENTORY_DATA
func _connect_inventory_signals() -> void:
	# Отключаем старые сигналы, если они были подключены
	if INVENTORY_DATA.is_connected("equipment_changed", _update_weapon_texture):
		INVENTORY_DATA.equipment_changed.disconnect(_update_weapon_texture)
	if INVENTORY_DATA.is_connected("equipment_changed", update_equipment_damage):
		INVENTORY_DATA.equipment_changed.disconnect(update_equipment_damage)
	if INVENTORY_DATA.is_connected("equipment_changed", update_health):
		INVENTORY_DATA.equipment_changed.disconnect(update_health)
	
	# Подключаем сигналы
	INVENTORY_DATA.equipment_changed.connect(_update_weapon_texture)
	INVENTORY_DATA.equipment_changed.connect(update_equipment_damage)
	INVENTORY_DATA.equipment_changed.connect(update_health)

# Обрабатывает завершение загрузки
func _on_load_completed(success: bool) -> void:
	if not success:
		print("[PlayerManager] Load failed")
		return
	
	print("[PlayerManager] Load completed, restoring state")
	restore_state()

# Восстанавливает состояние после загрузки
func restore_state() -> void:
	# Получаем данные из Repository
	var new_stats = Repository.instance.get_data("player", "stats", null)
	var new_inventory_data = Repository.instance.get_data("inventory", "data", null)
	
	if new_stats and new_stats is Stats:
		PLAYER_STATS = new_stats
		PLAYER_STATS.init()
		print("[PlayerManager] Restored PLAYER_STATS: hp=%d, max_hp=%d" % [PLAYER_STATS.hp, PLAYER_STATS.max_hp])
	else:
		print("[PlayerManager] Failed to restore PLAYER_STATS")
	
	if new_inventory_data and new_inventory_data is InventoryData:
		INVENTORY_DATA = new_inventory_data
		_connect_inventory_signals() # Переподключаем сигналы
		print("[PlayerManager] Restored INVENTORY_DATA with %d slots" % INVENTORY_DATA.slots.size())
	else:
		print("[PlayerManager] Failed to restore INVENTORY_DATA")
	
	# Обновляем состояние игрока
	if player:
		update_health()
		update_equipment_damage()
		_update_weapon_texture()
		set_player_position(PLAYER_STATS.position if PLAYER_STATS.position else Vector2.ZERO)
	if INVENTORY_DATA:
		INVENTORY_DATA.data_changed.emit()
		INVENTORY_DATA.equipment_changed.emit()
	if PLAYER_STATS:
		PLAYER_STATS.init()
		Hud.connect_stats_signals()
		Inventory.stats_ui.connect_updating_ui()

# --- Управление игроком ---
func set_player(new_player: Player) -> void:
	player = new_player
	player_assigned.emit(player)
	update_health()

func get_player() -> Player:
	return player

func spawn_player(parent_node: Node = null) -> void:
	if player_spawned:
		print("Player is already spawned!")
		return
	
	player = PLAYER_SCENE.instantiate()
	var target_node = parent_node if parent_node else get_tree().root
	target_node.call_deferred("add_child", player)
	
	player_spawned = true
	set_player(player)

func set_player_position(new_position: Vector2) -> void:
	if player:
		player.global_position = new_position

# --- Управление характеристиками ---
func set_health(hp: int, max_hp: int) -> void:
	PLAYER_STATS.hp = hp
	PLAYER_STATS.max_hp = max_hp
	if player:
		player.health.update_hp(0)

func update_equipment_damage() -> void:
	var weapon_bonus = INVENTORY_DATA.get_equipped_weapon_damage_bonus()
	can_attack = true if weapon_bonus != 0 else false
	PLAYER_STATS.update_damage(weapon_bonus)
	if player:
		player.attack_hurt_box.damage = weapon_bonus

func update_health() -> void:
	var health_bonus = INVENTORY_DATA.get_health_bonus()
	var skill_bonus = 0
	for slot in INVENTORY_DATA.equipment_slots():
		if slot and slot.item_data and slot.item_data.skill and slot.item_data.skill.type == SkillResource.SkillType.PASSIVE:
			if slot.item_data.skill.element == SkillResource.Element.EARTH:
				skill_bonus += slot.item_data.skill.base_value + (slot.item_data.skill.level - 1) * 5
	PLAYER_STATS.update_health(health_bonus + skill_bonus)

# --- Управление звуком ---
func play_audio(audio: AudioStream, loop: bool = false) -> void:
	if player:
		if player.audio:
			var audio_node = player.audio
			
			if loop:
				if not audio_node.finished.is_connected(_on_audio_finished.bind(audio_node)):
							audio_node.finished.connect(_on_audio_finished.bind(audio_node))
			audio_node.stream = audio
			audio_node.play()
# --- Вспомогательные методы ---
func _update_weapon_texture() -> void:
	var texture = INVENTORY_DATA.get_equipped_weapon_texture()
	if player:
		player.change_weapon_texture(texture)
		
func _on_audio_finished(audio_node: AudioStreamPlayer2D) -> void:
	audio_node.play()
