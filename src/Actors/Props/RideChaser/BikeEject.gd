extends Ability

func _StartCondition() -> bool:
	if character.listening_to_inputs:
		if Input.is_action_just_pressed("jump"):
			return true
	return false

#func _Setup():
	#character.deactivate()
