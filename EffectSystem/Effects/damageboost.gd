# DamageBoostEffect.gd
class_name DamageBoostEffect
extends EffectResource

func _init(_value: float = 10.0, _duration: float = -1.0):  # -1.0 для пассивных
	super._init("DamageBoost", _value, _duration)

func apply_effect(entity: Node) -> void:
	if entity is Player:
		entity.stats.total_damage += int(value)
	print("Applied DamageBoost effect to %s with value %s" % [entity.name, value])

func remove_effect(entity: Node) -> void:
	if entity is Player:
		entity.stats.total_damage -= int(value)
	print("Removed DamageBoost effect from %s" % entity.name)
