extends X8TextureButton

export  var pick_sound: NodePath
onready var label: Label = $text

func _ready() -> void :
	CharacterManager.game_mode_set = false
	label.text = tr("GAME_START")
	Event.connect("translation_updated", self, "update_display")

func update_display():
	label.text = tr("GAME_START")

func update_game_mode(mode: int) -> void :
	CharacterManager.game_mode = mode
	CharacterManager.update_game_mode()

func on_press() -> void :
	CharacterManager.game_mode_set = true
	GameManager.collectibles = []
	GameManager.equip_exceptions = []
	GlobalVariables.variables = {}
	GameManager.seen_dialogues.clear()
	Savefile.newgame_plus = 0
	GatewayManager.reset_bosses()
	CharacterManager.reset_for_new_game()
	BossRNG.rng.seed = 0
	IGT.set_time(0.0)
	IGT.reset()
	get_node(pick_sound).play()
	Event.emit_signal("fadeout_startmenu")
	strong_flash()
	menu.lock_buttons()
	menu.fader.SoftFadeOut()
	yield(menu.fader, "finished")

	go_to_next_scene()

func go_to_next_scene() -> void :
	if already_finished_noahs_park():
		GameManager.call_deferred("go_to_stage_select")
	else:
		get_tree().change_scene("res://System/Screens/CharacterSelection/Character_Selection.tscn")

func already_finished_noahs_park() -> bool:
	return "finished_intro" in GameManager.collectibles
