extends CharacterBody2D
class_name Enemy

# --- Signals ---
signal direction_changed(new_direction: Vector2)
signal enemy_damaged(hurt_box: HurtBox)
signal enemy_destroyed(hurt_box: HurtBox)

# --- Constants ---
const DIRECTIONS: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

# --- Settings ---
@export var enemy_id: String
@export var HP: int = 5
@export var speed: float = 100.0
@export var experience_drop: int = 5
@export var two_directions_only: bool = false
@export var difficulty: float = 1.0  # Difficulty multiplier for stats

var max_hp: int = HP
var base_speed: float = speed
var base_damage: int = 1  # Base damage for hurt_box

# --- Variables ---
var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO
var player: Player = null
var invulnerable: bool = false

# --- Node References ---
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_box: HitBox = $HitBox
@onready var hurt_box: HurtBox = $HurtBox
@onready var state_machine: EnemyStateMachine = $EnemyStateMachine

# --- Initialization ---
func _ready() -> void:
	apply_difficulty()
	state_machine.initialize(self)
	player = PlayerManager.player
	hit_box.Damaged.connect(_take_damage)
	cardinal_direction = Vector2.RIGHT if two_directions_only else Vector2.DOWN
	add_to_group("enemies")

func apply_difficulty() -> void:
	HP = int(HP * difficulty)
	max_hp = HP
	speed = base_speed * difficulty
	if hurt_box:
		hurt_box.damage = int(base_damage * difficulty)

# --- Physics Processing ---
func _physics_process(_delta: float) -> void:
	move_and_slide()

# --- Movement Control ---
func set_direction(new_direction: Vector2) -> bool:
	direction = new_direction
	if direction == Vector2.ZERO:
		return false
	
	var new_cardinal: Vector2
	
	if two_directions_only:
		new_cardinal = Vector2.RIGHT if direction.x >= 0 else Vector2.LEFT
	else:
		var direction_id: int = int(round(direction).angle() / TAU * DIRECTIONS.size())
		new_cardinal = DIRECTIONS[direction_id]
	
	if new_cardinal == cardinal_direction:
		return false
	
	cardinal_direction = new_cardinal
	direction_changed.emit(cardinal_direction)
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true

# --- Animation Control ---
func update_animation(state: String) -> void:
	animation_player.play(state + "_" + _get_animation_direction())

func _get_animation_direction() -> String:
	if two_directions_only:
		return "side"
	else:
		match cardinal_direction:
			Vector2.DOWN: return "down"
			Vector2.UP: return "up"
			Vector2.LEFT: return "side"
			Vector2.RIGHT: return "side"
			_: return "down"

func change_health(amount: int) -> void:
	HP = clamp(HP + amount, 0, max_hp)
	if HP <= 0:
		enemy_destroyed.emit(null)
		queue_free()

# --- Damage Handling ---
func _take_damage(hurt_box: HurtBox) -> void:
	if invulnerable:
		return
	
	HP -= hurt_box.damage
	if HP > 0:
		enemy_damaged.emit(hurt_box)
	else:
		enemy_destroyed.emit(hurt_box)

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	sprite.visible = true
	state_machine.set_physics_process(true)
	state_machine.set_process(true)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	sprite.visible = false
	state_machine.set_physics_process(false)
	state_machine.set_process(false)
