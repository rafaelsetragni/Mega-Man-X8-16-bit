extends X8OptionButton

const BASE_LOCALES = ["en", "br", "es", "ja_JP", "ko", "zh_CN", "hi", "it"]
const JOKE_LOCALES = ["en_z", "pr", "es_z", "ja_JP_z", "ko_z", "zh_CN_z", "hi_z", "it_z"]


func _ready() -> void:
	._ready()
	Event.connect("translation_updated", self, "_display_joke_mode")

func setup() -> void:
	_display_joke_mode()

func increase_value() -> void:
	_toggle()

func decrease_value() -> void:
	_toggle()

func _toggle() -> void:
	var current_lang = Configurations.get("Language")
	if not current_lang:
		return

	var new_locale: String
	var joke_idx = JOKE_LOCALES.find(current_lang)
	var base_idx = BASE_LOCALES.find(current_lang)

	if joke_idx != -1:
		new_locale = BASE_LOCALES[joke_idx]
	elif base_idx != -1:
		new_locale = JOKE_LOCALES[base_idx]
	else:
		return

	JokeTranslationLoader.apply_language(new_locale)
	Configurations.set("Language", new_locale)
	_display_joke_mode()
	Event.emit_signal("translation_updated")

func _display_joke_mode() -> void:
	var lang = Configurations.get("Language")
	if lang and lang in JOKE_LOCALES:
		display_value("ON_VALUE")
	else:
		display_value("OFF_VALUE")
