class_name Player extends CharacterBody2D


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D 
@onready var state_machine: PlayerStateMachine = $StateMachine

var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO


func _ready():
	state_machine.initialize(self)
	pass
	
func _process(delta):
	#direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	#direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	#direction = direction.normalized()
	
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()
	pass
	
func _physics_process(delta):
	move_and_slide()

func set_direction() -> bool:
	var new_direction: Vector2 = cardinal_direction
	
	if direction == Vector2.ZERO:
		return false
	if direction.y == 0:
		new_direction = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	elif direction.x == 0:
		new_direction = Vector2.UP if direction.y < 0 else Vector2.DOWN
		
	if new_direction == cardinal_direction:
		return false
		
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
		
