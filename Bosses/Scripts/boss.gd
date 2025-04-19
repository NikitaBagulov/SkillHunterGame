extends CharacterBody2D
class_name Boss

# --- Сигналы ---
## Сигнал изменения направления движения
signal direction_changed(new_direction: Vector2)
## Сигнал получения урона врагом
signal boss_damaged(hurt_box: HurtBox)
## Сигнал уничтожения врага
signal boss_destroyed(hurt_box: HurtBox)

# --- Константы ---
## Возможные кардинальные направления движения (только налево и направо)
const DIRECTIONS: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT]

# --- Настройки ---
## ID врага
@export var boss_id: String
## Здоровье врага
@export var HP: int = 5
## Количество опыта за уничтожение врага
@export var experience_drop: int = 5

# --- Переменные ---
## Текущее кардинальное направление
var cardinal_direction: Vector2 = Vector2.RIGHT
## Вектор движения
var direction: Vector2 = Vector2.ZERO
## Ссылка на игрока
var player: Player = null
## Флаг неуязвимости
var invulnerable: bool = false
## Максимальное здоровье для шкалы
var max_hp: int = 0

# --- Ссылки на узлы ---
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_box: HitBox = $HitBox
@onready var state_machine: BossStateMachine = $BossStateMachine
@onready var hp_bar: ProgressBar = $HP_bar
@onready var label: Label = $HP_bar/Label
@onready var spawn_points: Array[Node2D] = [
	$Spawn1,
	$Spawn2,
	$Spawn3,
	$Spawn4
]


# --- Инициализация ---
func _ready() -> void:
	state_machine.initialize(self)
	player = PlayerManager.player
	hit_box.Damaged.connect(_take_damage)
	# Инициализация шкалы здоровья
	max_hp = HP
	hp_bar.max_value = max_hp
	hp_bar.value = HP
	label.text = "%d/%d" % [HP, max_hp]
	# Воспроизводим анимацию idle при старте
	animation_player.play("idle")

# --- Обработка физики ---
func _physics_process(_delta: float) -> void:
	move_and_slide()

# --- Управление движением ---
## Устанавливает новое направление движения
func set_direction(new_direction: Vector2) -> bool:
	direction = new_direction
	if direction == Vector2.ZERO:
		return false
	
	# Определяем ближайшее направление (налево или направо) по оси X
	var new_cardinal: Vector2 = Vector2.RIGHT if direction.x >= 0 else Vector2.LEFT
	
	if new_cardinal == cardinal_direction:
		return false
	
	cardinal_direction = new_cardinal
	direction_changed.emit(cardinal_direction)
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true

func change_health(amount: int) -> void:
	HP = clamp(HP + amount, 0, max_hp)
	hp_bar.value = HP
	label.text = "%d/%d" % [HP, max_hp]
	if HP <= 0:
		print("Boss destroyed, experience: ", experience_drop)
		boss_destroyed.emit(null)

## Применяет лечение и обновляет шкалу
func change_heal(amount: int) -> void:
	if amount <= 0:
		print("Warning: Heal amount must be positive")
		return
	HP = clamp(HP + amount, 0, max_hp)
	hp_bar.value = HP
	label.text = "%d/%d" % [HP, max_hp]

# --- Управление анимацией ---
## Воспроизводит анимацию idle независимо от состояния
func update_animation(_state: String) -> void:
	animation_player.play("idle")

# --- Обработка урона ---
## Применяет урон к врагу и вызывает соответствующие сигналы
func _take_damage(hurt_box: HurtBox) -> void:
	if invulnerable:
		return
	HP -= hurt_box.damage
	# Обновляем шкалу здоровья
	hp_bar.value = HP
	label.text = "%d/%d" % [HP, max_hp]
	if HP > 0:
		boss_damaged.emit(hurt_box)
	else:
		print("Boss destroyed, experience: ", experience_drop)
		boss_destroyed.emit(hurt_box)
		queue_free()

func get_projectile_spawn_position(index: int) -> Vector2:
	var spawn_point = spawn_points[index % spawn_points.size()]
	var offset = spawn_point.position
	if sprite.scale.x < 0:  # Если спрайт отражён (смотрит налево)
		offset.x = -offset.x  # Инвертируем X-координату
	return global_position + offset
