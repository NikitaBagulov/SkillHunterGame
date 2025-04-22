# KnockbackEffect.gd
class_name KnockbackEffect
extends EffectResource

func _init(_value: float = 200.0, _duration: float = 0.1):
	super._init("Knockback", _value, _duration)
	particle_scene = preload("res://SkillSystem/Particles/air_particle.tscn")

func apply_effect(entity: Node) -> void:
	super.apply_effect(entity)
	if not is_instance_valid(entity) or entity.is_queued_for_deletion():
		print("Entity '%s' is invalid or freed, skipping Burning effect processing" % entity.name)
		return
	if entity is Enemy or entity is Boss:
		var direction = (entity.global_position - PlayerManager.player.global_position).normalized()
		entity.velocity = direction * value
	print("Applied Knockback effect to %s with value %s" % [entity.name, value])

func remove_effect(entity: Node) -> void:
	print("Removed Knockback effect from %s" % entity.name)
