# EffectManager.gd
extends Node

# Хранилище активных эффектов: { сущность: { effect_name: { effect: EffectResource, timer: Timer } } }
var active_effects: Dictionary = {}

# Применение эффекта к сущности
func apply_effect(entity: Node, effect: EffectResource) -> void:
	if not entity or not effect or entity.is_queued_for_deletion():
		print("ERROR: Attempted to apply effect with invalid or freed entity or effect")
		return
	
	print("Applying effect '%s' to entity '%s' (value: %s, duration: %s, stackable: %s)" % [
		effect.name, entity.name, effect.value, effect.duration, effect.stackable
	])
	
	# Инициализируем хранилище для сущности
	if not active_effects.has(entity):
		active_effects[entity] = {}
		print("Initialized effect storage for entity '%s'" % entity.name)
	
	var effect_name = effect.name
	var effects = active_effects[entity]
	
	# Если эффект уже есть и он не стакается
	if effects.has(effect_name) and not effect.stackable:
		var existing = effects[effect_name]
		print("Effect '%s' already exists on '%s' (non-stackable, current value: %s, duration left: %s)" % [
			effect_name, entity.name, existing.effect.value, existing.timer.time_left
		])
		if effect.duration > existing.timer.time_left:
			print("Updating duration for '%s' from %s to %s seconds" % [
				effect_name, existing.timer.time_left, effect.duration
			])
			existing.timer.stop()
			existing.timer.wait_time = effect.duration
			existing.timer.start()
		existing.effect.value = max(existing.effect.value, effect.value)
		print("Updated effect value to %s" % existing.effect.value)
		return
	
	# Создаем таймер для эффекта (если длительность не бесконечна)
	var timer: Timer = null
	if effect.duration > 0:
		timer = Timer.new()
		timer.wait_time = effect.duration
		timer.one_shot = true
		timer.timeout.connect(_on_effect_timeout.bind(entity, effect_name))
		add_child(timer)
		timer.start()
		print("Created timer for effect '%s' on '%s' with duration %s seconds" % [
			effect_name, entity.name, effect.duration
		])
	
	effects[effect_name] = { "effect": effect.duplicate(), "timer": timer }
	print("Stored effect '%s' for entity '%s' (total effects: %s)" % [
		effect_name, entity.name, effects.size()
	])
	
	# Применяем эффект
	effect.apply_effect(entity)
	
	# Ограничиваем количество стаков
	if effect.stackable and effects.size() > effect.max_stacks:
		print("Max stacks (%s) exceeded for '%s', removing oldest effect" % [
			effect.max_stacks, entity.name
		])
		_remove_oldest_effect(entity)

# Удаление эффекта
func remove_effect(entity: Node, effect_name: String) -> void:
	if not active_effects.has(entity) or not active_effects[entity].has(effect_name):
		print("WARNING: Attempted to remove non-existent effect '%s' from entity '%s'" % [
			effect_name, entity.name
		])
		return
	
	print("Removing effect '%s' from entity '%s'" % [effect_name, entity.name])
	var effect_data = active_effects[entity][effect_name]
	effect_data.effect.remove_effect(entity)
	if effect_data.timer:
		effect_data.timer.stop()
		effect_data.timer.queue_free()
		print("Timer for effect '%s' on '%s' stopped and freed" % [effect_name, entity.name])
	active_effects[entity].erase(effect_name)
	print("Effect '%s' removed from '%s' (remaining effects: %s)" % [
		effect_name, entity.name, active_effects[entity].size()
	])
	
	if active_effects[entity].is_empty():
		active_effects.erase(entity)
		print("No effects left for entity '%s', storage cleared" % entity.name)

# Обработка периодических эффектов
func _process(delta: float) -> void:
	# Создаем копию ключей, чтобы избежать изменения словаря во время перебора
	var entities = active_effects.keys()
	for entity in entities:
		if not is_instance_valid(entity) or entity.is_queued_for_deletion():
			print("Entity (freed or queued for deletion) detected, removing all effects")
			#_clear_entity_effects(entity)
			continue
		for effect_name in active_effects[entity]:
			var effect_data = active_effects[entity][effect_name]
			effect_data.effect.process_effect(entity, delta)
			# Логируем только для эффектов с активной обработкой
			if effect_data.effect is BurningEffect or effect_data.effect is RegenerationEffect:
				print("Processing effect '%s' on '%s' (delta: %s)" % [
					effect_name, entity.name, delta
				])

# Очистка всех эффектов для сущности
func _clear_entity_effects(entity: Node) -> void:
	if not active_effects.has(entity):
		return
	for effect_name in active_effects[entity].keys():
		var effect_data = active_effects[entity][effect_name]
		effect_data.effect.remove_effect(entity)
		if effect_data.timer:
			effect_data.timer.stop()
			effect_data.timer.queue_free()
		print("Cleared effect '%s' from freed entity '%s'" % [effect_name, entity.name])
	active_effects.erase(entity)
	print("All effects cleared for freed entity '%s'" % entity.name)

# Обработка истечения времени эффекта
func _on_effect_timeout(entity: Node, effect_name: String) -> void:
	print("Effect '%s' timed out for entity '%s'" % [effect_name, entity.name])
	remove_effect(entity, effect_name)

# Удаление старейшего эффекта при превышении стаков
func _remove_oldest_effect(entity: Node) -> void:
	var effects = active_effects[entity]
	var oldest_effect_name = effects.keys()[0]
	print("Removing oldest effect '%s' from '%s' to enforce max stacks" % [
		oldest_effect_name, entity.name
	])
	remove_effect(entity, oldest_effect_name)
