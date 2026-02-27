extends CanvasLayer

const SAVE_DIR := "user://debug_saves/"
const SAVE_PREFIX := "debug_slot_"
const MAX_SLOTS := 10

var slots: Array = []
var selected: int = 0
var is_open: bool = false
var confirm_delete: bool = false

onready var bg: ColorRect = $BG
onready var slot_list: VBoxContainer = $Panel/SlotList
onready var title_label: Label = $Panel/Title
onready var actions_label: Label = $Panel/Actions
onready var menu_font: Font = preload("res://src/Fonts/menuFont.tres")


func _ready() -> void:
	GameManager.debug_save_menu = self
	visible = false
	_ensure_dir()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open:
		return
	is_open = true
	confirm_delete = false
	selected = 0
	slots = _load_all_slot_metadata()
	_rebuild_ui()
	visible = true
	GameManager.pause("DebugSaveState")


func close() -> void:
	if not is_open:
		return
	is_open = false
	confirm_delete = false
	visible = false
	GameManager.unpause("DebugSaveState")


func _input(event: InputEvent) -> void:
	if not is_open:
		return

	if not event is InputEventKey or not event.pressed or event.echo:
		return

	get_tree().set_input_as_handled()

	if confirm_delete:
		if event.scancode == KEY_D or event.scancode == KEY_ENTER:
			_do_delete(selected)
			confirm_delete = false
			_rebuild_ui()
		else:
			confirm_delete = false
			_rebuild_ui()
		return

	match event.scancode:
		KEY_UP:
			selected = wrapi(selected - 1, 0, MAX_SLOTS)
			_update_selection()
		KEY_DOWN:
			selected = wrapi(selected + 1, 0, MAX_SLOTS)
			_update_selection()
		KEY_S:
			if not event.command and not event.meta:
				_save_to_slot(selected)
		KEY_L, KEY_ENTER:
			_load_from_slot(selected)
		KEY_D, KEY_DELETE:
			if slots[selected] != null:
				confirm_delete = true
				_rebuild_ui()
		KEY_ESCAPE:
			close()
		_:
			if event.scancode >= KEY_0 and event.scancode <= KEY_9:
				selected = event.scancode - KEY_0
				_update_selection()

	if event.command or event.meta:
		if event.scancode == KEY_S:
			close()


# ── Persistence ──────────────────────────────────────────────────

func _get_save_path(index: int) -> String:
	return SAVE_DIR + SAVE_PREFIX + str(index) + ".save"


func _ensure_dir() -> void:
	var dir := Directory.new()
	if not dir.dir_exists(SAVE_DIR):
		dir.make_dir_recursive(SAVE_DIR)


func _save_to_slot(index: int) -> void:
	var player = GameManager.player
	if not player or not is_instance_valid(player):
		return

	var data := {
		"timestamp": OS.get_unix_time(),
		"level": GameManager.current_level,
		"character": CharacterManager.player_character,
		"position_x": player.global_position.x,
		"position_y": player.global_position.y,
		"current_health": player.current_health,
		"max_health": player.max_health,
		"facing_right": player.facing_right,
		"collectibles": GameManager.collectibles.duplicate(),
		"equip_exceptions": GameManager.equip_exceptions.duplicate(),
		"global_variables": GlobalVariables.variables.duplicate(true),
		"state": GameManager.state,
	}

	if GameManager.checkpoint:
		data["checkpoint_id"] = GameManager.checkpoint.id
		data["checkpoint_pos_x"] = GameManager.checkpoint.respawn_position.x
		data["checkpoint_pos_y"] = GameManager.checkpoint.respawn_position.y
		data["checkpoint_direction"] = GameManager.checkpoint.character_direction
		data["checkpoint_last_door"] = GameManager.checkpoint.last_door

	var shot_node = player.get_node_or_null("Shot")
	if shot_node:
		var ammo_data := {}
		for child in shot_node.get_children():
			if child is Weapon:
				ammo_data[child.name] = child.current_ammo
		data["weapon_ammo"] = ammo_data

	var file := File.new()
	file.open(_get_save_path(index), File.WRITE)
	file.store_string(to_json(data))
	file.close()

	slots[index] = data
	_rebuild_ui()
	print_debug("DEBUG SAVE STATE: Saved to slot " + str(index))


func _load_from_slot(index: int) -> void:
	if slots[index] == null:
		return

	var data: Dictionary = slots[index]

	GlobalVariables.variables = data["global_variables"].duplicate(true)
	GameManager.collectibles = data["collectibles"].duplicate()
	GameManager.equip_exceptions = data["equip_exceptions"].duplicate()

	var saved_cp = CheckpointSettings.new()
	saved_cp.respawn_position = Vector2(data["position_x"], data["position_y"])
	saved_cp.character_direction = 1 if data["facing_right"] else -1
	saved_cp.id = 999
	if data.has("checkpoint_last_door"):
		saved_cp.last_door = data["checkpoint_last_door"]
	GameManager.checkpoint = saved_cp

	GameManager._debug_save_data = {
		"max_health": data["max_health"],
		"current_health": data["current_health"],
		"weapon_ammo": data.get("weapon_ammo", {}),
		"state": data.get("state", "Normal"),
		"position": Vector2(data["position_x"], data["position_y"]),
		"facing_right": data["facing_right"],
	}
	GameManager._debug_restore_pending = true

	close()
	print_debug("DEBUG SAVE STATE: Loading slot " + str(index))
	GameManager.restart_level()


func _do_delete(index: int) -> void:
	var dir := Directory.new()
	var path := _get_save_path(index)
	if dir.file_exists(path):
		dir.remove(path)
	slots[index] = null
	print_debug("DEBUG SAVE STATE: Deleted slot " + str(index))


func _load_all_slot_metadata() -> Array:
	var result := []
	var file := File.new()
	for i in range(MAX_SLOTS):
		var path := _get_save_path(i)
		if file.file_exists(path):
			file.open(path, File.READ)
			var text := file.get_as_text()
			file.close()
			var parsed = parse_json(text)
			if parsed is Dictionary:
				result.append(parsed)
			else:
				result.append(null)
		else:
			result.append(null)
	return result


# ── UI ───────────────────────────────────────────────────────────

func _rebuild_ui() -> void:
	for i in range(MAX_SLOTS):
		var slot_item: HBoxContainer = slot_list.get_child(i)
		var num_label: Label = slot_item.get_child(0)
		var info_label: Label = slot_item.get_child(1)
		var time_label: Label = slot_item.get_child(2)

		num_label.text = str(i)

		if slots[i] != null:
			var data: Dictionary = slots[i]
			var level_name: String = data.get("level", "???")
			var character_name: String = data.get("character", "?")
			var hp: String = str(int(data.get("current_health", 0))) + "/" + str(int(data.get("max_health", 0)))
			info_label.text = level_name + " - " + character_name + " - " + hp
			info_label.modulate = Color.white

			var ts: int = int(data.get("timestamp", 0))
			var dt := OS.get_datetime_from_unix_time(ts)
			time_label.text = "%02d/%02d %02d:%02d" % [dt["month"], dt["day"], dt["hour"], dt["minute"]]
			time_label.modulate = Color.white
		else:
			info_label.text = "(empty)"
			info_label.modulate = Color(0.5, 0.5, 0.5)
			time_label.text = ""
			time_label.modulate = Color(0.5, 0.5, 0.5)

	_update_selection()

	if confirm_delete:
		actions_label.text = "Delete slot " + str(selected) + "? [D] Confirm  [Any] Cancel"
		actions_label.modulate = Color(1.0, 0.4, 0.4)
	else:
		actions_label.text = "[S]ave  [L]oad  [D]elete  [Esc]Close  [0-9]Slot"
		actions_label.modulate = Color(0.7, 0.7, 0.7)


func _update_selection() -> void:
	for i in range(MAX_SLOTS):
		var slot_item: HBoxContainer = slot_list.get_child(i)
		if i == selected:
			slot_item.get_child(0).modulate = Color(1.0, 1.0, 0.3)
			if slots[i] != null:
				slot_item.get_child(1).modulate = Color(1.0, 1.0, 0.3)
				slot_item.get_child(2).modulate = Color(1.0, 1.0, 0.3)
			else:
				slot_item.get_child(1).modulate = Color(0.7, 0.7, 0.3)
		else:
			slot_item.get_child(0).modulate = Color.white
			if slots[i] != null:
				slot_item.get_child(1).modulate = Color.white
				slot_item.get_child(2).modulate = Color.white
			else:
				slot_item.get_child(1).modulate = Color(0.5, 0.5, 0.5)
				slot_item.get_child(2).modulate = Color(0.5, 0.5, 0.5)
