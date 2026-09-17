extends Movement
class_name Death

onready var explosions = $"X Death Particles"
onready var background = $background_light
onready var collision: = get_parent().get_node("CollisionShape2D")
onready var collision_shape_2d: CollisionShape2D = $"../Enemy Collision Detector/CollisionShape2D"
onready var dash_shape: CollisionShape2D = $"../Enemy Collision Detector/DashShape"

var alpha: float = 0.0
var emitted_sound: bool = false
var game_paused: bool = false
var death_location: Vector2
var kids_mode_death: bool = false


func play_sound_on_initialize():
	pass

func _ready() -> void :
	character.listen("zero_health", self, "_on_zero_health")

func _Setup() -> void :
	kids_mode_death = CharacterManager.game_mode <= -1
	if not kids_mode_death:
		Event.emit_signal("player_death")
	death_location = global_position
	background.set_scale(Vector2(100, 40))
	GameManager.pause("PlayerDeath")
	emitted_sound = false
	game_paused = true
	alpha = 0
	if not kids_mode_death:
		character.current_health = 0
	character.deactivate()
	character.remove_invulnerability_shader()
	character.stop_all_movement()
	call_deferred("disable_collision")
	background.material.set_shader_param("Alpha", alpha)
	explosions.visible = true
	Log("finished Setup")

func disable_collision() -> void :
	collision.disabled = true
	collision_shape_2d.disabled = true
	dash_shape.disabled = true

func enable_collision() -> void :
	collision.disabled = false
	collision_shape_2d.disabled = false
	dash_shape.disabled = false

func _Update(delta):
	character.disable_floor_snap()
	character.global_position = death_location
	if timer > 1.5:
		alpha += delta * 2
		background.material.set_shader_param("Alpha", alpha)
	if timer > 5:
		background.set_scale(Vector2(400, 160))
		GameManager.on_death()

func _physics_process(delta: float) -> void :
	if not executing:
		return
	if game_paused:
		timer += delta
		if timer > 0.5 and emitted_sound == false:
			GameManager.unpause("PlayerDeath")
			character.animatedSprite.visible = false
			play_sound(sound, false)
			emitted_sound = true
			game_paused = false
			if not kids_mode_death:
				background.visible = true
			var position_in_camera = GameManager.camera.get_nearest_position_inside_camera(global_position)
			if position_in_camera != global_position:
				death_location = position_in_camera
			else:
				explosions.emit()
	elif kids_mode_death:
		timer += delta
		character.disable_floor_snap()
		character.global_position = death_location
		if timer > 2:
			_kids_mode_revive()

func _kids_mode_revive() -> void :
	explosions.stop()
	explosions.visible = false
	character.current_health = character.max_health
	character.set_invulnerability(3.0)
	EndAbility()
	character._kids_mode_void_rescue()
	call_deferred("enable_collision")
	call_deferred("_trigger_intro")

func _trigger_intro() -> void :
	character.animatedSprite.visible = true
	GameManager.emit_intro_signal()
	var intro_started = character.is_executing("Intro")
	if not intro_started:
		character.activate()

func _StartCondition() -> bool:
	return false

func _EndCondition() -> bool:
	return false

func _on_zero_health() -> void :
	if CharacterManager.game_mode <= -1:
		return
	if active and not executing:
		ExecuteOnce()

func is_high_priority() -> bool:
	return true
