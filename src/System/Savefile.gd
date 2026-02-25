extends Node


var save_slot: int = 0
var max_slots: int = 10
const save_version: String = "2.0.0+5"

var game_data = {}
var newgame_plus: int = 0

signal loaded
signal saved


func get_config_path() -> String:
	return "user://config"

func save_config_data() -> void :

	var config_data = {
		"configs": Configurations.variables,
		"keys": InputManager.modified_keys,
		"achievements": Achievements.export_unlocked_list()
	}
	var bson = BSON.to_bson(config_data)
	var file = File.new()
	file.open(get_config_path(), File.WRITE)
	file.store_buffer(bson)
	file.close()

func load_config_data() -> void :
	var file = File.new()
	if not file.file_exists(get_config_path()):
		return
	file.open(get_config_path(), File.READ)
	file.seek_end(-1)
	var final = file.get_8()
	file.seek(0)
	if final == 0:
		var binary_json = file.get_buffer(file.get_len())
		file.close()
		var config_data = BSON.from_bson(binary_json)
		if config_data.has("configs"):
			Configurations.load_variables(config_data["configs"])
		if config_data.has("keys"):
			InputManager.load_modified_keys(config_data["keys"])
		if config_data.has("achievements"):
			Achievements.load_achievements(config_data["achievements"])
	else:
		file.close()
		push_warning("Savefile: Legacy encrypted config data not supported, skipping.")


# Legacy: returns old single-file path, used for migration detection
func get_save_slot(slot: int = 0) -> String:
	return "user://saves/save_slot_%d" % slot

func get_save_slot_path(slot: int, sub: String) -> String:
	return "user://saves/save_slot_%d_%s" % [slot, sub]

func get_marker_path(slot: int) -> String:
	return "user://saves/save_slot_%d_safe" % slot

func get_safe_sub_slot(slot: int) -> String:
	var file = File.new()
	var marker_path = get_marker_path(slot)
	if not file.file_exists(marker_path):
		return "a"
	var err = file.open(marker_path, File.READ)
	if err != OK:
		return "a"
	var content = file.get_as_text().strip_edges()
	file.close()
	if content == "b":
		return "b"
	return "a"

func get_other_sub_slot(sub: String) -> String:
	return "b" if sub == "a" else "a"

func write_marker(slot: int, sub: String) -> void :
	ensure_save_folder_exists()
	var file = File.new()
	var err = file.open(get_marker_path(slot), File.WRITE)
	if err != OK:
		push_error("Savefile: Failed to write marker for slot %d" % slot)
		return
	file.store_string(sub)
	file.close()

func migrate_old_save(slot: int) -> void :
	var file = File.new()
	var old_path = get_save_slot(slot)
	var new_path_a = get_save_slot_path(slot, "a")
	if not file.file_exists(old_path) or file.file_exists(new_path_a):
		return
	var dir = Directory.new()
	var err = dir.rename(old_path, new_path_a)
	if err == OK:
		write_marker(slot, "a")
		print("Savefile: Migrated slot %d to A/B format." % slot)
	else:
		if file.open(old_path, File.READ) == OK:
			var data = file.get_buffer(file.get_len())
			file.close()
			if file.open(new_path_a, File.WRITE) == OK:
				file.store_buffer(data)
				file.close()
				write_marker(slot, "a")
				print("Savefile: Migrated slot %d to A/B format (copy)." % slot)

func _try_read_bson(path: String) -> Dictionary:
	var file = File.new()
	if not file.file_exists(path):
		return {}
	var err = file.open(path, File.READ)
	if err != OK:
		return {}
	var length = file.get_len()
	if length == 0:
		file.close()
		return {}
	file.seek_end(-1)
	var final_byte = file.get_8()
	file.seek(0)
	if final_byte != 0:
		file.close()
		push_warning("Savefile: Legacy or corrupt data at '%s', skipping." % path)
		return {}
	var bson_data = file.get_buffer(length)
	file.close()
	var dict = BSON.from_bson(bson_data)
	if typeof(dict) != TYPE_DICTIONARY or not dict.has("version"):
		push_warning("Savefile: Invalid save data at '%s'." % path)
		return {}
	return dict

func _delete_if_exists(path: String) -> void :
	var dir = Directory.new()
	if dir.file_exists(path):
		dir.remove(path)

func ensure_save_folder_exists() -> void :
	var dir = Directory.new()
	if not dir.dir_exists("user://saves"):
		dir.make_dir("user://saves")

func set_all_data() -> void :
	game_data["version"] = save_version
	game_data["collectibles"] = GameManager.collectibles
	game_data["equip_exceptions"] = GameManager.equip_exceptions
	game_data["variables"] = GlobalVariables.variables
	game_data["meta"] = {
		"last_saved": OS.get_unix_time(),
		"difficulty": CharacterManager.game_mode,
		"game_mode_set": CharacterManager.game_mode_set,
		"newgame_plus": newgame_plus
	}

func save(slot: int = 0) -> void :

	set_all_data()
	write_to_file(slot)
	call_deferred("save_config_data")
	emit_signal("saved")

func write_to_file(slot: int = 0) -> void :
	ensure_save_folder_exists()
	var safe_sub = get_safe_sub_slot(slot)
	var target_sub = get_other_sub_slot(safe_sub)
	var target_path = get_save_slot_path(slot, target_sub)
	var bson = BSON.to_bson(game_data)
	var file = File.new()
	var err = file.open(target_path, File.WRITE)
	if err != OK:
		push_error("Savefile: Failed to write save slot %d_%s (error %d)" % [slot, target_sub, err])
		return
	file.store_buffer(bson)
	file.close()
	write_marker(slot, target_sub)

func load_save(slot: int = 0) -> void :

	CharacterManager.game_mode_set = false
	CharacterManager.game_mode = 0
	newgame_plus = 0
	GameManager.collectibles = []
	GameManager.equip_exceptions = []
	GlobalVariables.variables = {}
	load_from_file(slot)
	apply_data(slot)

	CharacterManager._load()

	emit_signal("loaded")

func load_from_file(slot: int = 0) -> void :
	migrate_old_save(slot)
	var safe_sub = get_safe_sub_slot(slot)
	var safe_path = get_save_slot_path(slot, safe_sub)
	var dict = _try_read_bson(safe_path)
	if dict.empty():
		var other_sub = get_other_sub_slot(safe_sub)
		var other_path = get_save_slot_path(slot, other_sub)
		dict = _try_read_bson(other_path)
		if dict.empty():
			clear_save(slot)
			return
		else:
			push_warning("Savefile: Slot %d primary '%s' corrupt, recovered from '%s'." % [slot, safe_sub, other_sub])
			write_marker(slot, other_sub)
	game_data = dict

func load_latest_save() -> void :
	var latest_time: = - 1
	var latest_slot: = - 1
	for i in range(max_slots):
		var data = load_slot_metadata(i)
		var meta = {}
		if data.has("meta"):
			meta = data["meta"]
		if meta.has("last_saved"):
			var saved_time = int(meta["last_saved"])
			if saved_time > latest_time:
				latest_time = saved_time
				latest_slot = i
	if latest_slot != - 1:

		save_slot = latest_slot
		load_save(latest_slot)
	else:

		save_slot = 0
		load_save(0)

func load_slot_metadata(slot: int) -> Dictionary:
	migrate_old_save(slot)
	var safe_sub = get_safe_sub_slot(slot)
	var safe_path = get_save_slot_path(slot, safe_sub)
	var dict = _try_read_bson(safe_path)
	if dict.empty():
		var other_sub = get_other_sub_slot(safe_sub)
		var other_path = get_save_slot_path(slot, other_sub)
		dict = _try_read_bson(other_path)
		if dict.empty():
			return {}
	var result = {}
	if dict.has("meta"):
		result["meta"] = dict["meta"]
	if dict.has("collectibles"):
		result["collectibles"] = dict["collectibles"]
	if dict.has("variables"):
		result["variables"] = dict["variables"]
	return result

func apply_data(_slot: int = 0) -> void :
	if game_data.has("version") and game_data["version"] == save_version:
		if game_data.has("meta"):
			if game_data["meta"].has("difficulty"):
				CharacterManager.game_mode = int(game_data["meta"].get("difficulty", 0))
			if game_data["meta"].has("game_mode_set"):
				CharacterManager.game_mode_set = bool(game_data["meta"].get("game_mode_set", false))
			if game_data["meta"].has("newgame_plus"):
				newgame_plus = int(game_data["meta"].get("newgame_plus", 0))

		GameManager.collectibles = game_data["collectibles"]
		if game_data.has("equip_exceptions"):
			GameManager.equip_exceptions = game_data["equip_exceptions"]
		GlobalVariables.load_variables(game_data["variables"])

		if game_data["variables"].has("igt"):
			IGT.set_time(GlobalVariables.get("igt"))
		call_deferred("emit_signal", "loaded")

func clear_save(slot: int = 0) -> void :
	game_data = {
		"version": save_version,
		"meta": {},
		"collectibles": [],
		"equip_exceptions": [],
		"variables": {}
	}
	CharacterManager.game_mode_set = false
	CharacterManager.game_mode = 0
	newgame_plus = 0
	IGT.reset()
	GameManager.collectibles = []
	GameManager.equip_exceptions = []
	GlobalVariables.variables = {}
	_delete_if_exists(get_save_slot(slot))
	_delete_if_exists(get_save_slot_path(slot, "a"))
	_delete_if_exists(get_save_slot_path(slot, "b"))
	_delete_if_exists(get_marker_path(slot))
	write_to_file(slot)

func clear_global_variables() -> void :
	game_data["variables"] = {}
	GlobalVariables.load_variables(game_data["variables"])

func clear_game_data(slot: int = 0) -> void :
	set_all_data()
	game_data["collectibles"] = []
	game_data["equip_exceptions"] = []
	game_data["variables"] = {}
	apply_data(slot)
	write_to_file(slot)

func clear_keybinds(slot: int = 0) -> void :
	set_all_data()
	game_data["keys"] = {}
	InputMap.load_from_globals()
	apply_data(slot)
	write_to_file(slot)

func clear_options(slot: int = 0) -> void :
	set_all_data()
	game_data["configs"] = {}
	apply_data(slot)
	write_to_file(slot)
