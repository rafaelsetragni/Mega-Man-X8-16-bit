extends X8TextureButton

export var slot_index: int = 0

onready var slot_number: Label = $number
onready var difficulty_label = $difficulty
onready var completion_label: Label = $completion_display
onready var newgame_plus_label: Label = $newgameplus
onready var last_saved_label: Label = $date_display
onready var igt_label: Label = $igt_display
onready var status_label: Label = $status
onready var boss_icons: HBoxContainer = $boss_icons
onready var item_icons: HBoxContainer = $item_icons

var _is_occupied: bool = false
var _confirm_pending: bool = false
var _igt_str: String = ""

const COLLECTIBLES := [
	"finished_intro",
	"panda_weapon", "sunflower_weapon", "trilobyte_weapon", "manowar_weapon",
	"yeti_weapon", "rooster_weapon", "antonion_weapon", "mantis_weapon",
	"life_up_panda", "life_up_sunflower", "life_up_trilobyte", "life_up_manowar",
	"life_up_yeti", "life_up_rooster", "life_up_antonion", "life_up_mantis",
	"subtank_trilobyte", "subtank_sunflower", "subtank_yeti", "subtank_rooster",
	"hermes_head", "hermes_arms", "hermes_body", "hermes_legs",
	"icarus_head", "icarus_arms", "icarus_body", "icarus_legs",
	"ultima_head", "ultima_arms", "ultima_body", "ultima_legs",
	"black_zero_armor", "white_axl_armor",
	"defeated_antonion_vile", "defeated_panda_vile",
	"vile3_defeated", "vile_palace_defeated",
	"copy_sigma_defeated", "seraph_lumine_defeated",
	"b_fan_zero", "d_glaive_zero", "k_knuckle_zero", "t_breaker_zero",
]


func _ready() -> void:
	pass  # menu is set via connect_lock_signals() by SaveScreen


func setup_save(data: Dictionary, idx: int) -> void:
	slot_index = idx
	slot_number.text = str(idx + 1)
	status_label.text = ""
	boss_icons.visible = false

	if data.empty():
		_is_occupied = false
		_igt_str = ""
		difficulty_label.text = ""
		difficulty_label.idle_color = Color.dimgray
		difficulty_label.focus_color = Color.white
		completion_label.text = ""
		last_saved_label.text = ""
		igt_label.text = ""
		igt_label.visible = false
		newgame_plus_label.text = ""
		status_label.modulate = Color.white
		status_label.text = tr("SAVE_EMPTY")
		_reset_item_icons()
	else:
		_is_occupied = true
		var meta: Dictionary = data.get("meta", {})
		var slot_collectibles: Array = data.get("collectibles", [])
		var variables: Dictionary = {}
		if data.has("variables") and typeof(data["variables"]) == TYPE_DICTIONARY:
			variables = data["variables"]

		# Difficulty + completion
		var total_collectibles := COLLECTIBLES.size()
		if meta.has("difficulty"):
			var diff_name := ""
			match int(meta["difficulty"]):
				-1:
					diff_name = tr("GAME_START_ROOKIE")
					difficulty_label.idle_color = Color("#329632")
					difficulty_label.focus_color = Color("#8cff8c")
					total_collectibles -= 6
				0:
					diff_name = tr("GAME_START_NORMAL")
					difficulty_label.idle_color = Color("#68caff")
					difficulty_label.focus_color = Color("#fbffaf")
				1:
					diff_name = tr("GAME_START_HARD")
					difficulty_label.idle_color = Color("#960000")
					difficulty_label.focus_color = Color("#ff4b4b")
					total_collectibles -= 2
				2:
					diff_name = tr("GAME_START_INSANITY")
					difficulty_label.idle_color = Color("#771313")
					difficulty_label.focus_color = Color("#ff7200")
					total_collectibles -= 4
				3:
					diff_name = tr("GAME_START_NINJA")
					difficulty_label.idle_color = Color("#832b7f")
					difficulty_label.focus_color = Color("#e090f2")
					total_collectibles -= 12
			difficulty_label.text = tr("SAVE_DIFFICULTY") + ": " + diff_name
			completion_label.text = "Completion: %3.0f%%" % _calc_completion(slot_collectibles, variables, total_collectibles)
		else:
			difficulty_label.text = ""
			completion_label.text = ""

		# IGT + date
		_igt_str = _format_igt(variables["igt"]) if variables.has("igt") else ""
		igt_label.text = _igt_str
		igt_label.visible = _igt_str != ""
		last_saved_label.text = _unix_to_string(meta["last_saved"]) if meta.has("last_saved") else ""

		# New game+
		var ng := int(meta.get("newgame_plus", 0))
		if ng > 1:
			newgame_plus_label.text = tr("NEWGAME_OPTION") + str(ng)
		elif ng == 1:
			newgame_plus_label.text = tr("NEWGAME_OPTION")
		else:
			newgame_plus_label.text = ""

		# Boss and item icons
		if data.has("collectibles"):
			boss_icons.visible = true
			_populate_boss_icons(slot_collectibles, variables)
			_populate_item_icons(slot_collectibles)
		else:
			_reset_item_icons()

	_on_focus_exited()


func _on_focus_entered() -> void:
	._on_focus_entered()
	var scroll := get_parent().get_parent()
	if scroll is ScrollContainer:
		scroll.ensure_control_visible(self)


func on_press() -> void:
	if not _is_occupied:
		strong_flash()
		menu.on_slot_save(slot_index)
	elif _confirm_pending:
		_confirm_pending = false
		strong_flash()
		menu.on_slot_save(slot_index)
	else:
		_confirm_pending = true
		strong_flash()
		if menu:
			menu.play_equip_sound()
		igt_label.text = ""
		status_label.modulate = Color.white
		status_label.text = tr("SAVE_OVERWRITE_CONFIRM")


func _on_focus_exited() -> void:
	._on_focus_exited()
	_confirm_pending = false
	if _is_occupied:
		status_label.text = ""
		igt_label.text = _igt_str
	else:
		status_label.modulate = Color.white
		status_label.text = tr("SAVE_EMPTY")


func _reset_item_icons() -> void:
	for child in item_icons.get_children():
		child.visible = false


func _populate_boss_icons(slot_collectibles: Array, variables: Dictionary) -> void:
	for boss in ["panda", "yeti", "manowar", "rooster", "trilobyte", "mantis", "antonion", "sunflower"]:
		var defeated: bool = (boss + "_weapon") in slot_collectibles
		boss_icons.get_node(boss).visible = defeated
		if defeated:
			boss_icons.get_node(boss + "/animatedSprite").frame = 1
	for hidden in ["zero", "red", "serenade"]:
		boss_icons.get_node(hidden).visible = false
	var secret_checks := {
		"zero_seen": "zero", "zero_defeated": "zero",
		"red_seen": "red", "red_defeated": "red",
		"serenade_seen": "serenade", "serenade_defeated": "serenade",
	}
	for key in secret_checks:
		if key in slot_collectibles:
			boss_icons.get_node(secret_checks[key]).visible = true
			if "defeated" in key:
				boss_icons.get_node(secret_checks[key] + "/animatedSprite").frame = 1
	var end_boss_map := {
		"vile3_defeated": "vile",
		"copy_sigma_defeated": "sigma",
		"seraph_lumine_defeated": "lumine",
	}
	for key in end_boss_map:
		var node_name: String = end_boss_map[key]
		var has_key: bool = key in variables
		boss_icons.get_node(node_name).visible = has_key
		if has_key:
			boss_icons.get_node(node_name + "/animatedSprite").frame = 1


func _populate_item_icons(slot_collectibles: Array) -> void:
	_reset_item_icons()
	var hermes := 0
	var icarus := 0
	var subtanks := 0
	var hearts := 0
	for item in slot_collectibles:
		if "hermes" in item:
			item_icons.get_node("hermes").visible = true
			hermes += 1
		elif "icarus" in item:
			item_icons.get_node("icarus").visible = true
			icarus += 1
		elif "subtank" in item:
			item_icons.get_node("subtanks").visible = true
			subtanks += 1
		elif "life_up" in item:
			item_icons.get_node("hearts").visible = true
			hearts += 1
		elif item == "ultima_head":
			item_icons.get_node("ultima_head").visible = true
		elif item == "black_zero_armor":
			item_icons.get_node("black_zero_armor").visible = true
		elif item == "white_axl_armor":
			item_icons.get_node("white_axl_armor").visible = true
	item_icons.get_node("hermes/Sprite/number").text = str(hermes)
	item_icons.get_node("icarus/Sprite/number").text = str(icarus)
	item_icons.get_node("subtanks/Sprite/number").text = str(subtanks)
	item_icons.get_node("hearts/Sprite/number").text = str(hearts)


func _calc_completion(slot_collectibles: Array, variables: Dictionary, total: int) -> float:
	if total <= 0:
		return 0.0
	var collected := 0
	for item in slot_collectibles:
		if item in COLLECTIBLES:
			collected += 1
	for key in variables.keys():
		if key in COLLECTIBLES:
			var val = variables[key]
			match typeof(val):
				TYPE_BOOL:
					if val:
						collected += 1
				TYPE_STRING:
					if "defeated" in val:
						collected += 1
	return float(collected) / float(total) * 100.0


func _format_igt(accumulated_time: float) -> String:
	# warning-ignore:integer_division
	var h := int(accumulated_time) / 3600
	# warning-ignore:integer_division
	var m := (int(accumulated_time) % 3600) / 60
	var s := int(accumulated_time) % 60
	return "%02d:%02d:%02d" % [h, m, s]


func _unix_to_string(unix_time: int) -> String:
	var date = OS.get_datetime_from_unix_time(unix_time)
	return "%04d.%02d.%02d %02d:%02d" % [date.year, date.month, date.day, date.hour, date.minute]
