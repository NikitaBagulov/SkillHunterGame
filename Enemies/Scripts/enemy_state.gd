extends Node
class_name EnemyState

# --- Переменные ---
## Ссылка на врага, которому принадлежит состояние
var enemy: Enemy = null
## Ссылка на управляющий конечный автомат
var state_machine: EnemyStateMachine = null

# --- Виртуальные методы ---
## Инициализация состояния (вызывается при создании)
func init() -> void:
	pass

## Выполняется при входе в состояние
func enter() -> void:
	pass

## Выполняется при выходе из состояния
func exit() -> void:
	pass

## Обработка каждого кадра, возвращает новое состояние или null
func process(_delta: float) -> EnemyState:
	return null

## Обработка физического шага, возвращает новое состояние или null
func physics(_delta: float) -> EnemyState:
	return null
