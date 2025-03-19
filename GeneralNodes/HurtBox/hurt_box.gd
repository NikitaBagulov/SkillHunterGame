extends Area2D
class_name HurtBox

# --- Настройки ---
## Урон, наносимый при столкновении с HitBox
@export var damage: int = 1

# --- Инициализация ---
func _ready() -> void:
	area_entered.connect(_on_area_entered)

# --- Обработка столкновений ---
## Обрабатывает вход другой области (HitBox) и наносит урон
func _on_area_entered(area: Area2D) -> void:
	if area is HitBox:
		area.take_damage(self)
