extends Node

var last_message
var last_caller

func msg(msg, caller = null, _bool: = true) -> void :
	if _bool:
		if not last_message == str(msg):
			var _message_to_print
			if caller is String and last_caller != caller:
				_message_to_print = str(caller + ": " + str(msg))
				last_caller = caller
			elif caller != null and last_caller != caller.name:
				_message_to_print = str(caller.name + ": " + str(msg))
				last_caller = caller.name
			else:
				_message_to_print = "Log: " + str(msg)


			last_message = str(msg)
