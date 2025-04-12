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

# Время наведения для показа всплывающего окна
var hover_time: float = 0.0
const HOVER_DELAY: float = 1.0  # 2 секунды
var tooltip: PopupPanel
var title_label: Label  # Ссылка на узел названия
var desc_label: Label   # Ссылка на узел описания
var progress_bar: TextureProgressBar  # Индикатор прогресса наведения
var is_hovered: bool = false  # Флаг нахождения мыши над слотом

@onready var texture: TextureRect = $TextureRect
@onready var label: Label = $Label

func _ready() -> void:
	texture.texture = null
	label.text = ""
	pressed.connect(item_pressed)
	button_down.connect(on_button_down)
	button_up.connect(on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Создаем всплывающее окно
	tooltip = PopupPanel.new()
	var panel_content = VBoxContainer.new()
	title_label = Label.new()
	desc_label = Label.new()
	title_label.name = "TitleLabel"
	desc_label.name = "DescLabel"
	panel_content.add_child(title_label)
	panel_content.add_child(desc_label)
	tooltip.add_child(panel_content)
	tooltip.hide()
	add_child(tooltip)
	
	# Создаем индикатор прогресса
	progress_bar = TextureProgressBar.new()
	progress_bar.max_value = HOVER_DELAY
	progress_bar.value = 0
	progress_bar.size = Vector2(32, 4)  # Размер полоски (можно настроить)
	progress_bar.position = Vector2(0, -8)  # Над кнопкой
	progress_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	progress_bar.tint_progress = Color(0, 1, 0)  # Зеленый прогресс
	progress_bar.hide()
	add_child(progress_bar)

func _process(delta):
	if dragging:
		drag_texture.position = get_local_mouse_position() - Vector2(16, 16)
		if outside_drag_threshhold():
			drag_texture.modulate.a = 0.5
		else:
			drag_texture.modulate.a = 0.0
	
	# Обновляем время наведения и прогресс
	if is_hovered and not dragging and slot_data != null:
		if not tooltip.visible:  # Если tooltip еще не открыт
			hover_time += delta
			progress_bar.value = hover_time
			progress_bar.show()
			if hover_time >= HOVER_DELAY:
				show_tooltip()
				progress_bar.hide()
	else:
		hover_time = 0.0
		progress_bar.value = 0
		progress_bar.hide()
		if not is_hovered:
			hide_tooltip()

func set_slot_data(value: SlotData) -> void:
	slot_data = value
	if slot_data == null:
		texture.texture = null
		label.text = ""
		hide_tooltip()
		progress_bar.hide()
		hover_time = 0.0
		return
	texture.texture = slot_data.item_data.texture
	if slot_data.item_data is EquipableItemData:
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
			if slot_data == null:
				return
			label.text = str(slot_data.quantity)

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
	is_hovered = true
	if slot_data != null and not tooltip.visible:
		progress_bar.show()

func _on_mouse_exited() -> void:
	is_hovered = false
	hover_time = 0.0
	progress_bar.hide()
	hide_tooltip()

# Показ всплывающего окна
func show_tooltip() -> void:
	if slot_data and slot_data.item_data and not tooltip.visible:
		title_label.text = slot_data.item_data.name
		desc_label.text = slot_data.item_data.description if slot_data.item_data.description else "No description"
		if slot_data.item_data is EquipableItemData and slot_data.item_data.skill:
			desc_label.text += "\nSkill: " + slot_data.item_data.skill.get_description()
		
		# Позиционируем tooltip рядом с курсором
		var screen_size = get_viewport_rect().size
		var tooltip_pos = get_global_mouse_position() + Vector2(10, 10) - global_position
		tooltip.popup()  # Показываем, чтобы получить размер
		var tooltip_size = tooltip.size
		if tooltip_pos.x + tooltip_size.x > screen_size.x:
			tooltip_pos.x = screen_size.x - tooltip_size.x
		if tooltip_pos.y + tooltip_size.y > screen_size.y:
			tooltip_pos.y = screen_size.y - tooltip_size.y
		tooltip.position = tooltip_pos

# Скрытие всплывающего окна
func hide_tooltip() -> void:
	tooltip.hide()
