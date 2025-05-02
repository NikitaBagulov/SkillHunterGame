# ItemEffectHeal.gd
class_name ItemEffectHeal
extends ItemEffect

@export var heal_amount: int = 1
@export var duration: float = 0.0  # Длительность эффекта (0 для моментального лечения)

func _init():
	use_description = "Heals for %s HP" % heal_amount
	# Создаем RegenerationEffect с заданными параметрами


func use(target: Node = PlayerManager.player) -> void:
	target.health.heal(heal_amount)
	
