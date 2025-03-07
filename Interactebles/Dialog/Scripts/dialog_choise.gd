@tool
@icon("res://GUI/Dialog/Icons/question_bubble.svg")
class_name DialogChoise extends DialogItem

var dialog_branches: Array[DialogBranch]

func _ready():
	if Engine.is_editor_hint():
		return
	for child in get_children():
		if child is DialogBranch:
			dialog_branches.append(child)

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
