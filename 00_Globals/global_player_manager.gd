extends Node

const PLAYER = preload("res://Player/Scenes/player.tscn")
const INVENTORY_DATA: InventoryData = preload("res://GUI/Inventory/player_inventory.tres")

signal interact_pressed()

var player: Player
var player_spawned: bool = false

#func _ready():
	#add_player_instance()
	#await get_tree().create_timer(0.2).timeout
	#player_spawned = true
	#pass
	
func add_player_instance() -> void:
	player = PLAYER.instantiate()
	add_child(player)
	
func set_player_position(_new_position: Vector2) -> void:
	player.global_position = _new_position
	
func set_health(hp: int, max_hp: int) -> void:
	player.HP = hp
	player.max_HP = max_hp
	player.update_hp(0)
	
