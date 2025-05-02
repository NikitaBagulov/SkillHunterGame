class_name QuestResource extends Resource

enum QuestStatus { AVAILABLE, IN_PROGRESS, COMPLETED }

@export var quest_id: String
@export var title: String
@export var description: String
@export var objectives: Array[QuestObjective]
@export var status: QuestStatus = QuestStatus.AVAILABLE
@export var rewards: Array[Resource]
@export var required_quest_id: String = ""

func update_objective(objective_id: String, value: int) -> bool:
	for objective in objectives:
		if objective.objective_id == objective_id:
			objective.current_value += value
			if objective.current_value >= objective.target_value:
				objective.completed = true
			return true
	return false

func is_completed() -> bool:
	for objective in objectives:
		if not objective.completed:
			return false
	return true
func serialize() -> Dictionary:
	var serialized_objectives: Array = []
	for objective in objectives:
		serialized_objectives.append(objective.serialize() if objective.has_method("serialize") else {
			"objective_id": objective.objective_id,
			"description": objective.description,
			"progress": objective.progress,
			"target": objective.target,
			"completed": objective.completed,
			"item_id": objective.item_id,
			"enemy_id": objective.enemy_id,
			"npc_id": objective.npc_id,
			"boss_id": objective.boss_id
		})
	
	var serialized_rewards: Array = []
	for reward in rewards:
		if reward is Resource:
			serialized_rewards.append(reward.resource_path)
	
	return {
		"class_name": "QuestResource",
		"quest_id": quest_id,
		"title": title,
		"description": description,
		"required_quest_id": required_quest_id,
		"status": status,
		"objectives": serialized_objectives,
		"rewards": serialized_rewards
	}

func deserialize(data: Dictionary) -> void:
	quest_id = data.get("quest_id", "")
	title = data.get("title", "")
	description = data.get("description", "")
	required_quest_id = data.get("required_quest_id", "")
	status = data.get("status", QuestStatus.AVAILABLE)
	
	objectives = []
	var objectives_data = data.get("objectives", [])
	for obj_data in objectives_data:
		var objective = QuestObjective.new()
		if obj_data is Dictionary and objective.has_method("deserialize"):
			objective.deserialize(obj_data)
		else:
			objective.objective_id = obj_data.get("objective_id", "")
			objective.description = obj_data.get("description", "")
			objective.progress = obj_data.get("progress", 0)
			objective.target = obj_data.get("target", 0)
			objective.completed = obj_data.get("completed", false)
			objective.item_id = obj_data.get("item_id", "")
			objective.enemy_id = obj_data.get("enemy_id", "")
			objective.npc_id = obj_data.get("npc_id", "")
			objective.boss_id = obj_data.get("boss_id", "")
		objectives.append(objective)
	
	rewards = []
	var rewards_data = data.get("rewards", [])
	for reward_path in rewards_data:
		if ResourceLoader.exists(reward_path):
			rewards.append(load(reward_path))
