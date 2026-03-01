extends CameraMode

var _prev_clamp: String = ""

func update(_delta) -> Vector2:
	var new_position: = camera.global_position
	if x_axis:
		if camera.is_constrained_horizontally():
			_log("constrained_x")
			new_position.x = camera.get_boundary_position_right()
			return new_position
		if _prev_clamp == "constrained_x":
			_log("")
		new_position.x = get_target().x
		if camera.is_over_right_limit():
			_log("over_right")
			new_position.x = camera.get_boundary_position_right()
		elif camera.is_over_left_limit():
			_log("over_left")
			new_position.x = camera.get_boundary_position_left()
		elif _prev_clamp in ["over_right", "over_left"]:
			_log("")
	else:
		if camera.is_constrained_vertically():
			_log("constrained_y")
			new_position.y = camera.get_boundary_position_bot()
			return new_position
		if _prev_clamp == "constrained_y":
			_log("")
		new_position.y = get_target().y
		if camera.is_over_top_limit():
			_log("over_top")
			new_position.y = camera.get_boundary_position_top()
		elif camera.is_over_bottom_limit():
			_log("over_bot")
			new_position.y = camera.get_boundary_position_bot()
		elif _prev_clamp in ["over_top", "over_bot"]:
			_log("")
	return new_position

func _log(state: String) -> void:
	if state == _prev_clamp:
		return
	_prev_clamp = state
	match state:
		"":
			print_debug("[CAM] Follow free | cam:", camera.global_position, " | player:", camera.player_pos())
		"constrained_x":
			print_debug("[CAM] Constrained X | L:", camera.custom_limits_left, " R:", camera.custom_limits_right, " (width:", camera.custom_limits_right - camera.custom_limits_left, ") | cam:", camera.global_position, " | player:", camera.player_pos())
		"over_right":
			print_debug("[CAM] Over RIGHT | R:", camera.custom_limits_right, " | cam:", camera.global_position, " | player:", camera.player_pos())
		"over_left":
			print_debug("[CAM] Over LEFT | L:", camera.custom_limits_left, " | cam:", camera.global_position, " | player:", camera.player_pos())
		"constrained_y":
			print_debug("[CAM] Constrained Y | T:", camera.custom_limits_top, " B:", camera.custom_limits_bot, " (height:", camera.custom_limits_bot - camera.custom_limits_top, ") | cam:", camera.global_position, " | player:", camera.player_pos())
		"over_top":
			print_debug("[CAM] Over TOP | T:", camera.custom_limits_top, " | cam:", camera.global_position, " | player:", camera.player_pos())
		"over_bot":
			print_debug("[CAM] Over BOTTOM | B:", camera.custom_limits_bot, " | cam:", camera.global_position, " | player:", camera.player_pos())

func is_valid_position() -> bool:

	return false

func is_limited_horizontally() -> bool:
	if camera.is_over_right_limit():
		return true
	elif camera.is_over_left_limit():
		return true
	return false

func is_limited_vertically() -> bool:
	if camera.is_over_bottom_limit():
		return true
	elif camera.is_over_top_limit():
		return true
	return false
