@tool
@icon("res://GUI/Dialog/Icons/question_bubble.svg")
class_name DialogChoise extends DialogItem

var dialog_branches: Array[DialogBranch]

func _ready():
	super()
	
	for child in get_children():
		if child is DialogBranch:
			dialog_branches.append(child)

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
