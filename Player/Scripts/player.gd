class_name Player extends CharacterBody2D


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effect_animation_player: AnimationPlayer = $EffectAnimationPlayer
@onready var abilities: PlayerAbilities = $Abilities

@onready var sprite: Sprite2D = $Sprite2D 
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var hit_box: HitBox = $HitBox
@onready var audio: AudioStreamPlayer2D = $Audio/AudioStreamPlayer2D
@onready var health: Health = $HealthComponent
@onready var experience_manager: ExperienceManager = $ExperienceManager


var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO

const DIRECTIONS = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

signal DirectionChanged(new_direction: Vector2)
signal player_damaged(hurt_box: HurtBox)

var invulnerable: bool = false
#var HP: int = 6
#var max_HP: int = 6


func _ready():
	PlayerManager.set_player(self)
	abilities.player = self
	state_machine.initialize(self)
	hit_box.Damaged.connect(health.take_damage)
	experience_manager.stats = health.stats
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
	
	
	if direction == Vector2.ZERO:
		return false
	
	var direction_id: int = int(round(direction).angle() / TAU * DIRECTIONS.size())
	var new_direction = DIRECTIONS[direction_id]	
		
	if new_direction == cardinal_direction:
		return false
		
	DirectionChanged.emit(new_direction)	
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
