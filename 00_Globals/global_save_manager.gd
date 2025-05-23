extends Node

#static var instance: SaveManager = null

# Путь к файлу сохранения
const SAVE_PATH: String = "user://savegame.save"

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
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		Repository.instance.log_message("Opening file for saving...")
		file.store_var(save_data, true)
		file.close()
		Repository.instance.log_message("Game saved successfully (sync)")
		save_completed.emit(true)
		return true
	else:
		Repository.instance.log_message("Failed to open file for saving")
		save_completed.emit(false)
		return false

# Загрузка игры (синхронное)
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		Repository.instance.log_message("No save file found at: %s" % SAVE_PATH)
		load_completed.emit(false)
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		Repository.instance.log_message("Opening file for loading...")
		var save_data = file.get_var(true)
		file.close()

		if save_data is Dictionary:
			var success = Repository.instance.deserialize(save_data)
			load_completed.emit(success)
			Repository.instance.log_message("Game loaded successfully (sync)" if success else "Failed to load game: Invalid data")
			return success
		else:
			Repository.instance.log_message("Failed to load game: Data is not a Dictionary")
	else:
		Repository.instance.log_message("Failed to open save file for reading")

	load_completed.emit(false)
	return false

# Асинхронное сохранение
func save_game_async() -> bool:
	var thread = Thread.new()
	var save_data = Repository.instance.serialize()
	var error = thread.start(_write_save_file.bind(save_data))

	if error != OK:
		Repository.instance.log_message("Failed to start save thread: %s" % error)
		save_completed.emit(false)
		return false

	var success = thread.wait_to_finish()
	save_completed.emit(success)
	Repository.instance.log_message("Game saved successfully (async)" if success else "Failed to save game (async)")
	return success

# Асинхронная загрузка
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

	var save_data = thread.wait_to_finish()
	if save_data is Dictionary:
		var success = Repository.instance.deserialize(save_data)
		load_completed.emit(success)
		Repository.instance.log_message("Game loaded successfully (async)" if success else "Failed to load game: Invalid data (async)")
		return success
	else:
		Repository.instance.log_message("Failed to load game: Data is corrupted or null (async)")
		load_completed.emit(false)
		return false

# Вспомогательная функция для сохранения
func _write_save_file(save_data: Dictionary) -> bool:
	Repository.instance.log_message("Thread: Writing save data to file...")
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data, true)
		file.close()
		Repository.instance.log_message("Thread: Save data written successfully")
		return true
	else:
		Repository.instance.log_message("Thread: Failed to open file for writing")
	return false

# Вспомогательная функция для загрузки
func _read_save_file() -> Variant:
	Repository.instance.log_message("Thread: Reading save file...")
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var(true)
		file.close()
		Repository.instance.log_message("Thread: Save data read successfully")
		return data
	else:
		Repository.instance.log_message("Thread: Failed to open file for reading")
	return null

# Очистка сохранения
func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		Repository.instance.clear_category("")
		Repository.instance.log_message("Save file cleared")
