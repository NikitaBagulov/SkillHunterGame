class_name EquipableItemData extends ItemData

enum Type { HEAD, BODY, PANTS, BOOTS, WEAPON, ACCESSORY}
@export var type: Type = Type.WEAPON
@export var modifiers: Array[EquipableItemModifier]

# Использование оружия (атака)
func use() -> bool:
	if type == Type.WEAPON:
		PlayerManager.use_weapon(self)
		return true
	return false  # Для других типов ничего не делаем в use()

# Получение бонуса к урону
func get_attack_bonus() -> int:
	var bonus: int = 0
	for modifier in modifiers:
		if modifier.type == EquipableItemModifier.Type.ATTACK:
			bonus += modifier.value
	return bonus
