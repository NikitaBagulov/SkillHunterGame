class_name QuestObjective extends Resource

@export var objective_id: String
@export var description: String
@export var target_value: int
@export var current_value: int
@export var completed: bool = false

@export var item_id: String
@export var enemy_id: String
@export var npc_id: String
@export var boss_id: String

func serialize() -> Dictionary:
	return {
		"objective_id": objective_id,
		"description": description,
		"current_value": current_value,
		"target_value": target_value,
		"completed": completed,
		"item_id": item_id,
		"enemy_id": enemy_id,
		"npc_id": npc_id,
		"boss_id": boss_id
	}

func deserialize(data: Dictionary) -> void:
	objective_id = data.get("objective_id", "")
	description = data.get("description", "")
	current_value = data.get("current_value", 0)
	target_value = data.get("target_value", 0)
	completed = data.get("completed", false)
	item_id = data.get("item_id", "")
	enemy_id = data.get("enemy_id", "")
	npc_id = data.get("npc_id", "")
	boss_id = data.get("boss_id", "")
