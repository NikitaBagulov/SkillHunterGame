extends Node

const SAVE_PATH = "user://"

signal game_loaded
signal game_saved

var current_save: Dictionary = {
	scene_path = "",
	player = {
		HP = 1,
		max_HP = 1,
		pos_x = 0,
		pos_y = 0
	},
	items = [],
	persistence = [],
	quests = []
}

func save_game() -> void:
	update_player_data()
	update_scene_path()
	update_item_data()
	var file := FileAccess.open(SAVE_PATH+"save.sav", FileAccess.WRITE)
	var save_json = JSON.stringify(current_save)
	file.store_line(save_json)
	game_saved.emit()
	print("save")
	pass

func load_game() -> void:
	var file := FileAccess.open(SAVE_PATH+"save.sav", FileAccess.WRITE)
	var json := JSON.new()
	json.parse(file.get_line())
	var save_dict: Dictionary = json.get_data() as Dictionary
	current_save = save_dict
	
	PlayerManager.set_player_position(Vector2(current_save.player.pos_x, current_save.player.pos_y))
	PlayerManager.set_health(current_save.player.HP, current_save.player.max_HP)
	PlayerManager.INVENTORY_DATA.parse_save_data(current_save.items)
	print("load")
	pass

func update_player_data() -> void:
	var player: Player = PlayerManager.player
	current_save.player.HP = player.HP
	current_save.player.max_HP = player.max_HP
	current_save.player.pos_x = player.global_position.x
	current_save.player.pos_y = player.global_position.y
	
func update_scene_path() -> void:
	var p: String = ""
	for child in get_tree().root.get_children():
		pass
		#if child is Level:
			#p = c.scene_file_path
	current_save.scene_path = ""

func update_item_data() -> void:
	current_save.items = PlayerManager.INVENTORY_DATA.get_save_data()

func add_persistent_value(value: String) -> void:
	if !check_persistent_value(value):
		current_save.persistence

func check_persistent_value(value: String) -> bool:
	var p = current_save.persistence as Array
	return p.has(value)
