extends Node
class_name Health

# --- Ссылки ---
var player: Player = null
var hit_box: HitBox = null
var stats: Stats = PlayerManager.PLAYER_STATS

# --- Настройки регенерации ---
const REGENERATION_INTERVAL: float = 5.0  # Интервал регенерации (в секундах)

# --- Инициализация ---
func _ready() -> void:
	if PlayerManager.get_player():
		_initialize()
	else:
		await PlayerManager.player_assigned
		_initialize()

func _initialize() -> void:
	player = PlayerManager.get_player()
	hit_box = player.get_node("HitBox")
	
	# Инициализируем здоровье и UI
	stats.hp = stats.max_hp
	Hud.update_hp(stats.hp, stats.max_hp)
	stats.take_damage(0)  # Обновляем UI без урона
	
	# Запускаем регенерацию
	start_regeneration()

# --- Управление здоровьем ---
func update_hp(delta: int) -> void:
	stats.hp = clampi(stats.hp + delta, 0, stats.max_hp)
	Hud.update_hp(stats.hp, stats.max_hp)

func take_damage(hurt_box: HurtBox) -> void:
	if player.invulnerable:
		return
	
	stats.take_damage(hurt_box.damage)
	player.player_damaged.emit(hurt_box)
	
	if stats.hp <= 0:
		PlayerManager.PLAYER_STATS.player_died.emit()
		#stats.hp = stats.max_hp

func heal(amount: int) -> void:
	stats.heal(amount)
	update_hp(amount)

func make_invulnerable(duration: float = 1.0) -> void:
	player.invulnerable = true
	hit_box.monitoring = false
	await get_tree().create_timer(duration).timeout
	player.invulnerable = false
	hit_box.monitoring = true

# --- Регенерация здоровья ---
func start_regeneration() -> void:
	while true:
		await get_tree().create_timer(REGENERATION_INTERVAL).timeout
		if not player.invulnerable and stats.hp < stats.max_hp and stats.hp > 0:
			heal(stats.hp_regeneration_value)
