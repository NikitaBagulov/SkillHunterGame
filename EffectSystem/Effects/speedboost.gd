# SpeedBoostEffect.gd
class_name SpeedBoostEffect
extends EffectResource

func _init(_value: float = 20.0, _duration: float = -1.0):  # -1.0 для пассивных
	super._init("SpeedBoost", _value, _duration)

func apply_effect(entity: Node) -> void:
	if entity is Player:
		entity.stats.move_speed += value
	print("Applied SpeedBoost effect to %s with value %s" % [entity.name, value])

func remove_effect(entity: Node) -> void:
	if entity is Player:
		entity.stats.move_speed -= value
	print("Removed SpeedBoost effect from %s" % entity.name)
