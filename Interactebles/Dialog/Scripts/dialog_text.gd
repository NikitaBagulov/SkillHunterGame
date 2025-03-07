@tool
@icon("res://GUI/Dialog/Icons/chat_bubble.svg")
class_name DialogText extends DialogItem

@export_multiline var text: String = "Placeholder text": set = _set_text

func _set_text(_value: String) -> void:
	text = _value
	if Engine.is_editor_hint():
		if example_dialog != null:
			_set_editor_display()

func _set_editor_display() -> void:
	example_dialog.set_dialog_text(self)
	example_dialog.content.visible_characters = -1
