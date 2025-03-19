extends Node

# --- Константы ---
## Сцена игрока для инстанцирования
const PLAYER_SCENE = preload("res://Player/Scenes/player.tscn")
## Данные инвентаря игрока
const INVENTORY_DATA: InventoryData = preload("res://GUI/Inventory/player_inventory.tres")
## Статистика игрока
const PLAYER_STATS: Stats = preload("res://Player/PlayerStats.tres")

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
	# Подключаем сигнал изменения экипировки к обновлению текстуры оружия
	INVENTORY_DATA.equipment_changed.connect(_update_weapon_texture)

# --- Управление игроком ---
## Устанавливает экземпляр игрока и отправляет сигнал
func set_player(new_player: Player) -> void:
	player = new_player
	player_assigned.emit(player)

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
	if player:
		player.HP = hp
		player.max_HP = max_hp
		player.update_hp(0)

## Обновляет урон от экипированного оружия
func update_equipment_damage() -> void:
	var weapon_bonus = INVENTORY_DATA.get_equipped_weapon_damage_bonus()
	PLAYER_STATS.update_damage(weapon_bonus)
	if player:
		player.attack_hurt_box.damage = weapon_bonus

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
	if texture and player:
		player.change_weapon_texture(texture)
