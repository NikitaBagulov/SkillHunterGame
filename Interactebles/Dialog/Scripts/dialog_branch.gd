@tool
@icon("res://GUI/Dialog/Icons/answer_bubble.svg")
class_name DialogBranch extends DialogItem

@export var text: String = "окей...": set = _set_text
@export var quest_objective_id: String = ""  # ID цели квеста для обновления
@export var quest_progress_value: int = 0  # Значение прогресса для обновления

var dialog_items: Array[DialogItem]

func _ready():
	super()
	if Engine.is_editor_hint():
		return
	
	for child in get_children():
		if child is DialogItem:
			dialog_items.append(child)

# Метод вызывается при выборе этой ветки
func on_selected() -> void:
	# Обработка квестовых действий
	if quest_id and quest_action != QuestAction.NONE:
		match quest_action:
			QuestAction.START_QUEST:
				if GlobalQuestManager.instance.can_start_quest(quest_id):
					GlobalQuestManager.instance.add_quest(load("res://QuestSystem/Resources/%s.tres" % quest_id))
			QuestAction.UPDATE_QUEST:
				if quest_objective_id:
					GlobalQuestManager.instance.update_quest_progress(quest_id, quest_objective_id, quest_progress_value)
			QuestAction.COMPLETE_QUEST:
				GlobalQuestManager.instance.complete_quest(quest_id)
	
	# Продолжение диалога с элементами этой ветки
	if dialog_items.size() > 0:
		DialogSystem.show_dialog(dialog_items)

func _set_editor_display() -> void:
	var _p = get_parent()
	if _p is DialogChoise:
		set_related_text()
		if _p.dialog_branches.size() < 2:
			return
		example_dialog.set_dialog_choice( _p as DialogChoise )
		pass
	pass


func set_related_text() -> void:
	var _p = get_parent()
	var _p2 = _p.get_parent()
	var _t = _p2.get_child( _p.get_index() - 1 )

	if _t is DialogText:
		example_dialog.set_dialog_text( _t )
		example_dialog.content.visible_characters = -1



func _set_text( value : String ) -> void:
	text = value
	if Engine.is_editor_hint():
		if example_dialog != null:
			_set_editor_display()
