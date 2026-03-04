extends Sprite

export  var color1: Color
export  var color2: Color

onready var tween: TweenController = TweenController.new(self, false)
onready var turbo: Sprite = $"../by/turbo"
onready var modo: Label = $"../by/modo"
onready var by: Label = $"../by"
onready var github_url: Label = $"../github_url"
onready var fade_sprite: Sprite = $"../fade"
onready var jingle: AudioStreamPlayer = $"../jingle"

var able_to_exit: bool = false
var exiting: bool = false

func _ready() -> void :
	Tools.timer(1.0, "play_jingle", self)
	turbo.modulate = Color.black
	modo.modulate = Color.black
	modulate = Color.black
	by.modulate = Color.black
	github_url.modulate = Color.black
	center_top_row()
	activate()

func center_top_row() -> void :
	var font: Font = by.get_font("font")
	var modo_w: float = font.get_string_size(tr("TURBO_MODE")).x
	var by_w: float = font.get_string_size(tr("TURBO_MADE_BY")).x
	var turbo_w: float = turbo.texture.get_width() * turbo.scale.x
	var gap: float = 4.0
	var total_w: float = modo_w + gap + turbo_w + gap + by_w
	var start_x: float = (398.0 - total_w) / 2.0
	var by_x: float = start_x + modo_w + gap + turbo_w + gap
	by.margin_left = by_x
	by.margin_right = by_x + by_w
	modo.margin_left = -(modo_w + gap + turbo_w + gap)
	modo.margin_right = modo.margin_left + modo_w
	turbo.position.x = -(turbo_w / 2.0 + gap)

func activate() -> void :
	Tools.timer(0.5, "appear_turbo", self)
	Tools.timer(1.0, "appear", self)
	Tools.timer(1.5, "appear_github", self)
	Tools.timer(2.5, "set_able_to_exit", self)
	Tools.timer(6, "fade", self)
	Tools.timer(6, "fade_labels", self)

func play_jingle() -> void :
	jingle.play()

func appear_turbo() -> void :
	tween.attribute("modulate", Color.white, 1.0, by)
	tween.attribute("modulate", Color.white, 1.0, turbo)
	tween.attribute("modulate", Color.white, 1.0, modo)
	Tools.timer(0.75, "vibrate_turbo", self)

func vibrate_turbo() -> void :
	var base_x: float = turbo.position.x
	var amp: float = 2.0
	var dur: float = 0.05
	tween.attribute("position:x", base_x + amp, dur, turbo)
	for i in range(9):
		tween.add_attribute("position:x", base_x - amp, dur, turbo)
		tween.add_attribute("position:x", base_x + amp, dur, turbo)
	tween.add_attribute("position:x", base_x, dur, turbo)

func appear() -> void :
	tween.attribute("modulate", color1, 1.3)
	tween.add_attribute("modulate", color2, 0.6)
	tween.add_attribute("modulate", Color.white, 0.9)

func appear_github() -> void :
	tween.attribute("modulate", Color.black, 0.5, github_url)
	tween.add_attribute("modulate", Color.white, 1.5, github_url)

func set_able_to_exit() -> void :
	able_to_exit = true

func fade_labels() -> void :
	tween.attribute("modulate", Color.black, 2.0, by)
	tween.attribute("modulate", Color.black, 2.0, github_url)
	tween.attribute("modulate", Color.black, 2.0, turbo)
	tween.attribute("modulate", Color.black, 2.0, modo)

func fade() -> void :
	tween.attribute("modulate", color2, 0.7)
	tween.add_attribute("modulate", color1, 0.7)
	tween.add_callback("fadeout")

func _input(event: InputEvent) -> void :
	if not able_to_exit:
		return
	if event.is_action_pressed("fire") or event.is_action_pressed("pause"):
		fadeout()

func fadeout() -> void :
	if not exiting:
		exiting = true
		tween.reset()
		tween.attribute("volume_db", - 50.0, 1.0, jingle)
		tween.attribute("modulate", Color.black, 1.0, fade_sprite)
		tween.add_wait(1)
		tween.add_callback("next_screen")

func next_screen() -> void :
	var _dv = get_tree().change_scene("res://System/Screens/Title/CreditStartScreen.tscn")
