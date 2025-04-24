# RegenerationEffect.gd
class_name RegenerationEffect
extends EffectResource

func _init(_value: float = 5.0, _duration: float = -1.0):  # -1.0 для пассивных
	super._init("Regeneration", _value, _duration)

func apply_effect(entity: Node) -> void:
	pass
	#print("Applied Regeneration effect to %s with value %s" % [entity.name, value])

func remove_effect(entity: Node) -> void:
	pass
	#print("Removed Regeneration effect from %s" % entity.name)

func process_effect(entity: Node, delta: float) -> void:
	var timer: float = 0.0
	timer += delta
	if timer >= 1.0:
		if entity is Player:
			PlayerManager.PLAYER_STATS.heal(int(value))
		elif entity is Enemy or entity is Boss:
			entity.change_heal(int(value))
		timer -= 1.0
