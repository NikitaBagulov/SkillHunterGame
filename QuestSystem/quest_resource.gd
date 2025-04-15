class_name QuestResource extends Resource

enum QuestStatus { AVAILABLE, IN_PROGRESS, COMPLETED }

@export var quest_id: String
@export var title: String
@export var description: String
@export var objectives: Array[QuestObjective]
@export var status: QuestStatus = QuestStatus.AVAILABLE
@export var rewards: Array[Resource]

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
