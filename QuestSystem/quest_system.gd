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

var active_quests: Dictionary = {}  # {quest_id: QuestResource}
var completed_quests: Dictionary = {}  # {quest_id: QuestResource}

var inventory: InventoryData

func _ready() -> void:
	# Установка синглтона
	if instance == null:
		instance = self
	else:
		queue_free()
		return
	
	name = "GlobalQuestManager"
	
	# Подключение к SaveManager для обработки загрузки
	SaveManager.load_completed.connect(_on_load_completed)
	
	# Подключение к Repository
	if Repository.instance:
		_load_from_repository()
		
	inventory = PlayerManager.INVENTORY_DATA

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
	completed_quests[quest_id] = quest
	Repository.instance.remove_data("quests", quest_id) # Удаляем из активных
	Repository.instance.register("completed_quests", quest_id, quest, true) # Сохраняем в завершенные
	
	# Добавляем награды в инвентарь
	for reward in quest.rewards:
		if reward is ItemData:
			inventory.add_item(reward, 1)
	
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
	var quest_resource: QuestResource = load("res://QuestSystem/Resources/%s.tres" % quest_id)
	if active_quests.has(quest_id) or completed_quests.has(quest_id):
		return false
	if quest_resource and quest_resource.required_quest_id != "":
		if not completed_quests.has(quest_resource.required_quest_id):
			return false
	return true

# Загрузка квестов из Repository
func _load_from_repository() -> void:
	active_quests = {}
	completed_quests = {}
	var quest_ids = Repository.instance.get_category_keys("quests")
	for quest_id in quest_ids:
		var quest = Repository.instance.get_data("quests", quest_id, null)
		if quest and quest is QuestResource:
			active_quests[quest_id] = quest

	# Загружаем завершенные квесты
	var completed_quest_ids = Repository.instance.get_category_keys("completed_quests")
	for quest_id in completed_quest_ids:
		var quest = Repository.instance.get_data("completed_quests", quest_id, null)
		if quest and quest is QuestResource:
			completed_quests[quest_id] = quest

# Обработка завершения загрузки
func _on_load_completed(success: bool) -> void:
	if not success:
		print("[GlobalQuestManager] Load failed")
		return
	
	print("[GlobalQuestManager] Load completed, restoring state")
	_load_from_repository()
	
	# Обновляем UI, если оно открыто
	if quest_ui and quest_ui.visible:
		quest_ui.update_quest_list()

# Управление UI квестов
func _toggle_quest_ui() -> void:
	if not quest_ui:
		quest_ui = quest_ui_scene.instantiate() as QuestUI
		get_tree().root.add_child(quest_ui)
	
	quest_ui.visible = !quest_ui.visible
	Hud.visible = !Hud.visible
	if quest_ui.visible:
		quest_ui.update_quest_list()

# Получение всех активных квестов
func get_active_quests() -> Array[QuestResource]:
	var result: Array[QuestResource] = []
	for quest in active_quests.values():
		if quest is QuestResource:
			result.append(quest)
	return result

# Получение всех квестов (активных и завершенных)
func get_all_quests() -> Array[QuestResource]:
	var result: Array[QuestResource] = []
	for quest in active_quests.values():
		if quest is QuestResource:
			result.append(quest)
	for quest in completed_quests.values():
		if quest is QuestResource:
			result.append(quest)
	return result

# Обработчики событий
func on_item_collected(item_id: String, quantity: int) -> void:
	for quest in active_quests.values():
		for objective in quest.objectives:
			if objective.item_id == item_id and not objective.completed:
				update_quest_progress(quest.quest_id, objective.objective_id, quantity)

func on_enemy_killed(enemy_id: String) -> void:
	for quest in active_quests.values():
		for objective in quest.objectives:
			if objective.enemy_id == enemy_id and not objective.completed:
				update_quest_progress(quest.quest_id, objective.objective_id, 1)

func on_npc_interacted(npc_id: String) -> void:
	for quest in active_quests.values():
		for objective in quest.objectives:
			if objective.npc_id == npc_id and not objective.completed:
				update_quest_progress(quest.quest_id, objective.objective_id, 1)

func on_boss_killed(boss_id: String) -> void:
	for quest in active_quests.values():
		for objective in quest.objectives:
			if objective.boss_id == boss_id and not objective.completed:
				update_quest_progress(quest.quest_id, objective.objective_id, 1)
