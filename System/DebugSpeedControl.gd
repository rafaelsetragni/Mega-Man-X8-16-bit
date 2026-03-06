extends Node

var _cooldown: float = 0.0

func _process(delta: float) -> void :
	if _cooldown > 0:
		_cooldown -= delta / Engine.time_scale
	if _cooldown <= 0:
		if Input.is_key_pressed(KEY_COMMA):
			Engine.time_scale = max(0.01, Engine.time_scale * 0.5)
			print("[DEBUG-SPEED] time_scale = ", Engine.time_scale)
			_cooldown = 0.3
		elif Input.is_key_pressed(KEY_PERIOD):
			Engine.time_scale = min(1.0, Engine.time_scale * 2.0)
			print("[DEBUG-SPEED] time_scale = ", Engine.time_scale)
			_cooldown = 0.3
