extends CanvasLayer

export  var SlotButtonScene: PackedScene
export  var menu_path: NodePath
export  var initial_focus: NodePath
export  var exit_action: String = "none"
export  var start_emit_event: String = "none"

onready var menu: Control = get_node(menu_path)
onready var focus: Control = get_node(initial_focus)
onready var fader: ColorRect = $Fader
onready var choice: AudioStreamPlayer = $choice
onready var equip: AudioStreamPlayer = $equip
onready var pick: AudioStreamPlayer = $pick
onready var loaded: AudioStreamPlayer = $load
onready var cancel: AudioStreamPlayer = $cancel
onready var save_button_container: VBoxContainer = $Menu / scrollContainer / OptionHolder
onready var exit_button: Control = $Menu / exit

var active: bool = false
var locked: bool = true
var current_slot: int = 0

signal initialize
signal start
signal end
signal lock_buttons
signal unlock_buttons
signal loaded_savefile(gamemode)


func set_current_slot(slot: int) -> void :
	current_slot = slot


func load_all_slots() -> void :
	for child in save_button_container.get_children():
		child.free()
	for slot_index in range(Savefile.max_slots):
		var btn = SlotButtonScene.instance()
		save_button_container.add_child(btn)
		btn.connect_lock_signals(self)
		btn.setup_save(Savefile.load_slot_metadata(slot_index), slot_index)
		if slot_index == Savefile.save_slot:
			focus = btn

	var children := save_button_container.get_children()
	var total := children.size()
	for i in range(total):
		var btn = children[i]
		btn.focus_neighbour_top = children[i - 1].get_path() if i > 0 else exit_button.get_path()
		btn.focus_neighbour_bottom = children[i + 1].get_path() if i < total - 1 else exit_button.get_path()
	if total > 0:
		exit_button.focus_neighbour_bottom = children[0].get_path()
		exit_button.focus_neighbour_top = children[total - 1].get_path()


func loaded_end() -> void :
	Savefile.load_save(Savefile.save_slot)
	CharacterManager.game_mode_set = true
	lock_buttons()
	var tween = create_tween()
	tween.tween_property(fader, "color", Color.black, fader.duration)
	yield(tween, "finished")
	GameManager.reset_stretch_mode()
	if "finished_intro" in GameManager.collectibles:
		GameManager.call_deferred("go_to_stage_select")
	else:
		get_tree().change_scene("res://System/Screens/CharacterSelection/Character_Selection.tscn")


func _style_scrollbar() -> void:
	var vscroll = $Menu/scrollContainer.get_v_scrollbar()
	var blue_style = vscroll.get_stylebox("grabber_highlight")
	if blue_style:
		vscroll.add_stylebox_override("grabber", blue_style)


func _ready() -> void :
	load_all_slots()
	call_deferred("_style_scrollbar")
	if get_parent().name == "root":
		start()
	else:
		menu.visible = false
		visible = true


func _input(event: InputEvent) -> void :
	if active and not locked:
		if exit_action != "none" and event.is_action_pressed(exit_action):
			end()


func start() -> void :
	load_all_slots()
	emit_signal("initialize")
	active = true
	emit_signal("lock_buttons")
	if start_emit_event != "none":
		Event.emit_signal(start_emit_event)
	fader.visible = true
	fader.FadeIn()
	GameManager.set_stretch_mode(SceneTree.STRETCH_MODE_2D)
	yield(fader, "finished")
	unlock_buttons()
	emit_signal("start")
	call_deferred("give_focus")


func give_focus() -> void :
	focus.silent = true
	focus.grab_focus()


func end() -> void :
	cancel.play()
	lock_buttons()
	fader.FadeOut()
	yield(fader, "finished")
	GameManager.reset_stretch_mode()
	emit_signal("end")
	active = false


func play_choice_sound() -> void :
	choice.play()


func play_loaded_sound() -> void :
	loaded.play()


func button_call(method, param = null) -> void :
	if param:
		call_deferred(method, param)
	else:
		call(method)


func lock_buttons() -> void :
	emit_signal("lock_buttons")
	locked = true


func unlock_buttons() -> void :
	emit_signal("unlock_buttons")
	locked = false
