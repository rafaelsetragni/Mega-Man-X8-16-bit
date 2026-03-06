extends Node2D

onready var fade: Sprite = $fade
onready var thanks_label: Label = $thanks_label
onready var inspired_label: Label = $inspired_label
onready var capcom_label: Label = $capcom_label
onready var time_title: Label = $time_title
onready var time_value: Label = $time_value
onready var tween: TweenController = TweenController.new(self, false)

var japanese_font = preload("res://src/Fonts/japaneseFont.tres")

var can_dismiss := false
var exiting := false

func _ready() -> void:
	_apply_translations()
	_apply_font_for_locale()
	time_value.text = IGT.time_formatting(IGT.in_game_timer)
	_hide_all_labels()
	fade.modulate = Color.black
	Tools.timer(1.0, "fade_in", self)

func _apply_translations() -> void:
	thanks_label.text = tr("THANKS_FOR_PLAYING")
	inspired_label.text = tr("INSPIRED_BY")
	time_title.text = tr("FINAL_TIME")

func _apply_font_for_locale() -> void:
	var lang = Configurations.get("Language") if Configurations.exists("Language") else "en"
	if lang in ["ja_JP", "ja_JP_z", "ko", "ko_z", "zh_CN", "zh_CN_z", "hi", "hi_z"]:
		for label in [thanks_label, inspired_label, capcom_label, time_title, time_value]:
			label.set("custom_fonts/font", japanese_font)

func _hide_all_labels() -> void:
	for label in [thanks_label, inspired_label, capcom_label, time_title, time_value]:
		label.modulate = Color(label.modulate.r, label.modulate.g, label.modulate.b, 0.0)

func fade_in() -> void:
	tween.attribute("modulate", Color(0, 0, 0, 0.0), 2.0, fade)
	tween.add_wait(0.5)
	tween.add_callback("show_labels")

func show_labels() -> void:
	tween.attribute("modulate", Color(thanks_label.modulate.r, thanks_label.modulate.g, thanks_label.modulate.b, 1.0), 1.5, thanks_label)
	tween.add_attribute("modulate", Color(inspired_label.modulate.r, inspired_label.modulate.g, inspired_label.modulate.b, 1.0), 1.5, inspired_label)
	tween.add_attribute("modulate", Color(capcom_label.modulate.r, capcom_label.modulate.g, capcom_label.modulate.b, 1.0), 1.5, capcom_label)
	tween.add_attribute("modulate", Color(time_title.modulate.r, time_title.modulate.g, time_title.modulate.b, 1.0), 1.5, time_title)
	tween.add_attribute("modulate", Color(time_value.modulate.r, time_value.modulate.g, time_value.modulate.b, 1.0), 1.5, time_value)
	tween.add_callback("enable_dismiss")

func enable_dismiss() -> void:
	can_dismiss = true

func _input(event: InputEvent) -> void:
	if can_dismiss and not exiting:
		if event.is_action_pressed("fire") or event.is_action_pressed("pause") or event.is_action_pressed("ui_accept"):
			fade_out()

func fade_out() -> void:
	exiting = true
	tween.reset()
	tween.attribute("modulate", Color(0, 0, 0, 1.0), 2.0, fade)
	tween.add_callback("go_to_disclaimer", GameManager)
