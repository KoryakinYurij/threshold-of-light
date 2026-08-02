class_name SettingsStore extends RefCounted
## Настройки — ConfigFile (INI), отдельно от сейвов (ADR-001, план T-02).
## Не автолоад: состояния не держит, только читает и пишет файл.
##
## Первый потребитель — панель ползунков T-03: её состояние обязано
## переживать перезапуск.

const PATH: String = "user://settings.cfg"


static func load_config() -> ConfigFile:
	var cfg := ConfigFile.new()
	var err := cfg.load(PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("SettingsStore: %s не прочитан (код %d), беру пустые настройки" % [PATH, err])
	return cfg


static func save_config(cfg: ConfigFile) -> bool:
	var err := cfg.save(PATH)
	if err != OK:
		push_error("SettingsStore: не записать %s (код %d)" % [PATH, err])
		return false
	return true


static func get_value(section: String, key: String, default: Variant) -> Variant:
	return load_config().get_value(section, key, default)


static func set_value(section: String, key: String, value: Variant) -> bool:
	var cfg := load_config()
	cfg.set_value(section, key, value)
	return save_config(cfg)
