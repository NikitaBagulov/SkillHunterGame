class_name Enemy extends CharacterBody2D

signal direction_changed(new_direction: Vector2)
signal enemy_damaged(hurt_box: HurtBox)
signal enemy_destroyed(hurt_box: HurtBox)

const DIRECTIONS = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

@export var HP: int = 3
@export var experience_drop: int = 5  # Количество опыта, которое даёт враг

var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO
var player: Player
var invulnerable: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D 
@onready var hit_box: HitBox = $HitBox
@onready var state_machine: EnemyStateMachine = $EnemyStateMachine

# Called when the node enters the scene tree for the first time.
func _ready():
	state_machine.initialize(self)
	player = PlayerManager.player
	hit_box.Damaged.connect(_take_damage)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _physics_process(delta):
	move_and_slide()
	
func set_direction(_new_direction: Vector2) -> bool:
	direction = _new_direction
	
	if direction == Vector2.ZERO:
		return false
	
	var direction_id: int = int(round(direction).angle() / TAU * DIRECTIONS.size())
	var new_direction = DIRECTIONS[direction_id]	
		
	if new_direction == cardinal_direction:
		return false
		
	direction_changed.emit(new_direction)	
	cardinal_direction = new_direction
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	
	return true

func update_animation(state: String) -> void:
	animation_player.play(state + "_" + animation_direction())
	pass

func animation_direction() -> String:
	match cardinal_direction:
		Vector2.DOWN:
			return "down"	
		Vector2.UP:
			return "up"
		Vector2.LEFT:
			return "side"
		Vector2.RIGHT:
			return "side"
		_:
			return "down"
			
func _take_damage(hurt_box: HurtBox) -> void:
	if invulnerable == true:
		return
	HP -= hurt_box.damage
	if HP > 0:
		enemy_damaged.emit(hurt_box)
	else:
		print("Враг уничтожен, опыт: ", experience_drop)
		enemy_destroyed.emit(hurt_box)
