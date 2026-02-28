extends AttackAbility
class_name BeePatrol

export var area := 12
export var travel_time := 0.5
export var rest_duration := 0.5
export (NodePath) var ability_who_updates_patrol_area
var rest_time := 0.0
var patrol_position := Vector2.ZERO
var tween : SceneTreeTween
var _last_dest := Vector2.ZERO
var _last_rest := 0.0


func _ready() -> void:
	update_patrol_position(self)
	Event.connect("stage_rotate_end",self,"_Setup")
	if ability_who_updates_patrol_area:
	# warning-ignore:return_value_discarded
		get_node(ability_who_updates_patrol_area).connect("ability_end",self,"update_patrol_position")

func _Setup() -> void:
	attack_stage = 0
	timer = 0
	_last_dest = patrol_position + Vector2(random_value(), random_value())
	handle_turn(_last_dest)
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.tween_property(character, "global_position", _last_dest, travel_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_last_rest = rest_duration + randf()
	rest_time = _last_rest


func _demo_setup_data() -> Dictionary:
	return {"dx": _last_dest.x, "dy": _last_dest.y, "rt": _last_rest}


func _demo_apply_setup(data: Dictionary) -> void:
	attack_stage = 0
	timer = 0
	var dest := Vector2(float(data["dx"]), float(data["dy"]))
	handle_turn(dest)
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.tween_property(character, "global_position", dest, travel_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	rest_time = float(data["rt"])

func handle_turn(r_destination : Vector2) -> void:
	if r_destination.x > global_position.x:
		set_direction(1)
	else:
		set_direction(-1)
	

func _Update(_delta) -> void:
	if attack_stage == 0 and timer > travel_time:
		play_animation("idle")
		next_attack_stage()

func _Interrupt() -> void:
	tween.kill()

func update_patrol_position(_ability = null) -> void:
	patrol_position = global_position

func _EndCondition() -> bool:
	return timer > rest_time

func random_value() -> int:
	return randi() % area*2 + -area 

func random_rest_time() -> void:
	rest_time = rest_duration + randf()
