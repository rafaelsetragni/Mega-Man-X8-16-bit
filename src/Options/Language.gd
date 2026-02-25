extends X8OptionButton

const BASE_LOCALES = ["en", "br", "es", "ja_JP", "ko", "zh_CN", "hi", "it"]
const JOKE_LOCALES = ["en_z", "pr", "es_z", "ja_JP_z", "ko_z", "zh_CN_z", "hi_z", "it_z"]

var current_index := 0
signal translation_updated


func setup() -> void:
	if not Event.is_connected("translation_updated", self, "_refresh_display"):
		Event.connect("translation_updated", self, "_refresh_display")
	_sync_index()
	_apply_language()

func _sync_index() -> void:
	var lang = get_current_language()
	var joke_idx = JOKE_LOCALES.find(lang)
	if joke_idx != -1:
		current_index = joke_idx
	else:
		var base_idx = BASE_LOCALES.find(lang)
		current_index = base_idx if base_idx != -1 else 0

func _refresh_display() -> void:
	_sync_index()
	var lang = Configurations.get("Language")
	if lang:
		display_value(lang)

func increase_value() -> void:
	current_index = (current_index + 1) % BASE_LOCALES.size()
	_apply_language()

func decrease_value() -> void:
	current_index -= 1
	if current_index < 0:
		current_index = BASE_LOCALES.size() - 1
	_apply_language()

func _apply_language() -> void:
	var locale = _get_effective_locale()
	JokeTranslationLoader.apply_language(locale)
	Configurations.set("Language", locale)
	display_value(locale)
	emit_signal("translation_updated")
	Event.emit_signal("translation_updated")

func _get_effective_locale() -> String:
	var current_lang = Configurations.get("Language")
	if current_lang and current_lang in JOKE_LOCALES:
		return JOKE_LOCALES[current_index]
	return BASE_LOCALES[current_index]

func display_value(new_value) -> void:
	var display_map := {
		"ja_JP": "jp",
		"ja_JP_z": "jp",
		"zh_CN": "zh",
		"zh_CN_z": "zh",
		"pr": "br",
		"en_z": "en",
		"es_z": "es",
		"ko_z": "ko",
		"hi_z": "hi",
		"it_z": "it",
	}
	if new_value in display_map:
		new_value = display_map[new_value]
	value.text = tr(str(new_value))

func get_current_language():
	if Configurations.get("Language"):
		return Configurations.get("Language")
	if OS.get_locale_language() in BASE_LOCALES:
		return OS.get_locale_language()
	return "en"
