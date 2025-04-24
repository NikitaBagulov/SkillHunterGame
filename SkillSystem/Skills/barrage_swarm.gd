# BarrageSwarmSkill.gd
extends SkillResource
class_name BarrageSwarmSkill

var effect_radius = 300.0
var spawn_radius = 100.0

func _init():
	name = "Barrage Swarm"
	type = SkillType.ACTIVE
	element = Element.NONE
	base_value = 15
	cooldown = 5.0
	duration = 0.0
	
	key_binding = KeyBinding.Q
	description = "Вызывает рой из 3–7 самонаводящихся снарядов, каждый наносит 15–75 урона ближайшему врагу. Эффект зависит от элемента."
	
	super._init()

func execute(player: Player) -> bool:
	if type == SkillType.ACTIVE:
		
		var projectile_count = 3 + level  # 3 снаряда на 1 уровне, 7 на 5
		for i in range(projectile_count):
			spawn_projectile()
		return true
	#print("Skill '%s' is not ACTIVE, cannot execute" % name)
	return false
	
func spawn_projectile():
	var projectile_scene = preload("res://SkillSystem/Projectiles/skill_projectile.tscn")
	var projectile = projectile_scene.instantiate()
	# Спавним в случайной точке в радиусе spawn_radius
	var angle = randf() * 2 * PI
	var offset = Vector2(cos(angle), sin(angle)) * randf_range(0, spawn_radius)
	projectile.global_position = PlayerManager.player.global_position + offset
	projectile.damage = base_value * level
	projectile.element = element
	projectile.projectile_owner = PlayerManager.player
	PlayerManager.player.get_tree().root.add_child(projectile)
	projectile.animation_player.play("spawn")
