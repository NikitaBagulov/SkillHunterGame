@tool
@icon("res://GUI/Dialog/Icons/chat_bubble.svg")
class_name DialogItem extends Node

@export var npc_info: NPCResource
@export var quest_id: String = ""  # ID квеста, связанного с этим диалогом
@export var quest_action: QuestAction = QuestAction.NONE  # Действие с квестом

enum QuestAction {
	NONE,
	START_QUEST,
	UPDATE_QUEST,
	COMPLETE_QUEST
}

var editor_selection: EditorSelection
var example_dialog: DialogSystemNode

func _ready():
	if Engine.is_editor_hint():
		editor_selection = EditorInterface.get_selection()
		editor_selection.selection_changed.connect(_on_selection_changed)
		return
	check_npc_info()
	
	
func check_npc_info() -> void:
	if npc_info == null:
		var parent = self
		var _checking: bool = true
		while _checking == true:
			parent = parent.get_parent()
			if parent:
				if parent is NPC and parent.npc_resource:
					npc_info = parent.npc_resource
					_checking = false
				else:
					_checking = false
					

func _on_selection_changed() -> void:
	if editor_selection == null:
		return
	
	var selected = editor_selection.get_selected_nodes()
	
	if example_dialog != null:
		example_dialog.queue_free()
	
	if not selected.is_empty():
		if self == selected[0]:
			example_dialog = load("res://GUI/Dialog/dialog_system.tscn").instantiate() as DialogSystemNode
			if example_dialog == null:
				return
			self.add_child(example_dialog)
			example_dialog.offset = get_parent_global_position() + Vector2(32, -200)
			check_npc_info()
			_set_editor_display()
	pass

func get_parent_global_position() -> Vector2:
	var parent = self
	var _checking: bool = true
	while _checking:
		parent = parent.get_parent()
		if parent:
			if parent is Node2D:
				return parent.global_position
			else:
				_checking = false
	return Vector2.ZERO

func _set_editor_display() -> void:
	if quest_id and quest_action != QuestAction.NONE:
		example_dialog.set_quest_info(quest_id, quest_action)
	pass
