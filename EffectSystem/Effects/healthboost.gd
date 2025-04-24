# HealthBoostEffect.gd
class_name HealthBoostEffect
extends EffectResource

func _init(_value: float = 50.0, _duration: float = -1.0):  # -1.0 для пассивных
	super._init("HealthBoost", _value, _duration)

func apply_effect(entity: Node) -> void:
	if entity is Player:
		entity.stats.max_hp += int(value)
		entity.stats.hp += int(value)
	#print("Applied HealthBoost effect to %s with value %s" % [entity.name, value])

func remove_effect(entity: Node) -> void:
	if entity is Player:
		entity.stats.max_hp -= int(value)
		entity.stats.hp = min(entity.stats.hp, entity.stats.max_hp)
	#print("Removed HealthBoost effect from %s" % entity.name)
