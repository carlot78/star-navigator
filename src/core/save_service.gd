extends Node
## Writes and reads save games as versioned JSON under user://saves/.
## The format is GameState.to_dict(); older versions are upgraded step by
## step in _migrate() so a save from any released build keeps loading.

const DIR := "user://saves"
const AUTOSAVE := "autosave"


func slot_path(slot: String) -> String:
	return "%s/%s.json" % [DIR, slot]


func has_slot(slot: String = AUTOSAVE) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func save_game(slot: String = AUTOSAVE) -> Error:
	var err := DirAccess.make_dir_recursive_absolute(DIR)
	if err != OK:
		push_error("SaveService: cannot create %s (%d)" % [DIR, err])
		return err
	var path := slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		err = FileAccess.get_open_error()
		push_error("SaveService: cannot open %s (%d)" % [path, err])
		return err
	file.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	file.close()
	EventBus.game_saved.emit(slot)
	return OK


func load_game(slot: String = AUTOSAVE) -> Error:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("SaveService: %s is not a JSON object" % path)
		return ERR_INVALID_DATA
	GameState.from_dict(_migrate(data))
	EventBus.game_loaded.emit(slot)
	return OK


func _migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("version", 0))
	while version < GameState.SAVE_VERSION:
		match version:
			0:
				# Pre-versioned saves: nothing to change yet.
				pass
			_:
				push_warning("SaveService: no migration from version %d" % version)
		version += 1
	data["version"] = version
	return data
