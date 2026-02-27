extends Particles2D


func _ready() -> void :
	pass


func _on_sandstorm_detector_body_entered(_body: Node) -> void :
	emitting = true


func _on_sandstorm_detector_body_exited(_body: Node) -> void :
	emitting = false
