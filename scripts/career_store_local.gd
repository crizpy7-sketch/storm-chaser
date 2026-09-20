extends "res://scripts/career_store.gd"
## The career kept in the same ConfigFile as the rest of the settings.
##
## It owns the [career] section alone and rewrites it *after* main.gd's
## save_settings() has replaced the file. That order is deliberate and is the
## whole reason this is a separate write: save_settings() builds a FRESH
## ConfigFile, so any key it does not set is gone from the file -- the easiest
## save-wipe bug in the project. Loading the file back before setting the
## section is what preserves everything save_settings() just wrote.

var path := ""

func _init(config_path: String) -> void:
	path = config_path

func rebind(config_path: String) -> void:
	path = config_path

func read() -> Dictionary:
	var config := ConfigFile.new()
	if config.load(path) != OK: return {}
	if not config.has_section(SECTION): return {}
	var stored := {}
	for key in KEYS: stored[key] = config.get_value(SECTION, key, null)
	return sanitize(stored)

func write(career: Dictionary) -> void:
	var config := ConfigFile.new()
	# A missing file is not an error here: the career is simply the first
	# section written to a file that does not exist yet.
	config.load(path)
	var clean := sanitize(career)
	for key in KEYS: config.set_value(SECTION, key, clean[key])
	config.save(path)
