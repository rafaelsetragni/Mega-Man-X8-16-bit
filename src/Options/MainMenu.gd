extends X8Menu

onready var info: Label = $Menu / demo_02
onready var _gamestartbutton: X8TextureButton = $Menu / OptionHolder / GameStart
onready var _loadingbutton: X8TextureButton = $Menu / OptionHolder / Loading
onready var _optionsbutton: X8TextureButton = $Menu / OptionHolder / Options
onready var _keyconfigbutton: X8TextureButton = $Menu / OptionHolder / Keycfg
onready var _cursor: AnimatedSprite = $MegamanCursor
onready var Event_screen: TextureRect = $Menu / EVENT
onready var _megaman_logo: TextureRect = $Menu / MegaMan

var _logo_english: Texture = preload("res://src/Title/english_logo.png")
var _logo_japanese: Texture = preload("res://src/Title/japanese_logo.png")
var _logo_chinese: Texture = preload("res://src/Title/chinese_logo.png")

var _event_screen: Texture = null


func _input(event: InputEvent) -> void :
	if not locked:
		if event.is_action_pressed("pause"):
			var start_event: InputEventAction = InputEventAction.new()
			start_event.action = "ui_accept"
			start_event.pressed = true
			Input.parse_input_event(start_event)

func _ready() -> void :
	info.text = GameManager.current_demo + " V." + GameManager.version
	update_logo()
	Event.connect("translation_updated", self, "update_logo")

func update_logo() -> void :
	var locale: String = TranslationServer.get_locale()
	if locale.begins_with("ja"):
		_megaman_logo.texture = _logo_japanese
	elif locale.begins_with("zh"):
		_megaman_logo.texture = _logo_chinese
	else:
		_megaman_logo.texture = _logo_english
