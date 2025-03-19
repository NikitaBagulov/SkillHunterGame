extends Node
class_name Health

# --- Ссылки ---
## Ссылка на игрока из PlayerManager
var player: Player = null
## Ссылка на HitBox игрока
var hit_box: HitBox = null
## Ссылка на статистику игрока из PlayerManager
var stats: Stats = PlayerManager.PLAYER_STATS

# --- Инициализация ---
func _ready() -> void:
	# Если игрок уже существует, инициализируем сразу, иначе ждем его появления
	if PlayerManager.get_player():
		_initialize()
	else:
		await PlayerManager.player_assigned
		_initialize()

## Инициализирует здоровье игрока и связанные компоненты
func _initialize() -> void:
	player = PlayerManager.get_player()
	hit_box = player.get_node("HitBox")
	
	# Инициализируем здоровье и UI
	stats.hp = stats.max_hp
	Hud.update_max_hp(stats.max_hp)
	Hud.update_hp(stats.hp, stats.max_hp)
	stats.take_damage(0)  # Обновляем UI без реального урона

# --- Управление здоровьем ---
## Обновляет текущее здоровье с учетом изменений
func update_hp(delta: int) -> void:
	stats.hp = clampi(stats.hp + delta, 0, stats.max_hp)
	Hud.update_hp(stats.hp, stats.max_hp)

## Обрабатывает получение урона от HurtBox
func take_damage(hurt_box: HurtBox) -> void:
	if player.invulnerable:
		return
	
	stats.take_damage(hurt_box.damage)
	player.player_damaged.emit(hurt_box)
	
	# Если здоровье исчерпано, восстанавливаем его (временная механика)
	if stats.hp <= 0:
		stats.hp = stats.max_hp

## Восстанавливает здоровье на заданное количество
func heal(amount: int) -> void:
	stats.heal(amount)
	update_hp(amount)  # Обновляем UI после лечения

## Делает игрока неуязвимым на указанное время
func make_invulnerable(duration: float = 1.0) -> void:
	player.invulnerable = true
	hit_box.monitoring = false
	await get_tree().create_timer(duration).timeout
	player.invulnerable = false
	hit_box.monitoring = true
