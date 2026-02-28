extends Node

# Debug-only translation key validator.
# Checks that all per-language CSVs have identical key sets.
# Only runs in debug builds; does nothing in release exports.

const LOCALIZATION_DIR := "res://src/Localization/"
const REFERENCE_LANG := "en"
const LANGUAGES := ["en", "br", "es", "ja_JP", "ko", "zh_CN", "hi", "it", "pr", "en_z", "es_z", "ja_JP_z", "ko_z", "zh_CN_z", "hi_z", "it_z"]

func _ready() -> void:
	if not OS.is_debug_build():
		return
	call_deferred("_validate_translations")

func _validate_translations() -> void:
	var reference_keys := _load_keys(REFERENCE_LANG)
	if reference_keys.empty():
		push_error("TranslationValidator: Could not load reference keys for '%s'" % REFERENCE_LANG)
		return

	print("TranslationValidator: Reference language '%s' has %d keys" % [REFERENCE_LANG, reference_keys.size()])

	var all_valid := true
	for lang in LANGUAGES:
		if lang == REFERENCE_LANG:
			continue
		var lang_keys := _load_keys(lang)
		if lang_keys.empty():
			push_error("TranslationValidator: Could not load keys for '%s'" % lang)
			all_valid = false
			continue

		var missing := []
		for key in reference_keys:
			if not key in lang_keys:
				missing.append(key)

		var extra := []
		for key in lang_keys:
			if not key in reference_keys:
				extra.append(key)

		if missing.size() > 0:
			push_warning("TranslationValidator: '%s' is missing %d keys: %s" % [
				lang, missing.size(), str(missing).substr(0, 200)])
			all_valid = false

		if extra.size() > 0:
			push_warning("TranslationValidator: '%s' has %d extra keys: %s" % [
				lang, extra.size(), str(extra).substr(0, 200)])
			all_valid = false

		if missing.size() == 0 and extra.size() == 0:
			print("TranslationValidator: '%s' OK (%d keys)" % [lang, lang_keys.size()])

	if all_valid:
		print("TranslationValidator: All languages validated successfully.")

func _load_keys(lang: String) -> Array:
	var path := LOCALIZATION_DIR + "translations_%s.csv" % lang
	var file := File.new()
	if file.open(path, File.READ) != OK:
		push_error("TranslationValidator: Cannot open '%s'" % path)
		return []

	var keys := []
	var first_line := true
	while not file.eof_reached():
		var line := file.get_csv_line()
		if first_line:
			first_line = false
			continue
		if line.size() >= 1 and line[0] != "":
			keys.append(line[0])
	file.close()
	return keys
