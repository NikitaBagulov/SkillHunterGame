# SlowEffect.gd
class_name SlowEffect
extends EffectResource

func _init(_value: float = 30.0, _duration: float = 5.0):
	super._init("Slow", _value, _duration)  # _value в процентах
	particle_scene = preload("res://SkillSystem/Particles/water_particle.tscn")

func apply_effect(entity: Node) -> void:
	super.apply_effect(entity)
	if not is_instance_valid(entity) or entity.is_queued_for_deletion():
		#print("Entity '%s' is invalid or freed, skipping Burning effect processing" % entity.name)
		return
	if entity is Player:
		PlayerManager.PLAYER_STATS.move_speed *= (1.0 - value / 100.0)
	elif entity is Enemy or entity is Boss:
		entity.velocity *= (1.0 - value / 100.0)
	#print("Applied Slow effect to %s with value %s%%" % [entity.name, value])

func remove_effect(entity: Node) -> void:
	if entity is Player:
		PlayerManager.PLAYER_STATS.move_speed = PlayerManager.PLAYER_STATS.base_move_speed
	#print("Removed Slow effect from %s" % entity.name)
