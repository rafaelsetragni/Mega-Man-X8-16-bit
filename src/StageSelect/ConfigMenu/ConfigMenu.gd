extends CanvasLayer

signal end
signal lock_buttons
signal unlock_buttons

onready var content_root: Control = $ContentRoot
onready var fader: ColorRect = $Fader
onready var choice: AudioStreamPlayer = $choice
onready var equip: AudioStreamPlayer = $equip
onready var cancel: AudioStreamPlayer = $cancel
onready var first_button: Control = $ContentRoot/MainView/OptionsButton

onready var options_menu = $OptionsMenu
onready var key_config = $KeyConfig
onready var loading = $LOADING
onready var save_screen = $SaveScreen

var active: bool = false
var locked: bool = true


func _ready() -> void:
	visible = true
	content_root.visible = false
	options_menu.connect("end", self, "_on_submenu_end")
	key_config.connect("end", self, "_on_submenu_end")
	loading.connect("end", self, "_on_submenu_end")
	save_screen.connect("end", self, "_on_submenu_end")


func _input(event: InputEvent) -> void:
	if active and not locked:
		if event.is_action_pressed("ui_cancel"):
			_close()


func start() -> void:
	active = true
	content_root.visible = true
	emit_signal("lock_buttons")
	fader.visible = true
	fader.FadeIn()
	GameManager.set_stretch_mode(SceneTree.STRETCH_MODE_2D)
	yield(fader, "finished")
	unlock_buttons()
	call_deferred("_give_focus")


func _give_focus() -> void:
	first_button.silent = true
	first_button.grab_focus()


func _open_options() -> void:
	play_equip_sound()
	lock_buttons()
	options_menu.start()


func _open_keyconfig() -> void:
	play_equip_sound()
	lock_buttons()
	key_config.start()


func _open_loading() -> void:
	play_equip_sound()
	lock_buttons()
	loading.start()


func _open_save() -> void:
	play_equip_sound()
	lock_buttons()
	save_screen.start()


func on_voltar_confirmed() -> void:
	GameManager.go_to_intro()


func _on_submenu_end() -> void:
	unlock_buttons()
	call_deferred("_give_focus")


func _close() -> void:
	play_cancel_sound()
	active = false
	lock_buttons()
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
