@tool
@icon("res://GUI/Dialog/Icons/answer_bubble.svg")
class_name DialogBranch extends DialogItem

@export var text: String = "окей...": set = _set_text

var dialog_items: Array[DialogItem]

func _ready():
	super()
	if Engine.is_editor_hint():
		return
	
	for child in get_children():
		if child is DialogItem:
			dialog_items.append(child)

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
