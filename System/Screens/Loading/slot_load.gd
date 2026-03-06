extends "res://src/Options/SaveScreen/SlotSaveButton.gd"


func _on_focus_entered() -> void:
	if menu:
		menu.set_current_slot(slot_index)
	._on_focus_entered()


func _on_pressed() -> void:
	if focus_mode == 0:
		return
	Savefile.save_slot = slot_index
	strong_flash()
	menu.loaded_end()
	play_loading_sound()


func play_loading_sound() -> void:
	if not silent and menu:
		menu.play_loaded_sound()
	silent = false
