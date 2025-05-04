extends CanvasLayer

@onready var button_save: Button = $VBoxContainer/ButtonSave
@onready var button_load: Button = $VBoxContainer/ButtonLoad
@onready var status_label: Label = $Label

var is_paused: bool = false
var stored_states: Dictionary = {}  # Хранит состояние видимости CanvasLayer

func _ready():
	hide_pause_menu()
	button_save.pressed.connect(_on_save_pressed)
	button_load.pressed.connect(_on_load_pressed)
	status_label.text = ""
	# Проверка наличия узла World и отключение кнопки сохранения
	var main_root = get_tree().get_root().get_node_or_null("MainRoot")
	if main_root and main_root.has_node("World"):
		button_save.disabled = true

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
	status_label.text = "Сохранение..."
	var success = await SaveManager.save_game_async()
	status_label.text = "Сохранено!" if success else "Ошибка в сохранении!"
	await get_tree().create_timer(2.0).timeout
	status_label.text = ""
	hide_pause_menu()

func _on_load_pressed() -> void:
	var hub_portal = get_tree().get_first_node_in_group("hub_portal")
	if hub_portal:
		hub_portal._on_body_entered(PlayerManager.player)
	if not is_paused:
		return
	status_label.text = "Загрузка сохранения..."
	var success = await SaveManager.load_game_async()
	status_label.text = "Загрузка сохранения успешна!" if success else "Ошибка в загрузке сохранения!"
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
	
	# Проверка наличия узла World и отключение кнопки сохранения
	var main_root = get_tree().get_root().get_node_or_null("MainRoot")
	if main_root and main_root.has_node("World"):
		button_save.disabled = true
	else:
		button_save.disabled = false
	
	# Скрываем все CanvasLayer и сохраняем их состояние
	stored_states.clear()
	var root = get_tree().root
	for child in root.get_children():
		if child is CanvasLayer and child != self:
			stored_states[child] = child.visible
			child.visible = false

func hide_pause_menu() -> void:
	get_tree().paused = false
	visible = false
	is_paused = false
	
	# Восстанавливаем состояние CanvasLayer
	for layer_item in stored_states.keys():
		layer_item.visible = stored_states[layer_item]
	stored_states.clear()  # Очищаем для следующего использования


func _on_button_exit_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.
