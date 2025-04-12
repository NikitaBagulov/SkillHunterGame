extends Node

# --- Константы ---
## Сцена игрока для инстанцирования
const PLAYER_SCENE = preload("res://Player/Scenes/player.tscn")
## Данные инвентаря игрока
const INVENTORY_DATA: InventoryData = preload("res://GUI/Inventory/player_inventory.tres")
## Статистика игрока
var PLAYER_STATS: Stats = preload("res://Player/PlayerStats.tres")

# --- Сигналы ---
## Сигнал нажатия кнопки взаимодействия
signal interact_pressed
## Сигнал назначения игрока
signal player_assigned(player: Player)

# --- Переменные ---
## Ссылка на экземпляр игрока
var player: Player = null
## Флаг состояния спавна игрока
var player_spawned: bool = false

# --- Инициализация ---
func _ready() -> void:
	# Подключаем сигнал изменения экипировки к обновлению текстуры оружия и здоровья
	INVENTORY_DATA.equipment_changed.connect(_update_weapon_texture)
	INVENTORY_DATA.equipment_changed.connect(update_health)

# --- Управление игроком ---
## Устанавливает экземпляр игрока и отправляет сигнал
func set_player(new_player: Player) -> void:
	player = new_player
	player_assigned.emit(player)
	# Обновляем здоровье при установке игрока
	update_health()

## Возвращает текущий экземпляр игрока
func get_player() -> Player:
	return player

## Создает и добавляет экземпляр игрока в указанный узел или корень сцены
func spawn_player(parent_node: Node = null) -> void:
	if player_spawned:
		print("Player is already spawned!")
		return
	
	player = PLAYER_SCENE.instantiate()
	var target_node = parent_node if parent_node else get_tree().root
	target_node.add_child(player)
	
	player_spawned = true
	set_player(player)

## Устанавливает позицию игрока в мире
func set_player_position(new_position: Vector2) -> void:
	if player:
		player.global_position = new_position

# --- Управление характеристиками ---
## Устанавливает здоровье игрока
func set_health(hp: int, max_hp: int) -> void:
	PLAYER_STATS.hp = hp
	PLAYER_STATS.max_hp = max_hp
	if player:
		player.health.update_hp(0)

## Обновляет урон от экипированного оружия
func update_equipment_damage() -> void:
	var weapon_bonus = INVENTORY_DATA.get_equipped_weapon_damage_bonus()
	PLAYER_STATS.update_damage(weapon_bonus)
	if player:
		player.attack_hurt_box.damage = weapon_bonus

## Обновляет здоровье игрока на основе экипировки
func update_health() -> void:
	var health_bonus = INVENTORY_DATA.get_health_bonus()
	# Учитываем бонусы от пассивных навыков экипировки
	var skill_bonus = 0
	for slot in INVENTORY_DATA.equipment_slots():
		if slot and slot.item_data and slot.item_data.skill and slot.item_data.skill.type == SkillResource.SkillType.PASSIVE:
			if slot.item_data.skill.element == SkillResource.Element.EARTH:
				skill_bonus += slot.item_data.skill.base_value + (slot.item_data.skill.level - 1) * 5
	PLAYER_STATS.update_health(health_bonus + skill_bonus)

# --- Управление звуком ---
## Воспроизводит указанный аудиопоток через аудиоузел игрока
func play_audio(audio: AudioStream) -> void:
	if player and player.has_node("audio"):
		var audio_node = player.get_node("audio")
		audio_node.stream = audio
		audio_node.play()

# --- Вспомогательные методы ---
## Обновляет текстуру оружия игрока на основе экипированного предмета
func _update_weapon_texture() -> void:
	var texture = INVENTORY_DATA.get_equipped_weapon_texture()
	if player:
		player.change_weapon_texture(texture)
