class_name InventorySlotUI extends Button

enum ItemType {
	HEAD,
	BODY,
	WEAPON,
	ACCESSORY,
	BOOTS,
	PANTS,
}

var slot_data: SlotData
var slot_type: int = -1  # Тип слота из enum ItemType

var click_pos: Vector2 = Vector2.ZERO
var dragging: bool = false
var drag_texture: Control
var drag_threshhold: float = 16.0

var tooltip: Control
var title_label: Label  # Ссылка на узел названия
var desc_label: Label   # Ссылка на узел описания

@onready var texture: TextureRect = $TextureRect
@onready var label: Label = $Label
@onready var level_label: Label = $LevelLabel

func _ready() -> void:
	texture.texture = null
	label.text = ""
	level_label.text = ""
	pressed.connect(item_pressed)
	button_down.connect(on_button_down)
	button_up.connect(on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Создаем всплывающее окно
	tooltip = Control.new()
	tooltip.z_index = 100
	var panel_content = VBoxContainer.new()
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label = Label.new()
	desc_label = Label.new()
	title_label.name = "TitleLabel"
	desc_label.name = "DescLabel"
	panel_content.add_child(title_label)
	panel_content.add_child(desc_label)
	tooltip.add_child(panel_content)
	tooltip.hide()
	add_child(tooltip)

func _process(delta):
	if dragging:
		drag_texture.position = get_local_mouse_position() - Vector2(16, 16)
		if outside_drag_threshhold():
			drag_texture.modulate.a = 0.5
		else:
			drag_texture.modulate.a = 0.0

func set_slot_data(value: SlotData) -> void:
	slot_data = value
	update_slot_display(slot_data)
	if slot_data == null:
		texture.texture = null
		label.text = ""
		hide_tooltip()
		return
	texture.texture = slot_data.item_data.texture
	if slot_data.item_data is EquipableItemData or slot_data.item_data is SkillItemData:
		label.text = ""
	else:
		label.text = str(slot_data.quantity)

func item_pressed() -> void:
	if slot_data and !outside_drag_threshhold():
		if slot_data.item_data:
			var item = slot_data.item_data
			if item is EquipableItemData:
				PlayerManager.INVENTORY_DATA.equip_item(slot_data)
				return
			var was_used = item.use()
			if !was_used:
				return
			slot_data.quantity -= 1
			if slot_data.quantity <= 0:
				# Очищаем слот
				PlayerManager.INVENTORY_DATA.slot_changed()  # Вызываем обновление инвентаря
				set_slot_data(null)  # Обновляем UI
			if slot_data == null:
				return
			label.text = str(slot_data.quantity)
			update_slot_display(slot_data)

func on_button_down() -> void:
	click_pos = get_global_mouse_position()
	dragging = true
	drag_texture = texture.duplicate()
	drag_texture.z_index = 10
	drag_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(drag_texture)

func on_button_up() -> void:
	dragging = false
	if drag_texture:
		drag_texture.free()

func outside_drag_threshhold() -> bool:
	if get_global_mouse_position().distance_to(click_pos) > drag_threshhold:
		return true
	return false

func is_inventory_slot() -> bool:
	return slot_type == -1

# Обработчики наведения мыши
func _on_mouse_entered() -> void:
	show_tooltip()

func _on_mouse_exited() -> void:
	hide_tooltip()

func show_tooltip(offset: Vector2 = Vector2(20, 0)) -> void:
	if slot_data and slot_data.item_data and not tooltip.visible:
		title_label.text = slot_data.item_data.name
		desc_label.text = slot_data.item_data.description if slot_data.item_data.description else "No description"

		if slot_data.item_data is EquipableItemData and slot_data.item_data.skill:
			desc_label.text += "\nSkill: " + slot_data.item_data.skill.get_description()

		
		await get_tree().process_frame  # Нужно, чтобы tooltip.size стал актуальным

		var viewport_size = get_viewport_rect().size
		var tooltip_size = tooltip.size
		var mouse_pos = get_global_mouse_position()

		var new_pos = mouse_pos + offset

		# === Корректировка ПРАВОГО края ===
		if new_pos.x + tooltip_size.x > viewport_size.x:
			new_pos.x = mouse_pos.x - tooltip_size.x - offset.x  # Сместить влево от курсора

		# === Центровка по вертикали (или как тебе удобно) ===
		new_pos.y = mouse_pos.y - tooltip_size.y / 2

		# === Границы ===
		new_pos.x = clamp(new_pos.x, 0, viewport_size.x - tooltip_size.x)
		new_pos.y = clamp(new_pos.y, 0, viewport_size.y - tooltip_size.y)

		tooltip.global_position = new_pos
		tooltip.show()


func update_slot_display(slot_data: SlotData) -> void:
	if slot_data and slot_data.item_data is SkillItemData:
		if slot_data.item_data.skill != null:
			var skill = slot_data.item_data.skill
			level_label.text = "Lv." + str(skill.level)
			level_label.visible = true
	else:
		level_label.visible = false
# Скрытие всплывающего окна
func hide_tooltip() -> void:
	tooltip.hide()
