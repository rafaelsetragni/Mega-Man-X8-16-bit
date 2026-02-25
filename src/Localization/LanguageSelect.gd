extends Node2D

onready var title_label: Label = $title
onready var lang_name_label: Label = $lang_name
onready var hint_label: Label = $hint
onready var fade: Sprite = $fade
onready var flags_node: Node2D = $flags

var current_index: int = 0
var animating: bool = false
var confirmed: bool = false

const LOCALES = ["en", "br", "es", "ja_JP", "pr"]
const NAMES = ["English", "Português (BR)", "Español", "日本語", "Português (HUE)"]
const TITLES = [
	"Select your Language",
	"Selecione seu Idioma",
	"Selecciona tu Idioma",
	"言語を選択してください",
	"Selecione seu Idioma"
]

const FLAG_SPACING := 60.0
const CENTER_X := 199.0
const FLAGS_Y := 108.0
const TWEEN_TIME := 0.15

const DIM_COLOR := Color(0.4, 0.4, 0.4, 1.0)
const DIM_SCALE := Vector2(0.7, 0.7)
const BRIGHT_SCALE := Vector2(1.0, 1.0)


func _ready() -> void:
	fade.modulate = Color.black

	var saved_lang = Configurations.get("Language")
	if saved_lang and saved_lang in LOCALES:
		current_index = LOCALES.find(saved_lang)

	_position_flags_instant()
	_update_labels()

	var t = create_tween()
	t.tween_property(fade, "modulate:a", 0.0, 0.5)


func _input(event: InputEvent) -> void:
	if confirmed or animating:
		return

	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_navigate(-1)
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_navigate(1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("pause"):
		_confirm()


func _navigate(direction: int) -> void:
	var new_index = current_index + direction
	if new_index < 0:
		new_index = LOCALES.size() - 1
	elif new_index >= LOCALES.size():
		new_index = 0

	current_index = new_index
	animating = true
	_animate_flags()
	_update_labels()


func _circular_offset(i: int) -> float:
	var n = LOCALES.size()
	var raw = i - current_index
	if raw > n / 2:
		raw -= n
	elif raw < -n / 2:
		raw += n
	return raw * FLAG_SPACING


func _position_flags_instant() -> void:
	var children = flags_node.get_children()
	for i in range(children.size()):
		children[i].position = Vector2(CENTER_X + _circular_offset(i), FLAGS_Y)
		if i == current_index:
			children[i].modulate = Color.white
			children[i].scale = BRIGHT_SCALE
		else:
			children[i].modulate = DIM_COLOR
			children[i].scale = DIM_SCALE


func _animate_flags() -> void:
	var children = flags_node.get_children()
	var t = create_tween()
	t.set_parallel(true)

	for i in range(children.size()):
		var target_pos = Vector2(CENTER_X + _circular_offset(i), FLAGS_Y)

		t.tween_property(children[i], "position", target_pos, TWEEN_TIME)

		if i == current_index:
			t.tween_property(children[i], "modulate", Color.white, TWEEN_TIME)
			t.tween_property(children[i], "scale", BRIGHT_SCALE, TWEEN_TIME)
		else:
			t.tween_property(children[i], "modulate", DIM_COLOR, TWEEN_TIME)
			t.tween_property(children[i], "scale", DIM_SCALE, TWEEN_TIME)

	t.chain().tween_callback(self, "_on_animation_done")


func _on_animation_done() -> void:
	animating = false


func _update_labels() -> void:
	title_label.text = TITLES[current_index]
	lang_name_label.text = NAMES[current_index]


func _confirm() -> void:
	confirmed = true
	TranslationServer.set_locale(LOCALES[current_index])
	Configurations.set("Language", LOCALES[current_index])
	Savefile.save_config_data()

	var t = create_tween()
	t.tween_property(fade, "modulate:a", 1.0, 0.5)
	t.tween_callback(self, "_go_to_disclaimer")


func _go_to_disclaimer() -> void:
	get_tree().change_scene("res://src/Title/DisclaimerScreen.tscn")
