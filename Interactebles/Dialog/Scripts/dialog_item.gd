@tool
@icon("res://GUI/Dialog/Icons/chat_bubble.svg")
class_name DialogItem extends Node

@export var npc_info: NPCResource

func _ready():
	if Engine.is_editor_hint():
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
					
