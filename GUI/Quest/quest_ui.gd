class_name QuestUI extends CanvasLayer

@onready var quest_list: VBoxContainer = $MarginContainer/QuestList
@onready var close_button: Button = $MarginContainer/Button

var quest_item_scene: PackedScene = preload("res://GUI/Quest/QuestItem.tscn")

func _ready() -> void:
	close_button.pressed.connect(_update_visible)
	
	visible = false
	update_quest_list()
	

func update_quest_list() -> void:
	# Очистка текущего списка
	for child in quest_list.get_children():
		child.queue_free()
	
	# Добавление активных квестов
	for quest in GlobalQuestManager.instance.get_active_quests():
		var quest_item = quest_item_scene.instantiate()
		quest_list.add_child(quest_item)
		quest_item.setup(quest)

func _update_visible():
	visible = false
