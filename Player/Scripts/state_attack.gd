class_name State_Attack extends State

var attacking: bool = false

@export_range(1, 20, 0.5) var decelerate_speed: float = 5.0

@onready var attack: State = $"."
@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"
@onready var hurt_box: HurtBox = %AttackHurtBox

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func enter() -> void:
	player.update_animation("attack")
	animation_player.animation_finished.connect(end_attack)
	attacking = true
	
	await  get_tree().create_timer(0.075).timeout
	hurt_box.monitoring = true
	
	pass
	
func exit() -> void:
	animation_player.animation_finished.disconnect(end_attack)
	attacking = false
	
	hurt_box.monitoring = false
	
	pass
	
func process(_delta: float) -> State:
	player.velocity -= player.velocity * decelerate_speed * _delta
	if attacking == false:
		if player.direction == Vector2.ZERO:
			return idle
		return walk
	return null

func physics(_delta: float) -> State:
	return null
	
func handle_input(_event: InputEvent) -> State:
	return null
	
func end_attack(_newAnimName: String) -> void:
	attacking = false
