extends Area2D
class_name HitBox

# --- Сигналы ---
## Сигнал, испускаемый при получении урона от HurtBox
signal Damaged(hurt_box: HurtBox)

# --- Управление уроном ---
## Обрабатывает получение урона и испускает сигнал Damaged
func take_damage(hurt_box: HurtBox) -> void:
	Damaged.emit(hurt_box)
