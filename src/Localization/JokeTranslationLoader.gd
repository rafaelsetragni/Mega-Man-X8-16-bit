extends Node

# Runtime joke translation loader.
# Joke CSVs use base locale codes in their headers so Godot imports them
# as valid Translation resources. This loader swaps joke Translation objects
# in/out of TranslationServer when joke mode is toggled.
#
# All Translation resources are preloaded in _ready() to guarantee stable
# object references for add/remove operations on TranslationServer.

const JOKE_TRANS_PATHS := {
	"en": "res://src/Localization/translations_en_z.en.translation",
	"br": "res://src/Localization/translations_pr.br.translation",
	"es": "res://src/Localization/translations_es_z.es.translation",
	"ja_JP": "res://src/Localization/translations_ja_JP_z.ja_JP.translation",
	"ko": "res://src/Localization/translations_ko_z.ko.translation",
	"zh_CN": "res://src/Localization/translations_zh_CN_z.zh_CN.translation",
	"hi": "res://src/Localization/translations_hi_z.hi.translation",
	"it": "res://src/Localization/translations_it_z.it.translation",
}

const BASE_TRANS_PATHS := {
	"en": "res://src/Localization/translations_en.en.translation",
	"br": "res://src/Localization/translations_br.br.translation",
	"es": "res://src/Localization/translations_es.es.translation",
	"ja_JP": "res://src/Localization/translations_ja_JP.ja_JP.translation",
	"ko": "res://src/Localization/translations_ko.ko.translation",
	"zh_CN": "res://src/Localization/translations_zh_CN.zh_CN.translation",
	"hi": "res://src/Localization/translations_hi.hi.translation",
	"it": "res://src/Localization/translations_it.it.translation",
}

const JOKE_TO_BASE := {
	"en_z": "en",
	"pr": "br",
	"es_z": "es",
	"ja_JP_z": "ja_JP",
	"ko_z": "ko",
	"zh_CN_z": "zh_CN",
	"hi_z": "hi",
	"it_z": "it",
}

const BASE_LOCALES := ["en", "br", "es", "ja_JP", "ko", "zh_CN", "hi", "it"]

# Cached Translation references — loaded once in _ready() for stable identity
var _base_trans := {}
var _joke_trans := {}
var _active_locale := ""


func _ready() -> void:
	for locale in BASE_LOCALES:
		_base_trans[locale] = load(BASE_TRANS_PATHS[locale])
		_joke_trans[locale] = load(JOKE_TRANS_PATHS[locale])
		if not _base_trans[locale]:
			push_error("JokeTranslationLoader: Failed to preload base translation for '%s'" % locale)
		if not _joke_trans[locale]:
			push_error("JokeTranslationLoader: Failed to preload joke translation for '%s'" % locale)


func activate_joke(base_locale: String) -> void:
	if _active_locale == base_locale:
		return
	if _active_locale != "":
		deactivate_joke()
	if not base_locale in _joke_trans or not _joke_trans[base_locale]:
		return
	if not base_locale in _base_trans or not _base_trans[base_locale]:
		return

	TranslationServer.remove_translation(_base_trans[base_locale])
	TranslationServer.add_translation(_joke_trans[base_locale])
	_active_locale = base_locale


func deactivate_joke() -> void:
	if _active_locale == "":
		return

	if _joke_trans.get(_active_locale) and _base_trans.get(_active_locale):
		TranslationServer.remove_translation(_joke_trans[_active_locale])
		TranslationServer.add_translation(_base_trans[_active_locale])

	_active_locale = ""


func is_joke_active() -> bool:
	return _active_locale != ""


func get_base_locale(lang: String) -> String:
	if lang in JOKE_TO_BASE:
		return JOKE_TO_BASE[lang]
	return lang


func is_joke_id(lang: String) -> bool:
	return lang in JOKE_TO_BASE


func apply_language(lang: String) -> void:
	var base_locale = get_base_locale(lang)
	# Swap translations BEFORE setting locale, because set_locale() fires
	# NOTIFICATION_TRANSLATION_CHANGED which triggers UI refresh via tr().
	if is_joke_id(lang):
		activate_joke(base_locale)
	else:
		deactivate_joke()
	TranslationServer.set_locale(base_locale)
