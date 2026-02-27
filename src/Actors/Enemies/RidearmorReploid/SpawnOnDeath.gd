extends Node
onready var character: KinematicBody2D = $".."

export var ridearmor := true
export var spawn : PackedScene

func _ready() -> void:
	character.listen("zero_health",self,"instantiate")

func instantiate() -> void:
	call_deferred("instantiate_spawn")

func instantiate_spawn() -> void:
	var instance = spawn.instance()
	get_tree().current_scene.add_child(instance,true)
	instance.set_global_position(character.global_position) 
	instance.set_direction(character.get_facing_direction())
	character.emit_spawned_child(instance,false)
	if ridearmor:
		instance.get_node("Eject")._Setup()
		instance.never_player_mounted = true
		instance.current_health = 0
		
