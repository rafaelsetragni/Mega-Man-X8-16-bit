extends CanvasLayer

export var SlotButtonScene: PackedScene

signal end
signal lock_buttons
signal unlock_buttons
signal transition_committed

onready var content_root: Control = $ContentRoot
onready var main_view: Control = $ContentRoot/MainView
onready var slots_view: Control = $ContentRoot/SlotsView
onready var slot_container: VBoxContainer = $ContentRoot/SlotsView/ScrollContainer/SlotContainer
onready var fader: ColorRect = $Fader
onready var choice: AudioStreamPlayer = $choice
onready var equip: AudioStreamPlayer = $equip
onready var cancel: AudioStreamPlayer = $cancel
onready var salvar_button: Control = $ContentRoot/MainView/SalvarButton

var active: bool = false
var locked: bool = true
var _transition_mode: bool = false


func _ready() -> void:
	visible = true
	content_root.visible = false
	if _is_debugging():
		content_root.visible = true
		main_view.visible = true
		slots_view.visible = false
		unlock_buttons()
		call_deferred("_give_main_focus")


func _is_debugging() -> bool:
	return get_parent() == get_tree().root


func _input(event: InputEvent) -> void:
	if active and not locked:
		if event.is_action_pressed("ui_cancel"):
			if slots_view.visible:
				_show_main_view()
			else:
				_close()


func start() -> void:
	active = true
	main_view.visible = true
	slots_view.visible = false
	emit_signal("lock_buttons")
	fader.visible = true
	fader.FadeIn()
	GameManager.set_stretch_mode(SceneTree.STRETCH_MODE_2D)
	yield(fader, "finished")
	unlock_buttons()
	call_deferred("_give_main_focus")


func _give_main_focus() -> void:
	salvar_button.silent = true
	salvar_button.grab_focus()


func _show_main_view() -> void:
	play_cancel_sound()
	slots_view.visible = false
	main_view.visible = true
	call_deferred("_give_main_focus")


func _on_salvar_pressed() -> void:
	play_equip_sound()
	main_view.visible = false
	slots_view.visible = true
	_load_slot_list()


func _on_continuar_pressed() -> void:
	_close()


func on_slot_save(slot_index: int) -> void:
	Savefile.save_slot = slot_index
	Savefile.save(slot_index)
	play_equip_sound()
	_close()


func start_for_transition() -> void:
	_transition_mode = true
	active = true
	main_view.visible = true
	slots_view.visible = false
	# Hide VoltarButton — not applicable in level-transition context
	var voltar_btn := get_node_or_null("ContentRoot/MainView/VoltarButton")
	if voltar_btn:
		voltar_btn.visible = false
	# Fix circular focus: only Salvar and Continuar remain
	var continuar_btn := get_node_or_null("ContentRoot/MainView/ContinuarButton")
	if salvar_button and continuar_btn:
		salvar_button.focus_neighbour_top = continuar_btn.get_path()
		continuar_btn.focus_neighbour_bottom = salvar_button.get_path()
	content_root.visible = true
	GameManager.set_stretch_mode(SceneTree.STRETCH_MODE_2D)
	unlock_buttons()
	call_deferred("_give_main_focus")


func on_voltar_confirmed() -> void:
	if _transition_mode:
		return
	lock_buttons()
	fader.SoftFadeOut()
	yield(fader, "finished")
	GameManager.unpause("PauseMenu")
	GameManager.go_to_stage_select()


func _load_slot_list() -> void:
	for child in slot_container.get_children():
		child.queue_free()
	var focus_btn: Control = null
	for i in range(Savefile.max_slots):
		var btn = SlotButtonScene.instance()
		slot_container.add_child(btn)
		btn.connect_lock_signals(self)
		btn.setup_save(Savefile.load_slot_metadata(i), i)
		if i == Savefile.save_slot:
			focus_btn = btn
	if not focus_btn and slot_container.get_child_count() > 0:
		focus_btn = slot_container.get_child(0)
	# Circular focus navigation
	var children := slot_container.get_children()
	var total := children.size()
	for i in range(total):
		var btn = children[i]
		btn.focus_neighbour_top = children[(i - 1 + total) % total].get_path()
		btn.focus_neighbour_bottom = children[(i + 1) % total].get_path()
	if focus_btn:
		call_deferred("_set_focus", focus_btn)


func _set_focus(node: Control) -> void:
	node.silent = true
	node.grab_focus()


func _close() -> void:
	active = false
	lock_buttons()
	if _transition_mode:
		content_root.visible = false
		GameManager.reset_stretch_mode()
		emit_signal("transition_committed")
		return
	fader.FadeOut()
	yield(fader, "finished")
	GameManager.reset_stretch_mode()
	emit_signal("end")


func play_choice_sound() -> void:
	if choice:
		choice.play()


func play_equip_sound() -> void:
	if equip:
		equip.play()


func play_cancel_sound() -> void:
	if cancel:
		cancel.play()


func button_call(method, _param = null) -> void:
	call(method)


func lock_buttons() -> void:
	emit_signal("lock_buttons")
	locked = true


func unlock_buttons() -> void:
	emit_signal("unlock_buttons")
	locked = false
