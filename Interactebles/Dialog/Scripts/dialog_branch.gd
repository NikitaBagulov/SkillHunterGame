@tool
@icon("res://GUI/Dialog/Icons/answer_bubble.svg")
class_name DialogBranch extends DialogItem

@export var text: String = "окей..."

var dialog_items: Array[DialogItem]

func _ready():
	if Engine.is_editor_hint():
		return
	
	for child in get_children():
		if child is DialogItem:
			dialog_items.append(child)
