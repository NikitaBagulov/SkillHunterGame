extends Area2D
class_name HurtBox

# --- Настройки ---
## Урон, наносимый при столкновении с HitBox (для врагов или по умолчанию)
@export var damage: int = 1:
	get:
		# Если это HurtBox игрока, возвращаем урон из Stats, иначе фиксированное значение
		return PlayerManager.PLAYER_STATS.total_damage if _is_player_hurtbox() else damage
	set(value):
		damage = value  # Сеттер для фиксированного значения (используется врагами)

# --- Инициализация ---
func _ready() -> void:
	area_entered.connect(_on_area_entered)
	# Подключаемся к сигналу обновления урона игрока, если это HurtBox игрока
	if _is_player_hurtbox():
		PlayerManager.PLAYER_STATS.damage_updated.connect(_on_damage_updated)
		_on_damage_updated(PlayerManager.PLAYER_STATS.total_damage)  # Устанавливаем начальное значение

# --- Обработка столкновений ---
func _on_area_entered(area: Area2D) -> void:
	if area is HitBox:
		area.take_damage(self)

# --- Вспомогательные методы ---
## Проверяет, принадлежит ли HurtBox игроку
func _is_player_hurtbox() -> bool:
	return get_parent() == PlayerManager.get_player()

## Обновляет урон, если это HurtBox игрока
func _on_damage_updated(new_damage: int) -> void:
	if _is_player_hurtbox():
		print("Player HurtBox damage updated to: %d" % new_damage)
