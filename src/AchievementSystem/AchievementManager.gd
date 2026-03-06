extends Node

const _popup_scene = preload("res://src/AchievementSystem/Popup.tscn")
const _dir = "res://src/AchievementSystem/Achievements"
var popup : AchievementPopup
var list : Array
const order = preload("res://src/AchievementSystem/AchievementOrder.tres")

func _ready() -> void:
	initialize_achievements()
	popup = _popup_scene.instance()
	get_parent().call_deferred("add_child",popup)

func initialize_achievements():
	list = []
	for file in order.order:
		if not file.disabled:
			list.append(file)
	print_debug ("Achievements: Initialized " + str(list.size()) +" achievements.")

func unlock(achievement_id : String):
	var found := false
	
	for achievement in list:
		if achievement.get_id() == achievement_id:
			found = true
			if not achievement.unlocked:
				if not GameManager.is_cheating():
					achievement.unlock()
				popup.show_achievement(achievement)
			else:
				print_debug("Achievements: Trying to unlock unlocked achievement " + achievement_id)
	if found:
		queue_save()
		return
	else:
		push_error("Achievements: No achievement found with id " + achievement_id)

var queued_save := false
func queue_save():
	if not queued_save:
		queued_save = true
		call_deferred("save")

func save():
	queued_save = false

func reset_all() -> void:
	print_debug("Achievements: Resetting All... ")
	for achievement in list:
		achievement.unlocked = false
	

func get_unlocked_list() -> Array:
	var unlocked_list := []
	for achievement in list:
		if achievement.unlocked:
			unlocked_list.append(achievement)
	
	unlocked_list.sort_custom(self,"sort_by_date")
	return unlocked_list

func sort_by_date(a,b):
	if (a.date < b.date): return false; 
	if (a.date > b.date): return true; 
	return false;

func export_unlocked_list() -> Dictionary:
	var dict := {}
	for achievement in get_unlocked_list():
		dict[achievement.get_id()] = achievement.date
	return dict

func get_locked_list() -> Array:
	var locked_list = []
	for achievement in list:
		if not achievement.unlocked:
			locked_list.append(achievement)
	return locked_list

func load_achievements(loaded_achievements : Dictionary) -> void:
	print_debug ("Achievements: Loading from savedata...")
	var i = 0
	for key in loaded_achievements.keys():
		for achievement in list:
			if achievement.get_id() == key:
				achievement.unlocked = true
				achievement.date = loaded_achievements[key]
				i += 1
	
	if i > 0:
		print_debug("Achievements: " + str(i) + " unlocked from savedata.")
	else:
		print ("Achievements: No achievements on savedata.")

func got_all() -> bool:
	return get_locked_list().size() == 0

func _get_files(path : String) -> Array:
	var files = []
	var dir := Directory.new()
	dir.open(path)
	dir.list_dir_begin(true)

	var file = dir.get_next()
	while file != '':
		files += [file]
		file = dir.get_next()

	return files
