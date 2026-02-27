extends Node

enum State { IDLE, RECORDING, PLAYING }

const DEMO_DIR := "user://demos/"
const BUNDLED_DEMO_DIR := "res://demos/"
const MAX_RECORD_FRAMES := 3600
const FADE_DURATION := 1.0
const TRACKED_ACTIONS := [
	"move_right", "move_left", "move_up", "move_down",
	"jump", "dash", "fire", "alt_fire",
	"weapon_select_left", "weapon_select_right",
	"reset_weapon", "select_special", "pause"
]

var state: int = State.IDLE
var current_frame: int = 0
var events: Array = []
var event_index: int = 0
var demo_metadata: Dictionary = {}
var pressed_actions: Dictionary = {}

var _saved_character: String = ""
var _saved_game_mode: int = 0
var _saved_collectibles: Array = []
var _saved_equip_exceptions: Array = []
var _saved_global_variables: Dictionary = {}
var _saved_rng_seed: int = 0

var idle_timer: float = 0.0
var idle_tracking_enabled: bool = false
const IDLE_DEMO_TIME := 20.0

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _fading: bool = false
var _pending_demo_data: Dictionary = {}
var _playback_waiting: bool = false
var _recording_waiting: bool = false


func _ready() -> void:
	set_pause_mode(2)
	_create_fade_overlay()
	_ensure_dir()
	print("DemoSystem: Initialized. Save dir: " + DEMO_DIR)


func _create_fade_overlay() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	_fade_layer.pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.black
	_fade_rect.modulate = Color(1, 1, 1, 0)
	_fade_rect.anchor_right = 1.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


# ── Idle tracking ────────────────────────────────────────────────

func enable_idle_tracking() -> void:
	idle_timer = 0.0
	idle_tracking_enabled = true
	print("DemoSystem: Idle tracking enabled")


func disable_idle_tracking() -> void:
	idle_tracking_enabled = false
	idle_timer = 0.0


func _process(delta: float) -> void:
	if state == State.IDLE and idle_tracking_enabled and not _fading:
		idle_timer += delta
		if int(idle_timer) % 10 == 0 and int(idle_timer) != int(idle_timer - delta):
			print("DemoSystem: idle = " + str(int(idle_timer)) + "s / " + str(int(IDLE_DEMO_TIME)) + "s")
		if idle_timer >= IDLE_DEMO_TIME:
			_try_attract_demo()


func _physics_process(_delta: float) -> void:
	match state:
		State.RECORDING:
			_record_frame()
		State.PLAYING:
			_playback_frame()


func _input(event: InputEvent) -> void:
	if idle_tracking_enabled and not _fading:
		if event is InputEventKey or event is InputEventJoypadButton:
			if event.pressed:
				idle_timer = 0.0
		elif event is InputEventJoypadMotion:
			if abs(event.axis_value) > 0.5:
				idle_timer = 0.0

	if state == State.PLAYING and not _fading:
		if event is InputEventKey or event is InputEventJoypadButton:
			if event.pressed:
				stop_demo()
				get_tree().set_input_as_handled()
		elif event is InputEventJoypadMotion:
			if abs(event.axis_value) > 0.5:
				stop_demo()
				get_tree().set_input_as_handled()


# ── Fade helpers ─────────────────────────────────────────────────

func _fade_to_black(duration: float, callback: String) -> void:
	_fading = true
	_fade_rect.modulate = Color(1, 1, 1, 0)
	var t := create_tween()
	t.tween_property(_fade_rect, "modulate", Color(1, 1, 1, 1), duration)
	t.tween_callback(self, callback)


func _fade_from_black(duration: float) -> void:
	var t := create_tween()
	t.tween_property(_fade_rect, "modulate", Color(1, 1, 1, 0), duration)
	t.tween_callback(self, "_on_fade_in_done")


func _on_fade_in_done() -> void:
	_fading = false


func _fade_out_music() -> void:
	var scene = get_tree().current_scene
	if not scene:
		return
	var music = scene.get_node_or_null("theme_music")
	if music:
		var t := create_tween()
		t.tween_property(music, "volume_db", -80.0, FADE_DURATION)


# ── Attract mode ─────────────────────────────────────────────────

func _try_attract_demo() -> void:
	idle_timer = 0.0
	var demos := get_available_demos()
	print("DemoSystem: Attract mode triggered. Found " + str(demos.size()) + " demos")
	if demos.size() > 0:
		var pick: String = demos[randi() % demos.size()]
		print("DemoSystem: Playing demo: " + pick)
		play_demo(pick)


# ── Recording ────────────────────────────────────────────────────

func start_recording() -> void:
	disable_idle_tracking()
	events.clear()
	state = State.RECORDING
	current_frame = 0
	_recording_waiting = true
	print("DemoSystem: Recording armed, waiting for level to load...")


func stop_recording() -> void:
	if state != State.RECORDING:
		return
	_save_demo()
	state = State.IDLE
	print("DemoSystem: Recording stopped. " + str(events.size()) + " events in " + str(current_frame) + " frames.")


func _capture_metadata() -> void:
	demo_metadata = {
		"version": 1,
		"level": GameManager.current_level,
		"character": CharacterManager.player_character,
		"game_mode": CharacterManager.game_mode,
		"collectibles": GameManager.collectibles.duplicate(),
		"equip_exceptions": GameManager.equip_exceptions.duplicate(),
		"global_variables": GlobalVariables.variables.duplicate(true),
		"rng_seed": BossRNG.seed_rng,
		"global_seed": randi(),
		"total_frames": 0,
		"events": []
	}


func _record_frame() -> void:
	if _recording_waiting:
		var player = GameManager.player
		if player and is_instance_valid(player) and player.listening_to_inputs:
			_recording_waiting = false
			current_frame = 0
			_capture_metadata()
			print("DemoSystem: Player ready, recording started for " + GameManager.current_level)
		return

	for action in TRACKED_ACTIONS:
		if Input.is_action_just_pressed(action):
			events.append([current_frame, action, true])
		elif Input.is_action_just_released(action):
			events.append([current_frame, action, false])
	current_frame += 1
	if current_frame >= MAX_RECORD_FRAMES:
		stop_recording()


# ── Playback ─────────────────────────────────────────────────────

func play_demo(file_path: String) -> void:
	if _fading:
		return

	var data := _load_demo_file(file_path)
	if data.empty():
		return

	var level_name: String = data.get("level", "")
	if level_name == "":
		push_warning("DemoSystem: Demo has empty level name: " + file_path)
		return

	disable_idle_tracking()
	_pending_demo_data = data

	_fade_out_music()
	_fade_to_black(FADE_DURATION, "_on_play_demo_fade_done")


func _on_play_demo_fade_done() -> void:
	var data: Dictionary = _pending_demo_data
	_pending_demo_data = {}

	demo_metadata = data
	events = data.get("events", [])

	_backup_game_state()
	_restore_game_state(data)

	state = State.PLAYING
	current_frame = 0
	event_index = 0
	pressed_actions.clear()
	_playback_waiting = true

	print("DemoSystem: Loading level: " + data["level"])
	GameManager.start_level(data["level"])
	call_deferred("_fade_from_black", FADE_DURATION)


func _playback_frame() -> void:
	if _playback_waiting:
		var player = GameManager.player
		if player and is_instance_valid(player) and player.listening_to_inputs:
			_playback_waiting = false
			current_frame = 0
			print("DemoSystem: Player ready, starting playback")
		return

	while event_index < events.size():
		var ev = events[event_index]
		if ev[0] != current_frame:
			break
		var action: String = ev[1]
		var pressed: bool = ev[2]
		_inject_action(action, pressed)
		event_index += 1

	current_frame += 1

	var total = demo_metadata.get("total_frames", MAX_RECORD_FRAMES)
	if event_index >= events.size() or current_frame > total:
		stop_demo()


func stop_demo() -> void:
	if state != State.PLAYING:
		return
	_release_all_actions()
	state = State.IDLE
	_restore_backed_up_state()
	print("DemoSystem: Demo stopped.")

	_fade_to_black(0.5, "_on_stop_demo_fade_done")


func _on_stop_demo_fade_done() -> void:
	GameManager.skip_to_menu = true
	GameManager.force_unpause()
	GameManager.go_to_intro()
	call_deferred("_fade_from_black", FADE_DURATION)


func _inject_action(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
	if pressed:
		pressed_actions[action] = true
	else:
		pressed_actions.erase(action)


func _release_all_actions() -> void:
	for action in pressed_actions.keys():
		var event := InputEventAction.new()
		event.action = action
		event.pressed = false
		Input.parse_input_event(event)
	pressed_actions.clear()


# ── State management ─────────────────────────────────────────────

func _backup_game_state() -> void:
	_saved_character = CharacterManager.player_character
	_saved_game_mode = CharacterManager.game_mode
	_saved_collectibles = GameManager.collectibles.duplicate()
	_saved_equip_exceptions = GameManager.equip_exceptions.duplicate()
	_saved_global_variables = GlobalVariables.variables.duplicate(true)
	_saved_rng_seed = BossRNG.seed_rng


func _restore_game_state(data: Dictionary) -> void:
	CharacterManager.player_character = data.get("character", "X")
	CharacterManager.game_mode = int(data.get("game_mode", 0))
	CharacterManager.update_game_mode()
	GameManager.collectibles = data.get("collectibles", []).duplicate()
	GameManager.equip_exceptions = data.get("equip_exceptions", []).duplicate()
	GlobalVariables.variables = data.get("global_variables", {}).duplicate(true)
	BossRNG.set_seed(int(data.get("rng_seed", 0)))
	seed(int(data.get("global_seed", 0)))


func _restore_backed_up_state() -> void:
	CharacterManager.player_character = _saved_character
	CharacterManager.game_mode = _saved_game_mode
	CharacterManager.update_game_mode()
	GameManager.collectibles = _saved_collectibles.duplicate()
	GameManager.equip_exceptions = _saved_equip_exceptions.duplicate()
	GlobalVariables.variables = _saved_global_variables.duplicate(true)
	BossRNG.set_seed(_saved_rng_seed)


# ── File I/O ─────────────────────────────────────────────────────

func _save_demo() -> void:
	_ensure_dir()
	demo_metadata["total_frames"] = current_frame
	demo_metadata["events"] = events

	var ts := OS.get_unix_time()
	var level_name: String = demo_metadata.get("level", "unknown")
	var filename := "demo_" + level_name + "_" + str(ts) + ".json"
	var path := DEMO_DIR + filename

	var file := File.new()
	if file.open(path, File.WRITE) == OK:
		file.store_string(to_json(demo_metadata))
		file.close()
		print("DemoSystem: Saved demo to " + path)
	else:
		push_warning("DemoSystem: Failed to save demo to " + path)


func _load_demo_file(path: String) -> Dictionary:
	var file := File.new()
	if not file.file_exists(path):
		push_warning("DemoSystem: Demo file not found: " + path)
		return {}
	if file.open(path, File.READ) != OK:
		push_warning("DemoSystem: Failed to open demo file: " + path)
		return {}
	var text := file.get_as_text()
	file.close()
	var data = parse_json(text)
	if data is Dictionary:
		return data
	push_warning("DemoSystem: Invalid demo file format: " + path)
	return {}


func _is_valid_demo(data: Dictionary) -> bool:
	var level: String = data.get("level", "")
	return level != "" and data.has("events") and data["events"].size() > 0


func get_available_demos() -> Array:
	var demos := []
	demos.append_array(_list_valid_demos(BUNDLED_DEMO_DIR))
	demos.append_array(_list_valid_demos(DEMO_DIR))
	return demos


func _list_valid_demos(dir_path: String) -> Array:
	var result := []
	var dir := Directory.new()
	if dir.open(dir_path) == OK:
		dir.list_dir_begin(true)
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var path := dir_path + file_name
				var data := _load_demo_file(path)
				if _is_valid_demo(data):
					result.append(path)
				else:
					print("DemoSystem: Skipping invalid demo: " + path)
			file_name = dir.get_next()
		dir.list_dir_end()
	return result


func _ensure_dir() -> void:
	var dir := Directory.new()
	if not dir.dir_exists(DEMO_DIR):
		dir.make_dir_recursive(DEMO_DIR)


# ── Public queries ───────────────────────────────────────────────

func is_demo_playing() -> bool:
	return state == State.PLAYING


func is_recording() -> bool:
	return state == State.RECORDING
