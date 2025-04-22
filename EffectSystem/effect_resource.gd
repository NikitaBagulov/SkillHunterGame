# EffectResource.gd
class_name EffectResource
extends Resource

@export var name: String = "Effect"
@export var duration: float = 5.0  # Длительность эффекта в секундах
@export var stackable: bool = false  # Можно ли стакать эффект
@export var max_stacks: int = 3  # Максимальное количество стаков
@export var value: float = 10.0  # Значение эффекта (урон, процент замедления и т.д.)
@export var particle_scene: PackedScene  # Сцена с CPUParticles2D

func _init(_name: String = "Effect", _value: float = 10.0, _duration: float = 5.0):
	name = _name
	value = _value
	duration = _duration

# Виртуальный метод для применения эффекта
func apply_effect(entity: Node) -> void:
	if particle_scene:
		var particles = particle_scene.instantiate()
		entity.add_child(particles)
		particles.global_position = entity.global_position
		particles.emitting = true
		
		if particles is CPUParticles2D:
			var total_lifetime = max(duration, particles.lifetime)
			if particles.one_shot:
				particles.get_tree().create_timer(duration, false).timeout.connect(
					func():
						if is_instance_valid(particles):
							print("Freeing particles for effect '%s'" % name)
							particles.queue_free()
				)
			else:
				particles.get_tree().create_timer(duration, false).timeout.connect(
					func():
						if is_instance_valid(particles):
							particles.emitting = false
							particles.get_tree().create_timer(particles.lifetime, false).timeout.connect(
								func():
									if is_instance_valid(particles):
										print("Freeing particles for effect '%s'" % name)
										particles.queue_free()
							)
				)

# Виртуальный метод для удаления эффекта
func remove_effect(entity: Node) -> void:
	pass

# Виртуальный метод для обработки периодических действий (если нужно)
func process_effect(entity: Node, delta: float) -> void:
	pass
