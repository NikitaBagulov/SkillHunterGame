# BurningEffect.gd
class_name BurningEffect
extends EffectResource

# Статический таймер для отслеживания интервалов урона
static var timers: Dictionary = {}  # { entity: float }

func _init(_value: float = 1.0, _duration: float = 5.0):
	super._init("Burning", _value, _duration)
	particle_scene = preload("res://SkillSystem/Particles/fire_particle.tscn")

func apply_effect(entity: Node) -> void:
	super.apply_effect(entity)
	if not is_instance_valid(entity) or entity.is_queued_for_deletion():
		#print("Entity '%s' is invalid or freed, skipping Burning effect processing" % entity.name)
		return
	# Инициализируем таймер для сущности
	if not timers.has(entity):
		timers[entity] = 0.0

func remove_effect(entity: Node) -> void:
	#print("Removed Burning effect from %s" % entity.name)
	# Очищаем таймер для сущности
	if timers.has(entity):
		timers.erase(entity)

func process_effect(entity: Node, delta: float) -> void:
	# Наносим урон раз в секунду
	if not timers.has(entity):
		timers[entity] = 0.0
	
	timers[entity] += delta
	if timers[entity] >= 1.0:
		if entity is Player:
			PlayerManager.PLAYER_STATS.take_damage(int(value))
			#print("Burning dealt %s damage to Player" % value)
		elif entity is Enemy or entity is Boss:
			entity.change_health(-int(value))
			#print("Burning dealt %s damage to Boss '%s'" % [value, entity.name])
		timers[entity] -= 1.0
