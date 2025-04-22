# ShieldEffect.gd
class_name ShieldEffect
extends EffectResource

func _init(_value: float = 50.0, _duration: float = 5.0):
	super._init("Shield", _value, _duration)
	particle_scene = preload("res://SkillSystem/Particles/earth_particle.tscn")

func apply_effect(entity: Node) -> void:
	super.apply_effect(entity)
	if not is_instance_valid(entity) or entity.is_queued_for_deletion():
		print("Entity '%s' is invalid or freed, skipping Burning effect processing" % entity.name)
		return
	if entity is Player:
		PlayerManager.PLAYER_STATS.max_hp += int(value)
		PlayerManager.PLAYER_STATS.hp += int(value)
	elif entity is Enemy or entity is Boss:
		entity.HP += int(value)
	print("Applied Shield effect to %s with value %s" % [entity.name, value])

func remove_effect(entity: Node) -> void:
	if entity is Player:
		PlayerManager.PLAYER_STATS.max_hp -= int(value)
		PlayerManager.PLAYER_STATS.hp = min(PlayerManager.PLAYER_STATS.hp, PlayerManager.PLAYER_STATS.max_hp)
	elif entity is Enemy or entity is Boss:
		entity.HP -= int(value)
		entity.HP = max(0, entity.HP)
	print("Removed Shield effect from %s" % entity.name)
