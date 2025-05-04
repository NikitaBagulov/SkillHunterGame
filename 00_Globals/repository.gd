extends Node

# Синглтон для глобального доступа
static var instance: Repository = null

# Основной словарь для хранения данных с поддержкой категорий
var data: Dictionary = {
	"player": {},
	"inventory": {},
	"settings": {},
	"world": {},
	"chunks": {},  # Новая категория для чанков
	"objects": {},  # Новая категория для объектов
	"portals": {}   # Новая категория для порталов
}

# Текущая версия формата данных
const DATA_VERSION: String = "1.0.0"

# Лог изменений для отладки
var change_log: Array[String] = []

# Сигналы для уведомления об изменениях
signal data_changed(category: String, key: String, value: Variant)
signal data_registered(category: String, key: String)
signal data_cleared(category: String)

func _ready() -> void:
	# Устанавливаем синглтон
	if instance == null:
		instance = self
	else:
		queue_free()
		return
	
	name = "Repository"
	log_message("Repository initialized")

# Регистрация объекта или данных в категории
func register(category: String, key: String, value: Variant, overwrite: bool = false) -> bool:
	if not data.has(category):
		data[category] = {}
	
	if data[category].has(key) and not overwrite:
		push_warning("Key '%s' in category '%s' already exists. Use overwrite=true." % [key, category])
		return false
	
	data[category][key] = value
	data_registered.emit(category, key)
	data_changed.emit(category, key, value)
	log_message("Registered '%s/%s': %s" % [category, key, value])
	return true

# Получение данных по категории и ключу
func get_data(category: String, key: String, default: Variant = null) -> Variant:
	if data.has(category):
		return data[category].get(key, default)
	push_warning("Category '%s' not found." % category)
	return default

# Обновление данных
func update_data(category: String, key: String, value: Variant) -> bool:
	if not data.has(category) or not data[category].has(key):
		push_warning("Key '%s' in category '%s' not found. Register it first." % [key, category])
		return false
	data[category][key] = value
	data_changed.emit(category, key, value)
	log_message("Updated '%s/%s': %s" % [category, key, value])
	return true

# Удаление данных
func remove_data(category: String, key: String) -> bool:
	if data.has(category) and data[category].erase(key):
		data_changed.emit(category, key, null)
		log_message("Removed '%s/%s'" % [category, key])
		return true
	push_warning("Key '%s' in category '%s' not found." % [key, category])
	return false

# Очистка категории или всех данных
func clear_category(category: String = "") -> void:
	if category.is_empty():
		data.clear()
		data = {"player": {}, "inventory": {}, "settings": {}, "world": {}}
		data_cleared.emit("")
		log_message("Cleared all Repository data")
	else:
		if data.has(category):
			data[category].clear()
			data_cleared.emit(category)
			log_message("Cleared category '%s'" % category)

# Проверка наличия ключа
func has_data(category: String, key: String) -> bool:
	return data.has(category) and data[category].has(key)

# Получение всех ключей в категории
func get_category_keys(category: String) -> Array:
	if data.has(category):
		return data[category].keys()
	return []

# Получение всех категорий
func get_all_categories() -> Array:
	return data.keys()

# Сериализация данных для сохранения
func serialize() -> Dictionary:
	var serialized_data: Dictionary = {
		"version": DATA_VERSION,
		"categories": {}
	}
	for category in data.keys():
		serialized_data.categories[category] = {}
		for key in data[category].keys():
			var value = data[category][key]
			serialized_data.categories[category][key] = _serialize_value(value)
	return serialized_data

# Десериализация данных при загрузке
func deserialize(serialized_data: Dictionary) -> bool:
	if not validate_serialized_data(serialized_data):
		log_message("Invalid serialized data format")
		return false
	
	var version = serialized_data.get("version", "0.0.0")
	data.clear()
	data = {"player": {}, "inventory": {}, "settings": {}, "quests": {}}
	
	var categories = serialized_data.get("categories", {})
	for category in categories.keys():
		if not data.has(category):
			data[category] = {}
		for key in categories[category].keys():
			var value = _deserialize_value(categories[category][key], version)
			data[category][key] = value
			data_registered.emit(category, key)
			data_changed.emit(category, key, value)
			log_message("Deserialized '%s/%s': %s" % [category, key, value])
	return true

# Вспомогательные методы
func _serialize_value(value: Variant) -> Variant:
	if value is Object and value.has_method("serialize"):
		var serialized = value.serialize()
		if serialized is Dictionary:
			# Проверяем, есть ли скрипт и class_name
			var class_name_text = value.get_class()
			if value.get_script() and value.get_script().has_source_code():
				var script = value.get_script()
				# Извлекаем class_name из скрипта
				var source = script.get_source_code()
				var class_name_match = RegEx.create_from_string("class_name\\s+(\\w+)").search(source)
				if class_name_match:
					class_name_text = class_name_match.get_string(1)
			serialized["serialized_type"] = class_name_text
			log_message("Serializing object with class_name: %s" % class_name_text)
		return serialized
	elif value is Array or value is Dictionary:
		return _deep_serialize(value)
	return value

func _deserialize_value(value: Variant, version: String) -> Variant:
	if value is String and ResourceLoader.exists(value):
		return load(value)
	elif value is Dictionary and value.has("serialized_type"):
		return _deserialize_custom_object(value, version)
	elif value is Array or value is Dictionary:
		return _deep_deserialize(value, version)
	return value

# Десериализация пользовательских объектов
func _deserialize_custom_object(data: Dictionary, version: String) -> Variant:
	var type_name = data.get("serialized_type", "")
	if type_name.is_empty():
		log_message("Missing serialized_type in data: %s" % data)
		return null
	
	# Удаляем метаданные перед десериализацией
	var serialized_data = data.duplicate()
	serialized_data.erase("serialized_type")
	
	# Создаем экземпляр объекта
	var instance = null
	match type_name:
		"Stats":
			instance = Stats.new()
		"InventoryData":
			instance = InventoryData.new()
		"QuestResource":
			instance = QuestResource.new()
		# Добавьте другие типы по необходимости
		_:
			log_message("Unsupported serialized_type: %s" % type_name)
	
	if instance and instance.has_method("deserialize"):
		instance.deserialize(serialized_data)
		return instance
	else:
		log_message("No deserialize method for type: %s" % type_name)
		return null

# Глубокая сериализация сложных типов
func _deep_serialize(value: Variant) -> Variant:
	if value is Array:
		var result = []
		for item in value:
			result.append(_serialize_value(item))
		return result
	elif value is Dictionary:
		var result = {}
		for key in value.keys():
			result[key] = _serialize_value(value[key])
		return result
	return value

# Глубокая десериализация сложных типов
func _deep_deserialize(value: Variant, version: String) -> Variant:
	if value is Array:
		var result = []
		for item in value:
			result.append(_deserialize_value(item, version))
		return result
	elif value is Dictionary:
		var result = {}
		for key in value.keys():
			result[key] = _deserialize_value(value[key], version)
		return result
	return value

# Валидация данных перед загрузкой
func validate_serialized_data(serialized_data: Variant) -> bool:
	if not serialized_data is Dictionary:
		return false
	if not serialized_data.has("version"):
		return false
	if not serialized_data.has("categories"):
		return false
	return true

# Логирование изменений
func log_message(message: String) -> void:
	var timestamp = Time.get_datetime_string_from_system()
	change_log.append("[%s] %s" % [timestamp, message])
	if change_log.size() > 100:  # Ограничение лога
		change_log.pop_front()
	#print(message)

# Получение лога изменений
func get_change_log() -> Array[String]:
	return change_log.duplicate()
