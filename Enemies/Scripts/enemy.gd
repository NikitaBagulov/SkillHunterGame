extends CharacterBody2D
class_name Enemy

# --- Сигналы ---
## Сигнал изменения направления движения
signal direction_changed(new_direction: Vector2)
## Сигнал получения урона врагом
signal enemy_damaged(hurt_box: HurtBox)
## Сигнал уничтожения врага
signal enemy_destroyed(hurt_box: HurtBox)

# --- Константы ---
## Возможные кардинальные направления движения
const DIRECTIONS: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

# --- Настройки ---
## ID врага
@export var enemy_id: String
## Здоровье врага
@export var HP: int = 5
## Количество опыта за уничтожение врага
@export var experience_drop: int = 5

# --- Переменные ---
## Текущее кардинальное направление
var cardinal_direction: Vector2 = Vector2.DOWN
## Вектор движения
var direction: Vector2 = Vector2.ZERO
## Ссылка на игрока
var player: Player = null
## Флаг неуязвимости
var invulnerable: bool = false

# --- Ссылки на узлы ---
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_box: HitBox = $HitBox
@onready var state_machine: EnemyStateMachine = $EnemyStateMachine

# --- Инициализация ---
func _ready() -> void:
	state_machine.initialize(self)
	player = PlayerManager.player
	hit_box.Damaged.connect(_take_damage)

# --- Обработка физики ---
func _physics_process(_delta: float) -> void:
	move_and_slide()

# --- Управление движением ---
## Устанавливает новое направление движения
func set_direction(new_direction: Vector2) -> bool:
	direction = new_direction
	if direction == Vector2.ZERO:
		return false
	
	var direction_id: int = int(round(direction).angle() / TAU * DIRECTIONS.size())
	var new_cardinal = DIRECTIONS[direction_id]
	
	if new_cardinal == cardinal_direction:
		return false
	
	cardinal_direction = new_cardinal
	direction_changed.emit(cardinal_direction)
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true

# --- Управление анимацией ---
## Воспроизводит анимацию в зависимости от состояния и направления
func update_animation(state: String) -> void:
	animation_player.play(state + "_" + _get_animation_direction())

## Возвращает строковое представление направления для анимации
func _get_animation_direction() -> String:
	match cardinal_direction:
		Vector2.DOWN: return "down"
		Vector2.UP: return "up"
		Vector2.LEFT: return "side"
		Vector2.RIGHT: return "side"
		_: return "down"

# --- Обработка урона ---
## Применяет урон к врагу и вызывает соответствующие сигналы
func _take_damage(hurt_box: HurtBox) -> void:
	if invulnerable:
		return
	
	HP -= hurt_box.damage
	if HP > 0:
		enemy_damaged.emit(hurt_box)
	else:
		print("Enemy destroyed, experience: ", experience_drop)
		enemy_destroyed.emit(hurt_box)
