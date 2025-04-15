@tool
@icon("res://GUI/Dialog/Icons/question_bubble.svg")
class_name DialogChoise extends DialogItem

var dialog_branches: Array[DialogBranch]

func _ready():
	super()
	
	for child in get_children():
		if child is DialogBranch:
			dialog_branches.append(child)

func get_available_branches() -> Array[DialogBranch]:
	var available: Array[DialogBranch] = []
	for branch in dialog_branches:
		if branch.quest_id:
			var quest = GlobalQuestManager.instance.get_quest(branch.quest_id)
			if branch.quest_action == QuestAction.START_QUEST and not GlobalQuestManager.instance.can_start_quest(branch.quest_id):
				continue
			if branch.quest_action == QuestAction.COMPLETE_QUEST and (not quest or quest.status != QuestResource.QuestStatus.IN_PROGRESS):
				continue
		available.append(branch)
	return available

func _set_editor_display() -> void:
	set_related_text()

	if dialog_branches.size() < 2:
		return
	example_dialog.set_dialog_choice( self )
	pass



func set_related_text() -> void:
	var _p = get_parent()
	var _t = _p.get_child( self.get_index() - 1 )

	if _t is DialogText:
		example_dialog.set_dialog_text( _t )
		example_dialog.content.visible_characters = -1


func _get_configuration_warnings() -> PackedStringArray:
	if !_check_for_dialog_branches():
		return ['Требуется 2 DialogBranches!']
	else:
		return []

func _check_for_dialog_branches() -> bool:
	var _count: int = 0
	for child in get_children():
		if child is DialogBranch:
			_count += 1
			if _count > 1:
				return true
	return false
