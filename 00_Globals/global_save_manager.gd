extends Node

# Путь к файлу сохранения
const SAVE_PATH: String = "user://savegame.save"
# Ключ для шифрования (в виде PackedByteArray)
var ENCRYPTION_KEY: PackedByteArray = "my_secret_key_123".to_utf8_buffer()

# Сигналы для уведомления о состоянии сохранения/загрузки
signal save_completed(success: bool)
signal load_completed(success: bool)

func _ready() -> void:
	name = "SaveManager"
	if not Repository.instance:
		push_error("Repository not found! Ensure it is autoloaded.")
		return

# Сохранение игры (синхронное)
func save_game() -> bool:
	var save_data = Repository.instance.serialize()
	var file = FileAccess.open_encrypted(SAVE_PATH, FileAccess.WRITE, ENCRYPTION_KEY)
	if file:
		file.store_var(save_data, true)
		file.close()
		Repository.instance.log_message("Game saved successfully")
		save_completed.emit(true)
		return true
	else:
		Repository.instance.log_message("Failed to save game")
		save_completed.emit(false)
		return false

# Загрузка игры (синхронное)
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		Repository.instance.log_message("No save file found at: %s" % SAVE_PATH)
		load_completed.emit(false)
		return false
	
	var file = FileAccess.open_encrypted(SAVE_PATH, FileAccess.READ, ENCRYPTION_KEY)
	if file:
		var save_data = file.get_var(true)
		file.close()
		if save_data is Dictionary:
			var success = Repository.instance.deserialize(save_data)
			load_completed.emit(success)
			if success:
				Repository.instance.log_message("Game loaded successfully")
			else:
				Repository.instance.log_message("Failed to load game: Invalid data")
			return success
		else:
			Repository.instance.log_message("Failed to load game: Corrupted file")
			load_completed.emit(false)
			return false
	else:
		Repository.instance.log_message("Failed to open save file")
		load_completed.emit(false)
		return false

# Асинхронное сохранение с использованием потока
func save_game_async() -> bool:
	var thread = Thread.new()
	var save_data = Repository.instance.serialize()
	var error = thread.start(_write_save_file.bind(save_data))
	if error != OK:
		Repository.instance.log_message("Failed to start save thread: %s" % error)
		save_completed.emit(false)
		return false
	
	# Ожидаем завершения потока
	var success = thread.wait_to_finish()
	save_completed.emit(success)
	if success:
		Repository.instance.log_message("Game saved successfully (async)")
	else:
		Repository.instance.log_message("Failed to save game (async)")
	return success

# Асинхронная загрузка с использованием потока
func load_game_async() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		Repository.instance.log_message("No save file found at: %s" % SAVE_PATH)
		load_completed.emit(false)
		return false
	
	var thread = Thread.new()
	var error = thread.start(_read_save_file)
	if error != OK:
		Repository.instance.log_message("Failed to start load thread: %s" % error)
		load_completed.emit(false)
		return false
	
	# Ожидаем завершения потока
	var save_data = thread.wait_to_finish()
	if save_data is Dictionary:
		var success = Repository.instance.deserialize(save_data)
		load_completed.emit(success)
		if success:
			Repository.instance.log_message("Game loaded successfully (async)")
		else:
			Repository.instance.log_message("Failed to load game: Invalid data (async)")
		return success
	else:
		Repository.instance.log_message("Failed to load game: Corrupted file (async)")
		load_completed.emit(false)
		return false

# Вспомогательная функция для сохранения в потоке
func _write_save_file(save_data: Dictionary) -> bool:
	var file = FileAccess.open_encrypted(SAVE_PATH, FileAccess.WRITE, ENCRYPTION_KEY)
	if file:
		file.store_var(save_data, true)
		file.close()
		return true
	return false

# Вспомогательная функция для чтения в потоке
func _read_save_file() -> Variant:
	var file = FileAccess.open_encrypted(SAVE_PATH, FileAccess.READ, ENCRYPTION_KEY)
	if file:
		var data = file.get_var(true)
		file.close()
		return data
	return null

# Очистка сохранений
func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		Repository.instance.clear_category("")
		Repository.instance.log_message("Save file cleared")
