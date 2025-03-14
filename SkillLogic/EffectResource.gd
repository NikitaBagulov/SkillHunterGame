class_name EffectResource
extends Resource

@export var effect_type: EFFECTS
@export var value: float         # Величина эффекта (например, 10 урона)
@export var duration: float = 0.0  # Длительность (для временных эффектов)

enum EFFECTS {DAMAGE, HEAL}

func apply(target: Node):
	match effect_type:
		"damage":
			if target.has_method("take_damage"):
				target.take_damage(value)
		"heal":
			if target.has_method("heal"):
				target.heal(value)
		# Дополнительные типы эффектов можно добавить здесь
