class_name QuestUI extends CanvasLayer

@onready var quest_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/QuestList
@onready var close_button: Button = $MarginContainer/VBoxContainer/Button
@onready var scroll_container = $MarginContainer/VBoxContainer/ScrollContainer
var quest_item_scene: PackedScene = preload("res://GUI/Quest/QuestItem.tscn")

func _ready() -> void:
	close_button.pressed.connect(_update_visible)
	
	visible = false
	update_quest_list()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed:
		
		var scroll_speed = 50
		if event.is_action("ui_up"):
			scroll_container.scroll_vertical -= scroll_speed
		elif event.is_action("ui_down"):
			scroll_container.scroll_vertical += scroll_speed

func update_quest_list() -> void:
	# Очистка текущего списка
	for child in quest_list.get_children():
		child.queue_free()
	
	# Добавление всех квестов
	var quests = GlobalQuestManager.instance.get_all_quests()
	for i in quests.size():
		var quest = quests[i]
		var quest_item = quest_item_scene.instantiate()
		quest_list.add_child(quest_item)
		quest_item.setup(quest)
		
		# Добавляем разделитель, кроме последнего квеста
		if i < quests.size() - 1:
			var separator = HSeparator.new()
			quest_list.add_child(separator)
	
	# Сбрасываем прокрутку к началу
	scroll_container.scroll_vertical = 0

func _update_visible():
	visible = false
