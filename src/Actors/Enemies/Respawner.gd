class_name Respawner extends Node2D

export var active := true
export var minimum_death_duration := 3.0
export var on_exit_despawn_after := 10.0
export var minimum_exit_duration := 0.0
export var next_checkpoint := -8
var enemies : Array
var starter_enemies : Array
var extras : Array
const respawn_marker := preload("res://src/System/Respawn/RespawnMark.tscn")

signal respawned
signal despawned

# True during demo playback when this Respawner has recorded game_events.
# In that case, all respawning is driven by DemoSystem game_events (exact frame timing).
# False when there are no recorded events — marks are used as normal fallback.
var _demo_using_game_events := false

func _ready() -> void:
	_initialize_enemies_watched_list()
	despawn_all()
	var ds = get_node_or_null("/root/DemoSystem")
	if ds and ds.is_demo_playing():
		_demo_using_game_events = _has_recorded_respawn_events(ds)
		if _demo_using_game_events:
			# Respawn lifecycle managed entirely by DemoSystem game_events.
			Event.listen("moved_player_to_checkpoint",self,"on_checkpoint_start")
			return
		# No recorded events for this Respawner: fall back to mark-based respawning.
		# The small real-time timer drift (~1-2 frames) is acceptable for
		# enemies in sections the player doesn't reach during recording.
	mark_all_for_respawn()
	Tools.timer(0.1,"first_checkpoint_spawn",self)
	Event.listen("moved_player_to_checkpoint",self,"on_checkpoint_start")

func _has_recorded_respawn_events(ds) -> bool:
	var scene = get_tree().current_scene
	if not scene:
		return false
	var my_path := str(scene.get_path_to(self))
	for ev in ds.game_events:
		if ev[1] == my_path and ev[2] == "respawn":
			return true
	return false

func _initialize_enemies_watched_list():
	for child in get_children():
		if child is Enemy:
			var watched_enemy = Watched.new(child)
			if child.spawn_at_start:
				starter_enemies.append(watched_enemy)
			else:
				enemies.append(watched_enemy)

		else:
			extras.append(child)

func connect_death_and_screen_signals(enemy : Watched):
	enemy.object.connect("death",self,"mark_for_respawn",[enemy])
	enemy.object.get_visibility_notifier().connect("screen_exited",self,"on_enemy_exit_screen",[enemy])
	enemy.object.get_visibility_notifier().connect("screen_entered",self,"on_enemy_enter_screen",[enemy])

func on_enemy_exit_screen(enemy : Watched):
	if is_instance_valid(enemy.object):
		if active and enemy.object.current_health > 0:
			var ds = get_node_or_null("/root/DemoSystem")
			if ds and ds.is_demo_playing():
				return  # No exit-despawn timers during demo playback
			enemy.outside_timer = Tools.timer_r(on_exit_despawn_after,"despawn_and_mark_for_respawn",self,[enemy])

func on_enemy_enter_screen(enemy : Watched):
	if is_instance_valid(enemy.outside_timer):
		enemy.outside_timer.stop()
		enemy.outside_timer.queue_free()
		enemy.outside_timer = null


func despawn_and_mark_for_respawn(enemy : Watched):
	if active:
		if is_instance_valid(enemy.object):
			despawn(enemy)
			mark_for_respawn(enemy,minimum_exit_duration)

func despawn(enemy : Watched):
	if is_instance_valid(enemy.object):
		enemy.object.destroy()
		emit_signal("despawned")

func mark_for_respawn(enemy : Watched, death_duration = minimum_death_duration):
	if _demo_using_game_events:
		return  # This Respawner uses game_events; marks would cause non-deterministic timing
	if active:
		var mark := respawn_marker.instance()
		enemy.parent.add_child(mark,true)
		mark.global_position = enemy.position
		mark.rect = enemy.notifier_size
		if death_duration > 0:
			Tools.timer(death_duration,"activate",mark)
		else:
			mark.activate()
		mark.connect("ready_for_respawn",self,"respawn",[enemy])

func respawn(enemy : Watched):
	if active and not is_instance_valid(enemy.object):
		var spawn = enemy.scene.instance()
		enemy.parent.add_child(spawn,true)
		spawn.global_position = enemy.position
		enemy.object = spawn
		connect_death_and_screen_signals(enemy)
		emit_signal("respawned")
		Event.emit_signal("respawned",spawn)
		_demo_record_respawn(enemy)

func _demo_record_respawn(enemy: Watched) -> void:
	var ds = get_node_or_null("/root/DemoSystem")
	if not ds or not ds.is_recording():
		return
	var idx := enemies.find(enemy)
	if idx >= 0:
		ds.emit_game_event(self, "respawn", {"idx": idx, "list": "enemies"})
		return
	idx = starter_enemies.find(enemy)
	if idx >= 0:
		ds.emit_game_event(self, "respawn", {"idx": idx, "list": "starters"})

func demo_execute(data: Dictionary) -> void:
	var idx := int(data.get("idx", -1))
	var list_name: String = data.get("list", "enemies")
	if list_name == "enemies":
		if idx >= 0 and idx < enemies.size():
			respawn(enemies[idx])
	elif list_name == "starters":
		if idx >= 0 and idx < starter_enemies.size():
			respawn(starter_enemies[idx])

func activate():
	active = true

func deactivate():
	despawn_all()
	destroy_extras()
	active = false

func despawn_all():
	print_debug(name + ": Despawning All")
	for each in enemies:
		if is_instance_valid(each.object):
			despawn(each)

func destroy_extras():
	for each in extras:
		if is_instance_valid(each):
			if "destroy" in each:
				each.destroy()
			else:
				each.queue_free()

func mark_all_for_respawn():
	for each in enemies:
		mark_for_respawn(each,minimum_death_duration)
	for each in starter_enemies:
		mark_for_respawn(each,minimum_death_duration)

var deactivated_by_checkpoints := false

func on_checkpoint_start(checkpoint : CheckpointSettings):
	print_debug(name + ": on_checkpoint_start")
	var ds = get_node_or_null("/root/DemoSystem")
	if ds and ds.is_demo_playing():
		return  # Skip checkpoint handling during demo playback
	if checkpoint.id > next_checkpoint:
		print_debug(name + ": Deactivating based on Checkpoint")
		deactivate()
		deactivated_by_checkpoints = true
	elif checkpoint.id == next_checkpoint -1:
		print_debug(name + ": Spawning Starters")
		call_deferred("spawn_starter_enemies")

func first_checkpoint_spawn():
	if not deactivated_by_checkpoints:
		var checkpoint = 0
		if checkpoint == next_checkpoint -1:
			call_deferred("spawn_starter_enemies")

func spawn_starter_enemies():
	for each in starter_enemies:
		respawn(each)


class Watched:
	var object : Enemy
	var position : Vector2
	var parent : Node
	var scene : PackedScene
	var outside_timer : Timer
	var notifier_size : Rect2

	func _init(_object : Node2D) -> void:
		object = _object
		position = _object.global_position
		parent = _object.get_parent()
		scene = PackedScene.new()
		notifier_size = _object.get_visibility_notifier().rect
		scene.pack(_object) # warning-ignore:return_value_discarded
