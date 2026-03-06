extends Node2D

export  var song: AudioStream

onready var tween: TweenController = TweenController.new(self, false)
onready var visuals: Node2D = $Visuals
onready var credits_bg: Sprite = $CreditsBG
onready var musicplayer: AudioStreamPlayer = $"Music Player"
onready var screencover: Sprite = $screencover
onready var credits: Node2D = $Credits
onready var credits_part1: RichTextLabel = $Credits / richTextLabel
onready var credits_part2: RichTextLabel = $Credits / richTextLabel2
onready var bottom_cover: Sprite = $bottom_cover
onready var top_cover: Sprite = $top_cover
onready var loop: AudioStreamPlayer2D = $Visuals / ElevatorPlatform / loop
onready var _x_sprite: AnimatedSprite = $Visuals / ElevatorPlatform / X
onready var _axl_sprite: AnimatedSprite = $Visuals / ElevatorPlatform / Axl
onready var _zero_sprite: AnimatedSprite = $Visuals / ElevatorPlatform / Zero
onready var finalrta = $FinalTime / RTADisplay / Time
onready var finaltime = $FinalTime / IGTDisplay / Time
onready var bitmap_font: BitmapFont = preload("res://src/Fonts/x8bitmapfontfinal.fnt")

var scroll_speed: float = 1.0
var base_duration: float = 158.0
var total_height: float = 0
var fade_out_duration: float = 6.0

func axl_credits():
	CharacterManager.set_axl_colors(_axl_sprite)

func zero_credits():
	CharacterManager.set_zero_colors(_zero_sprite)

func _ready() -> void :
	axl_credits()
	zero_credits()
	_translate_credits()

	Tools.timer(1, "fade_in", self)
	Tools.timer(0.02, "start", self)
	var final_rta = IGT.time_formatting(IGT.rta_timer)
	finalrta.text = final_rta
	var final_time = IGT.time_formatting(IGT.in_game_timer)
	finaltime.text = final_time

	Tools.timer(0.35, "start_music", self)
	Tools.timer(3.0, "roll_up_credits", self)

func start():
	move_to_the_side()
	move_credits_in()

func start_music():
	musicplayer.play_song(song)

func move_to_the_side():
	tween.create(Tween.EASE_IN_OUT, Tween.TRANS_SINE)
	tween.add_attribute("position", Vector2(-100, visuals.position.y), 6.0, visuals)

func move_credits_in():
	tween.create(Tween.EASE_IN_OUT, Tween.TRANS_SINE)
	tween.add_attribute("position", Vector2(180, credits_bg.position.y), 6.0, credits_bg)
	

func turn_on_covers():
	var final_y = bottom_cover.position.y
	bottom_cover.position.y += 16
	tween.create(Tween.EASE_OUT, Tween.TRANS_SINE)
	tween.add_attribute("position", Vector2(bottom_cover.position.x, final_y), 2.0, bottom_cover)

	final_y = top_cover.position.y
	top_cover.position.y -= 16
	tween.create(Tween.EASE_OUT, Tween.TRANS_SINE)
	tween.add_attribute("position", Vector2(top_cover.position.x, final_y), 2.0, top_cover)
	bottom_cover.visible = true
	top_cover.visible = true

func fade_in():
	
	screencover.modulate = Color.black
	tween.attribute("modulate", Color(0, 0, 0, 0.0), 3.0, screencover)





	
func _process(delta: float) -> void :
	if CharacterManager.credits_seen:
		if Input.is_action_pressed("pause"):
			fade_out_duration = 1.0
			fade_out()

func roll_up_credits():
	var font_size = bitmap_font.get_height()

	var lines_part1 = credits_part1.get_line_count()
	var total_lines = lines_part1

	var total_height = total_lines * font_size

	var buffer = 55 * font_size
	total_height += buffer

	var base_duration = 158.0
	var duration = base_duration / scroll_speed

	credits.position.x = 296
	tween.attribute("position", Vector2(credits.position.x, -total_height), duration, credits)
	tween.add_callback("fade_out")

func fade_out():
	screencover.visible = true
	tween.attribute("modulate", Color(screencover.modulate.r, screencover.modulate.g, screencover.modulate.b, 1.0), fade_out_duration, screencover)
	tween.add_wait(3)
	tween.attribute("volume_db", - 80, fade_out_duration, loop)
	CharacterManager.credits_seen = true
	CharacterManager._save()
	if IGT.clocked_all_stages():
		tween.add_callback("go_to_igt",GameManager)
	else:
		tween.add_callback("go_to_thanks_screen",GameManager)

func _translate_credits() -> void:
	var replacements = [
		# Fangame credits (longer strings first to avoid partial matches)
		["And thanks to \nall of the Megaman X\nSpeedrunning Community!", tr("CREDITS_SPEEDRUN")],
		["Thanks to all the \nawesome contributors!", tr("CREDITS_CONTRIBUTORS")],
		["Sprites, Sounds and \nBackground rips", tr("CREDITS_SPRITES")],
		["Original Megaman X8 Staff", tr("CREDITS_ORIGINAL_STAFF")],
		["Thank you for your support", tr("CREDITS_THANK_SUPPORT")],
		["Special Thanks to", tr("CREDITS_SPECIAL_THANKS_TO")],
		["Special Thanks", tr("CREDITS_SPECIAL_THANKS")],
		["Spanish Localization", tr("CREDITS_SPANISH_LOC")],
		["MM1 Boss Battle Remix", tr("CREDITS_MM1_REMIX")],
		["Consulting and QA", tr("CREDITS_CONSULTING")],
		["A fangame by", tr("CREDITS_FANGAME_BY")],
		["Turbo mod by", tr("CREDITS_TURBO_MOD")],
		["Decompiled by", tr("CREDITS_DECOMPILED")],
		["Rewritten by", tr("CREDITS_REWRITTEN")],
		["Playtesters", tr("CREDITS_PLAYTESTERS")],
		["Modded by", tr("CREDITS_MODDED")],
		["Based on", tr("CREDITS_BASED_ON")],
		# Capcom staff (longer/multi-line first, then shorter)
		["Produced in association with\nThe Ocean Group - Canada", tr("CREDITS_OCEAN_GROUP")],
		["International Business Departament", tr("CREDITS_INTL_BIZ")],
		["Visual Director\nand Character Design", tr("CREDITS_VISUAL_DIR")],
		["Lead Character Design \nand Animators", tr("CREDITS_LEAD_CHAR")],
		["Character Design\n and Animators", tr("CREDITS_CHAR_DESIGN")],
		["Background Concept\nArt Designer", tr("CREDITS_BG_CONCEPT")],
		["Lead Background\nDesigner", tr("CREDITS_LEAD_BG")],
		["Publishing Team \nSuleputer Label", tr("CREDITS_PUBLISHING")],
		["Recorded At\nBlue Waters Studios", tr("CREDITS_RECORDED_AT")],
		["Promotional Video Editors", tr("CREDITS_PROMO_VIDEO")],
		["Technical Program Support", tr("CREDITS_TECH_PROGRAM")],
		["Sound Technical Support", tr("CREDITS_SOUND_TECH")],
		["Technical Visual Director", tr("CREDITS_TECH_VISUAL")],
		["Lead Background Designer", tr("CREDITS_LEAD_BG_DESIGNER")],
		["Production Coordinator", tr("CREDITS_PROD_COORD")],
		["Visual Effects Design", tr("CREDITS_VFX")],
		["Sound Effects Design", tr("CREDITS_SFX_DESIGN")],
		["Character Animation", tr("CREDITS_CHAR_ANIM")],
		["Character Modeling", tr("CREDITS_CHAR_MODEL")],
		["Production Manager", tr("CREDITS_PROD_MANAGER")],
		["Executive Producer", tr("CREDITS_EXEC_PRODUCER")],
		["Animation Director", tr("CREDITS_ANIM_DIRECTOR")],
		["Technical Director", tr("CREDITS_TECH_DIRECTOR")],
		["Recording Engineers", tr("CREDITS_REC_ENG")],
		["Assistant Engineers", tr("CREDITS_ASST_ENG")],
		["Merchandising Team", tr("CREDITS_MERCH")],
		["Project Management", tr("CREDITS_PROJECT_MGMT")],
		["Main Game Designer", tr("CREDITS_MAIN_DESIGNER")],
		["2D Object Design", tr("CREDITS_2D_OBJECT")],
		["Title Logo Design", tr("CREDITS_TITLE_LOGO")],
		["Background Design", tr("CREDITS_BG_DESIGN")],
		["Public Relations", tr("CREDITS_PR")],
		["Boss Programmers", tr("CREDITS_BOSS_PROG")],
		["Scenario Writers", tr("CREDITS_SCENARIO")],
		["Sound Composers", tr("CREDITS_SOUND_COMP")],
		["Sound Composer", tr("CREDITS_SOUND_COMPOSER")],
		["Voice Directors", tr("CREDITS_VOICE_DIR")],
		["Manual Design", tr("CREDITS_MANUAL")],
		["Lead Animator", tr("CREDITS_LEAD_ANIMATOR")],
		["Game Designers", tr("CREDITS_GAME_DESIGNERS")],
		["Main Programmer", tr("CREDITS_MAIN_PROG")],
		["Line Producer", tr("CREDITS_LINE_PRODUCER")],
		["Rockman Club", tr("CREDITS_ROCKMAN_CLUB")],
		["Voice Actors", tr("CREDITS_VOICE_ACTORS")],
		["Art Director", tr("CREDITS_ART_DIRECTOR")],
		["Game Planner", tr("CREDITS_GAME_PLANNER")],
		["Localization", tr("CREDITS_LOCALIZATION")],
		["Programmers", tr("CREDITS_PROGRAMMERS")],
		["Animators", tr("CREDITS_ANIMATORS")],
		["Marketing", tr("CREDITS_MARKETING")],
		["Promotion", tr("CREDITS_PROMOTION")],
		["Publicity", tr("CREDITS_PUBLICITY")],
		["Director", tr("CREDITS_DIRECTOR")],
		["Testers", tr("CREDITS_TESTERS")],
		["Sales", tr("CREDITS_SALES")],
		["and CAPCOM All Staff!", tr("CREDITS_AND_CAPCOM")],
	]
	var txt = credits_part1.bbcode_text
	for pair in replacements:
		txt = txt.replace(pair[0], pair[1])
	credits_part1.bbcode_text = txt
