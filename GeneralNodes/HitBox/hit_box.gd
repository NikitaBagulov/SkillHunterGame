extends Area2D
class_name HitBox

# --- Сигналы ---
## Сигнал, испускаемый при получении урона от HurtBox
signal Damaged(hurt_box: HurtBox)

# --- Управление уроном ---
## Обрабатывает получение урона и испускает сигнал Damaged
func take_damage(hurt_box: HurtBox) -> void:
	print("HitBox took damage from: ", hurt_box, " (damage: ", hurt_box.damage, ")")
	Damaged.emit(hurt_box)
