extends AbilityUser
class_name Character

onready var wallcheck_left: = $_raycasts.get_node("Wallcheck Left")
onready var wallcheck_left2: = $_raycasts.get_node("Wallcheck Left2")
onready var wallcheck_left3: = $_raycasts.get_node("Wallcheck Left3")
onready var wallcheck_right: = $_raycasts.get_node("Wallcheck Right")
onready var wallcheck_right2: = $_raycasts.get_node("Wallcheck Right2")
onready var wallcheck_right3: = $_raycasts.get_node("Wallcheck Right3")
onready var cast_left = [wallcheck_left, wallcheck_left2, wallcheck_left3]
onready var cast_right = [wallcheck_right, wallcheck_right2, wallcheck_right3]

onready var walljumpcast_left: = $_raycasts.get_node("WallJumpCast Left")
onready var walljumpcast_left2: = $_raycasts.get_node("WallJumpCast Left2")
onready var walljumpcast_left3: = $_raycasts.get_node("WallJumpCast Left3")
onready var walljumpcast_right: = $_raycasts.get_node("WallJumpCast Right")
onready var walljumpcast_right2: = $_raycasts.get_node("WallJumpCast Right2")
onready var walljumpcast_right3: = $_raycasts.get_node("WallJumpCast Right3")
onready var jumpcast_left = [walljumpcast_left, walljumpcast_left2, walljumpcast_left3]
onready var jumpcast_right = [walljumpcast_right, walljumpcast_right2, walljumpcast_right3]
onready var low_jumpcasts = [walljumpcast_left3, walljumpcast_right3]

onready var collisor: = $"Enemy Collision Detector".get_node("CollisionShape2D")

onready var shot_position: = get_node("Shot Position")

var listening_to_inputs: bool = true
var emitted_land: bool = false
var last_time_dashed: float = 0.0
var last_wall_at_position: Vector2
var full_alpha: bool = true
var set_alert: bool = false
var is_shooting: bool = false
var colors: Array = []
var debug_position_y: float = 0.0
var should_die_to_spikes: bool = true
var spike_invincibility: bool = false

# Kids mode variables
var kids_safe_position: Vector2 = Vector2.ZERO
var kids_safe_position_set: bool = false
var kids_ground_timer: float = 0.0
var kids_wall_hold_direction: int = 0
var kids_cliff_dash_available: bool = false
const KIDS_SAFE_GROUND_TIME: float = 0.5

signal headbump
signal land
signal cutscene_deactivate
signal ride(prop)
signal eject(prop)
signal force_movement
signal stop_forced_movement(forcer)
signal melee_hit(enemy)
signal jump


func _ready() -> void :
	connect_cutscene_events()
	if CharacterManager.game_mode <= -1:
		call_deferred("_init_kids_safe_position")
		Event.listen("door_transition_end", self, "_on_kids_transition")
		Event.listen("moved_player_to_checkpoint", self, "_on_kids_transition")

func _init_kids_safe_position() -> void :
	kids_safe_position = global_position
	kids_safe_position_set = true

func connect_cutscene_events() -> void :
	Event.listen("end_cutscene_start", self, "deactivate")
	Event.listen("cutscene_start", self, "stop_listening_to_inputs")
	Event.listen("stage_rotate", self, "stop_listening_to_inputs")
	Event.listen("cutscene_over", self, "cutscene_activate")

func _process(_delta: float) -> void :
	update_facing_direction()

func _physics_process(delta: float) -> void :
	var actual_delta = delta
	if time_stop_active:
		actual_delta = GameManager.true_delta
	check_if_should_set_alpha_to_1()
	check_for_headbump()
	check_for_land(actual_delta)
	check_for_low_health()
	check_for_dash()
	if CharacterManager.game_mode <= -1:
		_update_kids_wall_hold()
		_update_kids_cliff_dash()
		_check_kids_out_of_bounds()
	if has_control() and IGT.should_run:
		IGT.in_game_timer += actual_delta
		IGT.stage_timer += actual_delta

func cutscene_activate() -> void :
	if not is_executing("Ride"):
		activate()






func spike_touch() -> void :
	if should_instantly_die() and not is_invulnerable() and not spike_invincibility:
		if not should_die_to_spikes:
			emit_signal("damage", 1, self)
			return
		emit_signal("zero_health")

func lava_touch() -> void :
	if should_instantly_die() and not spike_invincibility:
		if not should_die_to_spikes:
			if not is_invulnerable():
				emit_signal("damage", 1, self)
			return
		emit_signal("zero_health")

func void_touch() -> void :
	emit_signal("zero_health")

func should_instantly_die() -> bool:
	return not is_executing("Ride")

func ride(ride: Node) -> void :
	emit_signal("ride", ride)

func eject(ride: Node) -> void :
	emit_signal("eject", ride)

func force_movement(_forcer = null) -> void :
	emit_signal("force_movement")
	
func stop_forced_movement(forcer = null) -> void :
	emit_signal("stop_forced_movement", forcer)

func activate() -> void :
	start_listening_to_inputs()
	Log("Active")

func deactivate() -> void :
	stop_listening_to_inputs()
	stop_shot()
	Log("not active")

func stop_shot() -> void :
	for ability in executing_moves:
		if ability.name == "Shot":
			ability.EndAbility()

func make_invisible() -> void :
	Log("invisible")
	animatedSprite.visible = false

func make_visible() -> void :
	Log("visible")
	animatedSprite.visible = true

func stop_listening_to_inputs() -> void :
	Log("not listening to inputs")
	listening_to_inputs = false

func cutscene_deactivate() -> void :
	stop_listening_to_inputs()
	emit_signal("cutscene_deactivate")
	if GameManager.player.ride:
		GameManager.player.ride.stop_listening_to_inputs()

func start_listening_to_inputs() -> void :
	if GameManager.get_state() != "Cutscene":
		Log("listening to inputs")
		listening_to_inputs = true

func get_executing_moves() -> void :
	for move in moveset:
		if move.CheckForPressed():
			try_execution(move)

func has_control() -> bool:
	if listening_to_inputs:
		return true


	return false

func check_for_dash() -> void :
	if get_action_just_pressed("dash"):
		Event.emit_signal("input_dash")

func check_if_should_set_alpha_to_1() -> void :
	if invulnerability < 0 and not has_invulnerability_from_skills() and not full_alpha:
		remove_invulnerability_shader()
		full_alpha = true

func has_invulnerability_from_skills() -> bool:
	return toggleable_invulnerabilities.size() > 0

func check_for_low_health() -> void :
	if has_health():
		if is_low_health() and not set_alert:
			animatedSprite.material.set_shader_param("Alert", 1)
			set_alert = true
		elif not is_low_health() and set_alert:
			animatedSprite.material.set_shader_param("Alert", 0)
			set_alert = false

func is_invulnerable() -> bool:
	if not active:
		return true
	else:
		return .is_invulnerable()

func add_invulnerability(ability_name) -> void :
	if not ability_name in toggleable_invulnerabilities:
		toggleable_invulnerabilities.append(ability_name)
		apply_invulnerability_shader()

func remove_invulnerability(ability_name) -> void :
	toggleable_invulnerabilities.erase(ability_name)
	if not is_invulnerable():
		remove_invulnerability_shader()

func apply_invulnerability_shader() -> void :
		animatedSprite.material.set_shader_param("Alpha", 0.5)
		full_alpha = false

func remove_invulnerability_shader() -> void :
		animatedSprite.material.set_shader_param("Alpha", 1)
		full_alpha = true

func check_for_headbump() -> void :
	if is_on_ceiling():
		emit_signal("headbump")

func check_for_land(delta: float) -> void :
	if is_on_floor():
		if not emitted_land:
			emitted_land = true
			time_since_on_floor = 0
			emit_signal("land")
		if CharacterManager.game_mode <= -1:
			if get_conveyor_belt_speed() == 0:
				kids_ground_timer += delta
				if kids_ground_timer >= KIDS_SAFE_GROUND_TIME:
					var grounded = _is_fully_grounded()
					if grounded:
						if kids_safe_position != global_position:
							print_debug("[KIDS] Safe position saved: ", global_position)
						kids_safe_position = global_position
						kids_safe_position_set = true
					elif kids_ground_timer < KIDS_SAFE_GROUND_TIME + 0.1:
						print_debug("[KIDS] NOT grounded at: ", global_position)
			else:
				kids_ground_timer = 0.0
	else:
		time_since_on_floor = time_since_on_floor + delta
		if emitted_land:
			emitted_land = false
		if CharacterManager.game_mode <= -1:
			kids_ground_timer = 0.0

func is_colliding_with_wall() -> int:
	for cast in cast_right:
		if check_for_normal(cast, - 1):
			return 1
	for cast in cast_left:
		if check_for_normal(cast, 1):
			return - 1
	return 0

func is_colliding_with_wall_except_feet() -> int:
	var right = [wallcheck_right, wallcheck_right2]
	var left = [wallcheck_left, wallcheck_left2]
	for cast in right:
		if check_for_normal(cast, - 1):
			return 1
	for cast in left:
		if check_for_normal(cast, 1):
			return - 1
	return 0

func is_colliding_with_both_walls() -> bool:
	var collision = 0
	for cast in cast_right:
		if check_for_normal(cast, - 1):
			collision += 1
	for cast in cast_left:
		if check_for_normal(cast, 1):
			collision += 1
	return collision == 2

func is_in_reach_for_walljump() -> int:
	for cast in jumpcast_right:
		if check_for_normal(cast, - 1):
			return 1
	for cast in jumpcast_left:
		if check_for_normal(cast, 1):
			return - 1
	return 0

func check_for_normal(cast, normal: int, angle_range: float = 0.25) -> bool:
	return cast.is_colliding() and cast.get_collision_normal().x > normal - angle_range and cast.get_collision_normal().x < normal + angle_range

func get_pressed_axis() -> int:
	var axis = 0
	if get_action_pressed("move_left"):
		axis = axis - 1
	if get_action_pressed("move_right"):
		axis = axis + 1
	return axis

func get_just_pressed_axis() -> int:
	var axis = 0
	if has_just_pressed_left():
		axis = axis - 1
	if has_just_pressed_right():
		axis = axis + 1
	return axis

func has_just_pressed_left() -> bool:
	return get_action_just_pressed("move_left")

func has_just_pressed_right() -> bool:
	return get_action_just_pressed("move_right")

func set_animation_layer(layer):
	if animatedSprite.frames != layer:
		animatedSprite.frames = layer

func get_animation_layer() -> String:
	return animatedSprite.frames

func send_debug_info() -> String:
	var text: = ""
	text += print_position()
	text += print_speed()
	text += print_states()
	return text

func print_hp() -> String:
	var text: = "HP:"
	for unit in current_health:
		text += "l"
	return text

func print_position() -> String:
	var x_pos = stepify(position.x, 0.01)
	var y_pos = stepify(position.y, 0.01)
	return "X:" + str(x_pos) + "\nY:" + str(y_pos)

func print_speed() -> String:
	var x_speed = stepify(final_velocity.x, 0.1)
	var y_speed = stepify(final_velocity.y, 0.1)
	return "\nH Spd:" + str(x_speed) + "\nV Spd:" + str(y_speed)

func print_states() -> String:
	var text: = ""
	var total_states: = ""
	for state in moveset:
		if state.executing:
			text += state.name.left(1)
			if total_states.length() > 0:
				total_states += ", "
			total_states += state.name
		else:
			text += "."
	var final_text: = "\nState: " + str(total_states) + "\n" + text
	return final_text

var analog_deadzone = 0.1
func get_left_analog_direction():
	if listening_to_inputs:
		var raw_x = Input.get_joy_axis(0, 0)
		var raw_y = Input.get_joy_axis(0, 1)

		if abs(raw_x) < analog_deadzone:
			raw_x = 0.0
		if abs(raw_y) < analog_deadzone:
			raw_y = 0.0

		var analog_direction = Vector2(-raw_x, raw_y)
		if analog_direction.length() > analog_deadzone:
			analog_direction = analog_direction.normalized()
		else:
			analog_direction = Vector2.ZERO

		return analog_direction
	else:
		return false

func get_right_analog_direction():
	if listening_to_inputs:
		InputMap.action_set_deadzone("analog_left", analog_deadzone)
		InputMap.action_set_deadzone("analog_right", analog_deadzone)
		InputMap.action_set_deadzone("analog_up", analog_deadzone)
		InputMap.action_set_deadzone("analog_down", analog_deadzone)

		var right_stick_x = Input.get_action_strength("analog_left") - Input.get_action_strength("analog_right")
		var right_stick_y = Input.get_action_strength("analog_down") - Input.get_action_strength("analog_up")
		
		var analog_direction = Vector2(right_stick_x, right_stick_y)
		analog_direction = analog_direction.normalized()
			
		return analog_direction
	return Vector2.ZERO

func get_action_just_pressed(action) -> bool:
	if listening_to_inputs:
		return Input.is_action_just_pressed(action)
	return false

func get_action_pressed(action) -> bool:
	if listening_to_inputs:
		if CharacterManager.game_mode <= -1 and kids_wall_hold_direction != 0:
			if action == "move_right" and kids_wall_hold_direction == 1:
				return true
			if action == "move_left" and kids_wall_hold_direction == -1:
				return true
		return Input.is_action_pressed(action)
	return false

func get_action_strength(action) -> float:
	if listening_to_inputs:
		return Input.get_action_strength(action)
	return 0.0

func get_action_just_released(action) -> bool:
	if listening_to_inputs:
		return Input.is_action_just_released(action)
	return false

func hit(_body: Node) -> void :
	emit_signal("melee_hit", _body)

# Kids mode functions
func _is_fully_grounded() -> bool:
	var space = get_world_2d().direct_space_state
	var start_y = global_position.y
	var end_y = global_position.y + 20
	var half_width = 5.0
	var left_from = Vector2(global_position.x - half_width, start_y)
	var left_to = Vector2(global_position.x - half_width, end_y)
	var right_from = Vector2(global_position.x + half_width, start_y)
	var right_to = Vector2(global_position.x + half_width, end_y)
	var left_hit = space.intersect_ray(left_from, left_to, [self], 1)
	var right_hit = space.intersect_ray(right_from, right_to, [self], 1)
	return not left_hit.empty() and not right_hit.empty()

func _kids_mode_void_rescue() -> void :
	if kids_safe_position_set:
		global_position = kids_safe_position
	elif GameManager.checkpoint:
		global_position = GameManager.checkpoint.respawn_position
	current_health = max_health
	velocity = Vector2.ZERO
	bonus_velocity = Vector2.ZERO
	set_vertical_speed(0)
	set_horizontal_speed(0)
	snap_vector = snap_direction * snap_length
	set_invulnerability(3.0)
	emitted_zero_health = false
	spike_invincibility = false
	kids_wall_hold_direction = 0
	kids_cliff_dash_available = false
	kids_ground_timer = 0.0
	var crush = get_node_or_null("CrushCheck")
	if crush:
		crush.set_physics_process(true)

func _update_kids_wall_hold() -> void :
	if is_on_floor():
		kids_wall_hold_direction = 0
		return
	if is_invulnerable():
		kids_wall_hold_direction = 0
		return
	if kids_wall_hold_direction != 0:
		var opposite_action = "move_left" if kids_wall_hold_direction == 1 else "move_right"
		if Input.is_action_just_pressed(opposite_action):
			kids_wall_hold_direction = 0
			return
	var wall_dir = is_colliding_with_wall()
	if wall_dir != 0 and not is_on_floor():
		kids_wall_hold_direction = wall_dir

func _update_kids_cliff_dash() -> void :
	if is_on_floor():
		if _detect_cliff_edge():
			kids_cliff_dash_available = true
		else:
			kids_cliff_dash_available = false
		return
	if kids_cliff_dash_available:
		if time_since_on_floor > 0.4:
			kids_cliff_dash_available = false
			return
		if get_action_just_pressed("jump"):
			kids_cliff_dash_available = false
			for move in moveset:
				if move is DashJump:
					move.ExecuteOnce()
					break

func _detect_cliff_edge() -> bool:
	if abs(velocity.x) < 10:
		return false
	var space = get_world_2d().direct_space_state
	var dir = 1 if facing_right else -1
	var ahead_x = global_position.x + dir * 14
	var ray_from = Vector2(ahead_x, global_position.y)
	var ray_to = Vector2(ahead_x, global_position.y + 20)
	var hit = space.intersect_ray(ray_from, ray_to, [self], 1)
	return hit.empty()

func _check_kids_out_of_bounds() -> void :
	if not active or not has_health():
		return
	var cam = GameManager.camera
	if cam and global_position.y > cam.custom_limits_bot + 200:
		_do_kids_rescue()

func _do_kids_rescue() -> void :
	_kids_mode_void_rescue()
	animatedSprite.visible = true
	GameManager.emit_intro_signal()
	if not is_executing("Intro"):
		activate()

func _on_kids_transition(_arg = null) -> void :
	call_deferred("_deferred_kids_safe_update")

func _deferred_kids_safe_update() -> void :
	kids_safe_position = global_position
	kids_safe_position_set = true
	kids_ground_timer = 0.0
