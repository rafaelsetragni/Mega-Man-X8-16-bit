extends Node2D

onready var title_label: Label = $Title/text
onready var diff_name_label: Label = $diff_name
onready var diff_desc_label: Label = $diff_desc
onready var fade: Sprite = $fade
onready var images_node: Node2D = $images
onready var bg: Sprite = $bg
onready var navigate_sound: AudioStreamPlayer = $navigate_sound
onready var confirm_sound: AudioStreamPlayer = $confirm_sound
onready var cancel_sound: AudioStreamPlayer = $cancel_sound
onready var back_label: Label = $back_label

var music: AudioStreamPlayer

var current_index: int = 1
var animating: bool = false
var confirmed: bool = false
var on_back: bool = false

const BACK_SELECTED_COLOR := Color("#fbffaf")
const BACK_IDLE_COLOR := Color(0.6, 0.6, 0.6, 1.0)

var all_modes: Array = [-1, 0, 1, 2, 3]
var unlocked: Array = []

const NAMES = ["DIFFICULTY_KIDS", "DIFFICULTY_EASY", "DIFFICULTY_NORMAL", "DIFFICULTY_HARD", "DIFFICULTY_IMPOSSIBLE"]
const DESCS = ["DIFFICULTY_KIDS_DESC", "DIFFICULTY_EASY_DESC", "DIFFICULTY_NORMAL_DESC", "DIFFICULTY_HARD_DESC", "DIFFICULTY_IMPOSSIBLE_DESC"]
const LOCKED_DESCS = ["", "", "", "DIFFICULTY_HARD_UNLOCK", "DIFFICULTY_IMPOSSIBLE_UNLOCK"]

const SELECTED_GAP := 100.0
const DIM_GAP := 75.0
const CENTER_X := 199.0
const IMAGES_Y := 78.0
const TWEEN_TIME := 0.15

const DIM_COLOR := Color(0.3, 0.3, 0.3, 1.0)
const LOCKED_BRIGHT_COLOR := Color(1.0, 1.0, 1.0, 0.3)
const LOCKED_DIM_COLOR := Color(0.3, 0.3, 0.3, 0.3)
const DIM_SCALE := Vector2(0.13, 0.13)
const BRIGHT_SCALE := Vector2(0.21, 0.21)

var name_colors: Dictionary = {
	-1: Color("#8cff8c"),
	 0: Color("#fbffaf"),
	 1: Color("#68b0ff"),
	 2: Color("#ff7200"),
	 3: Color("#e090f2")
}


func _ready() -> void:
	fade.modulate = Color.black
	music = get_tree().root.get_node_or_null("PersistentMusic")
	_build_unlocked()
	_position_images_instant()
	_update_labels()

	var t = create_tween()
	t.tween_property(fade, "modulate:a", 0.0, 0.5)


func _build_unlocked() -> void:
	unlocked = [true, true, true, false, false]
	if CharacterManager.beaten_hard:
		unlocked[3] = true
	if CharacterManager.beaten_insanity:
		unlocked[4] = true
	current_index = 2


func _input(event: InputEvent) -> void:
	if confirmed or animating:
		return

	if on_back:
		if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
			_select_carousel()
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("pause"):
			_go_back()
		elif event.is_action_pressed("ui_cancel"):
			_go_back()
		return

	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_navigate(-1)
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_navigate(1)
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_select_back()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("pause"):
		if unlocked[current_index]:
			_confirm()
	elif event.is_action_pressed("ui_cancel"):
		_go_back()


func _navigate(direction: int) -> void:
	var new_index = current_index + direction
	if new_index < 0 or new_index >= all_modes.size():
		return

	current_index = new_index
	animating = true
	navigate_sound.play()
	_animate_images()
	_update_labels()


func _get_offset(i: int) -> float:
	if i == current_index:
		return 0.0
	var dir = sign(i - current_index)
	var steps = abs(i - current_index)
	return dir * (SELECTED_GAP + (steps - 1) * DIM_GAP)


func _get_color(i: int) -> Color:
	if i == current_index:
		if unlocked[i]:
			return Color.white
		return LOCKED_BRIGHT_COLOR
	if unlocked[i]:
		return DIM_COLOR
	return LOCKED_DIM_COLOR


func _position_images_instant() -> void:
	var children = images_node.get_children()
	for i in range(children.size()):
		var container = children[i]
		var sprite = container.get_node("img")
		var cursor = container.get_node("cursor")
		container.position = Vector2(CENTER_X + _get_offset(i), IMAGES_Y)
		sprite.self_modulate = _get_color(i)
		if i == current_index:
			container.scale = BRIGHT_SCALE
			container.z_index = 1
			cursor.visible = true
		else:
			container.scale = DIM_SCALE
			container.z_index = 0
			cursor.visible = false


func _animate_images() -> void:
	var children = images_node.get_children()
	var t = create_tween()
	t.set_parallel(true)

	for i in range(children.size()):
		var container = children[i]
		var sprite = container.get_node("img")
		var cursor = container.get_node("cursor")
		var target_pos = Vector2(CENTER_X + _get_offset(i), IMAGES_Y)
		t.tween_property(container, "position", target_pos, TWEEN_TIME)
		t.tween_property(sprite, "self_modulate", _get_color(i), TWEEN_TIME)

		if i == current_index:
			container.z_index = 1
			cursor.visible = true
			t.tween_property(container, "scale", BRIGHT_SCALE, TWEEN_TIME)
		else:
			container.z_index = 0
			cursor.visible = false
			t.tween_property(container, "scale", DIM_SCALE, TWEEN_TIME)

	t.chain().tween_callback(self, "_on_animation_done")


func _on_animation_done() -> void:
	animating = false


func _update_labels() -> void:
	var mode = all_modes[current_index]
	diff_name_label.text = tr(NAMES[current_index])
	diff_name_label.add_color_override("font_color", name_colors[mode])
	if unlocked[current_index]:
		diff_desc_label.text = tr(DESCS[current_index])
	else:
		diff_desc_label.text = tr(LOCKED_DESCS[current_index])


func _confirm() -> void:
	confirmed = true
	var mode = all_modes[current_index]
	CharacterManager.game_mode = mode
	CharacterManager.game_mode_set = true
	CharacterManager.update_game_mode()
	confirm_sound.play()
	flash()
	if music:
		music.start_fade_out()
	Tools.timer(0.48, "fade_out", self)
	Tools.timer(2.0, "_go_to_next", self)


func flash() -> void:
	white_bg()
	var interval := 0.016
	var i := 0
	var n := 1
	while i < 19:
		Tools.timer(interval + interval * i, _get_flash_bg(n), self)
		i += 1
		n *= -1


func _get_flash_bg(n: int) -> String:
	if n > 0:
		return "normal_bg"
	return "white_bg"


func white_bg() -> void:
	bg.modulate = Color(4, 4, 4, 1)


func normal_bg() -> void:
	bg.modulate = Color(1, 1, 1, 1)


func fade_out() -> void:
	fade.modulate = Color(0, 0, 0, 0)
	var t = create_tween()
	t.tween_property(fade, "modulate:a", 1.0, 1.5)


func _select_back() -> void:
	on_back = true
	navigate_sound.play()
	back_label.add_color_override("font_color", BACK_SELECTED_COLOR)
	var cursor = images_node.get_child(current_index).get_node("cursor")
	cursor.visible = false


func _select_carousel() -> void:
	on_back = false
	navigate_sound.play()
	back_label.add_color_override("font_color", BACK_IDLE_COLOR)
	var cursor = images_node.get_child(current_index).get_node("cursor")
	cursor.visible = true


func _go_back() -> void:
	confirmed = true
	cancel_sound.play()
	var t = create_tween()
	t.tween_property(fade, "modulate", Color.black, 0.3)
	t.tween_callback(self, "_go_to_char_select")


func _go_to_char_select() -> void:
	get_tree().change_scene("res://System/Screens/CharacterSelection/Character_Selection.tscn")


func _go_to_next() -> void:
	if music:
		music.queue_free()
	GameManager.start_level("NoahsPark")
