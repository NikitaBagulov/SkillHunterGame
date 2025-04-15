@tool
@icon("res://IconGodotNode/node/icon_interrogation.png")
class_name GlobalQuestManager extends Node

# Синглтон
static var instance: GlobalQuestManager = null

# Сигналы
signal quest_added(quest: QuestResource)
signal quest_updated(quest: QuestResource)
signal quest_completed(quest: QuestResource)

# Ссылки
@onready var quest_ui_scene: PackedScene = preload("res://GUI/Quest/QuestUI.tscn")
var quest_ui: QuestUI

# Хранилище активных квестов
var active_quests: Dictionary = {}  # {quest_id: QuestResource}

func _ready() -> void:
	# Установка синглтона
	if instance == null:
		instance = self
	else:
		queue_free()
		return
	
	name = "GlobalQuestManager"
	
	# Подключение к Repository
	if Repository.instance:
		_load_from_repository()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quest_menu"):  # Клавиша J
		_toggle_quest_ui()

# Регистрация нового квеста
func add_quest(quest: QuestResource) -> bool:
	if active_quests.has(quest.quest_id):
		push_warning("Quest '%s' already exists!" % quest.quest_id)
		return false
	
	active_quests[quest.quest_id] = quest
	Repository.instance.register("quests", quest.quest_id, quest, true)
	quest_added.emit(quest)
	
	if quest_ui and quest_ui.visible:
		quest_ui.update_quest_list()
	
	return true

# Обновление прогресса квеста
func update_quest_progress(quest_id: String, objective_id: String, value: int) -> void:
	if not active_quests.has(quest_id):
		return
	
	var quest: QuestResource = active_quests[quest_id]
	if quest.update_objective(objective_id, value):
		quest_updated.emit(quest)
		Repository.instance.update_data("quests", quest_id, quest)
		
		if quest.is_completed():
			complete_quest(quest_id)
		
		if quest_ui and quest_ui.visible:
			quest_ui.update_quest_list()

# Завершение квеста
func complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	
	var quest: QuestResource = active_quests[quest_id]
	quest.status = QuestResource.QuestStatus.COMPLETED
	active_quests.erase(quest_id)
	Repository.instance.remove_data("quests", quest_id)
	quest_completed.emit(quest)
	
	if quest_ui and quest_ui.visible:
		quest_ui.update_quest_list()

# Получение квеста по ID
func get_quest(quest_id: String) -> QuestResource:
	return active_quests.get(quest_id)

# Интеграция с диалоговой системой
func start_quest_from_dialog(quest_id: String, dialog_items: Array[DialogItem]) -> void:
	var quest: QuestResource = load("res://QuestSystem/Resources/%s.tres" % quest_id)
	if add_quest(quest):
		DialogSystem.show_dialog(dialog_items)

# Проверка условий для начала квеста в диалоге
func can_start_quest(quest_id: String) -> bool:
	if active_quests.has(quest_id):
		return false
	# Здесь можно добавить дополнительные проверки условий
	return true

# Загрузка квестов из Repository
func _load_from_repository() -> void:
	var quest_data = Repository.instance.get_data("quests", "", {})
	for quest_id in quest_data:
		var quest: QuestResource = quest_data[quest_id]
		if quest and quest is QuestResource:
			active_quests[quest_id] = quest

# Управление UI квестов
func _toggle_quest_ui() -> void:
	if not quest_ui:
		quest_ui = quest_ui_scene.instantiate() as QuestUI
		get_tree().root.add_child(quest_ui)
	
	quest_ui.visible = !quest_ui.visible
	if quest_ui.visible:
		quest_ui.update_quest_list()

# Получение всех активных квестов
func get_active_quests() -> Array[QuestResource]:
	var result: Array[QuestResource] = []
	for quest in active_quests.values():
		if quest is QuestResource:
			result.append(quest)
	return result

func on_item_collected(item_id: String, quantity: int) -> void:
	for quest in active_quests.values():
		for objective in quest.objectives:
			if objective.item_id == item_id and not objective.completed:
				update_quest_progress(quest.quest_id, objective.objective_id, quantity)
