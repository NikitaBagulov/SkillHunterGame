class_name Player
extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effect_animation_player: AnimationPlayer = $EffectAnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D 
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var hit_box: HitBox = $HitBox
@onready var audio: AudioStreamPlayer2D = $Audio/AudioStreamPlayer2D
@onready var health: Health = $HealthComponent
@onready var experience_manager: ExperienceManager = $ExperienceManager
@onready var weapon_texture: Sprite2D = $WeaponSprite
@onready var attack_hurt_box: HurtBox = %AttackHurtBox
@onready var skill_manager: SkillManager = $SkillManager

var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO

const DIRECTIONS = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

signal DirectionChanged(new_direction: Vector2)
signal player_damaged(hurt_box: HurtBox)

var invulnerable: bool = false

func _ready():
	# Ждем готовности PlayerManager
	if PlayerManager.is_inside_tree():
		_initialize_player()
	else:
		PlayerManager.manager_ready.connect(_initialize_player)

func _initialize_player():
	# Устанавливаем игрока
	PlayerManager.set_player(self)
	skill_manager.player = self
	state_machine.initialize(self)
	hit_box.Damaged.connect(health.take_damage)
	experience_manager.stats = PlayerManager.PLAYER_STATS
	weapon_texture.visible = false
	
	# Инициализируем Stats, если нужно
	if not PlayerManager.PLAYER_STATS._is_initialized:
		PlayerManager.PLAYER_STATS.initialize()
	
	# Синхронизируем начальную позицию
	PlayerManager.PLAYER_STATS.position = global_position
	PlayerManager.PLAYER_STATS.position_updated.connect(_on_position_updated)
	
	# Регистрируем Stats в Repository
	Repository.instance.register("player", "stats", PlayerManager.PLAYER_STATS, true)
	
	# Обновляем текстуру оружия
	#change_weapon_texture(PlayerManager.INVENTORY_DATA.get_equipped_weapon_texture())
	
	# Уведомляем о начальном состоянии
	PlayerManager.PLAYER_STATS.player_level_up.emit(PlayerManager.PLAYER_STATS)

func _process(delta):
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()

func _physics_process(delta):
	# Используем скорость из Stats
	velocity = direction * PlayerManager.PLAYER_STATS.move_speed
	move_and_slide()
	# Обновляем позицию в Stats после перемещения
	if global_position != PlayerManager.PLAYER_STATS.position:
		PlayerManager.PLAYER_STATS.position = global_position
		Repository.instance.update_data("player", "stats", PlayerManager.PLAYER_STATS)

func change_weapon_texture(texture: Texture) -> void:
	weapon_texture.texture = texture
	skill_manager.update_passive_skills()

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

func _on_position_updated(new_position: Vector2) -> void:
	# Синхронизируем позицию
	global_position = new_position
