extends Node

const PLAYER = preload("res://Player/Scenes/player.tscn")
const INVENTORY_DATA: InventoryData = preload("res://GUI/Inventory/player_inventory.tres")

signal interact_pressed
signal player_assigned(player: Player)

var player: Player
var player_spawned: bool = false

func set_player(p: Player):
	player = p
	player_assigned.emit(player)

func get_player() -> Player:
	return player

func add_player_instance(parent_node: Node = null) -> void:
	if player_spawned:
		print("Игрок уже спавнен!")
		return
	
	player = PLAYER.instantiate()
	if parent_node:
		parent_node.add_child(player)
	else:
		# Если родительский узел не указан, добавляем в корень сцены (по умолчанию)
		get_tree().root.add_child(player)
	
	player_spawned = true
	set_player(player)

func set_player_position(new_position: Vector2) -> void:
	if player:
		player.global_position = new_position

func set_health(hp: int, max_hp: int) -> void:
	if player:
		player.HP = hp
		player.max_HP = max_hp
		player.update_hp(0)

func play_audio(_audio: AudioStream) -> void:
	if player and player.has_node("audio"):
		player.get_node("audio").stream = _audio
		player.get_node("audio").play()
