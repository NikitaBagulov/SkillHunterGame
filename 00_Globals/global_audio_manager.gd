extends Node

# --- Константы и настройки ---
## Количество музыкальных плееров для кроссфейда
const MUSIC_PLAYER_COUNT: int = 2
## Название аудиобуса для музыки
const MUSIC_BUS: String = "Music"
## Длительность затухания/нарастания звука в секундах
const FADE_DURATION: float = 0.5
## Минимальная громкость в децибелах (для затухания)
const MIN_VOLUME_DB: float = -40.0
## Максимальная громкость в децибелах (для воспроизведения)
const MAX_VOLUME_DB: float = 0.0

# --- Переменные ---
## Индекс текущего активного плеера
var current_music_player: int = 0
## Массив музыкальных плееров
var music_players: Array[AudioStreamPlayer] = []

# --- Инициализация ---
func _ready() -> void:
	# Устанавливаем режим обработки для работы даже на паузе
	process_mode = PROCESS_MODE_ALWAYS
	_initialize_music_players()

## Создает и настраивает музыкальные плееры
func _initialize_music_players() -> void:
	for i in MUSIC_PLAYER_COUNT:
		var player = AudioStreamPlayer.new()
		add_child(player)
		player.bus = MUSIC_BUS
		player.volume_db = MIN_VOLUME_DB
		music_players.append(player)

# --- Управление воспроизведением ---
## Воспроизводит новую музыкальную дорожку с кроссфейдом
func play_music(audio: AudioStream) -> void:
	if not audio or audio == music_players[current_music_player].stream:
		return

	var new_player = music_players[current_music_player]
	var old_player = music_players[1 - current_music_player]  # Переключение между 0 и 1
	
	new_player.stream = audio
	_fade_in(new_player)
	_fade_out(old_player)
	
	current_music_player = 1 - current_music_player  # Переключаем текущий плеер

# --- Эффекты перехода ---
## Постепенно увеличивает громкость и начинает воспроизведение
func _fade_in(player: AudioStreamPlayer) -> void:
	player.play(0)
	var tween = create_tween()
	tween.tween_property(player, "volume_db", MAX_VOLUME_DB, FADE_DURATION)

## Постепенно уменьшает громкость и останавливает воспроизведение
func _fade_out(player: AudioStreamPlayer) -> void:
	var tween = create_tween()
	tween.tween_property(player, "volume_db", MIN_VOLUME_DB, FADE_DURATION)
	await tween.finished
	player.stop()
