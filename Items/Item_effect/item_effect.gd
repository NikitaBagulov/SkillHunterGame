# ItemEffect.gd
class_name ItemEffect
extends Resource

@export var use_description: String
@export var effect_resource: EffectResource
@export var particle_effect: PackedScene  # Сцена с CPUParticles2D

func use(target: Node = PlayerManager.player) -> void:
	if effect_resource:
		EffectManager.apply_effect(target, effect_resource)
		print("ItemEffect: Applied '%s' to '%s'" % [effect_resource.name, target.name])
	if particle_effect:
		var particles = particle_effect.instantiate()
		target.add_child(particles)
		particles.global_position = target.global_position
		particles.emitting = true
		print("ItemEffect: Spawned particle effect for '%s' on '%s'" % [effect_resource.name, target.name])
