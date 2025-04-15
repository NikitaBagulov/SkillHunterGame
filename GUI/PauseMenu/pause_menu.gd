extends CanvasLayer

@onready var button_save: Button = $VBoxContainer/ButtonSave
@onready var button_load: Button = $VBoxContainer/ButtonLoad
@onready var status_label: Label = $Label  # Добавьте Label в сцену

var is_paused: bool = false

func _ready():
	hide_pause_menu()
	button_save.pressed.connect(_on_save_pressed)
	button_load.pressed.connect(_on_load_pressed)
	status_label.text = ""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_paused == false:
			if DialogSystem.is_active:
				return
			show_pause_menu()
		else:
			hide_pause_menu()
		get_viewport().set_input_as_handled()
		
func _on_save_pressed() -> void:
	if not is_paused:
		return
	status_label.text = "Saving..."
	var success = await SaveManager.save_game_async()
	status_label.text = "Save successful!" if success else "Save failed!"
	await get_tree().create_timer(2.0).timeout
	status_label.text = ""
	hide_pause_menu()

func _on_load_pressed() -> void:
	if not is_paused:
		return
	status_label.text = "Loading..."
	var success = await SaveManager.load_game_async()
	status_label.text = "Load successful!" if success else "Load failed!"
	if success:
		var stats = Repository.instance.get_data("player", "stats", null)
		if stats and PlayerManager.player:
			PlayerManager.PLAYER_STATS = stats
			PlayerManager.player.global_position = stats.position
			PlayerManager.PLAYER_STATS.init()
			
		var inventory_data = Repository.instance.get_data("inventory", "data", null)
		if inventory_data and PlayerManager.player:
			PlayerManager.INVENTORY_DATA = inventory_data
			PlayerManager.player.change_weapon_texture(
				inventory_data.get_equipped_weapon_texture() if inventory_data else null
			)
			PlayerManager.INVENTORY_DATA.data_changed.emit()
	await get_tree().create_timer(2.0).timeout
	status_label.text = ""
	hide_pause_menu()
	
func show_pause_menu() -> void:
	get_tree().paused = true
	visible = true
	is_paused = true
	button_save.grab_focus()

func hide_pause_menu() -> void:
	get_tree().paused = false
	visible = false
	is_paused = false
