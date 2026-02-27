extends NinePatchRect

onready var texture_progress: TextureProgress = $textureProgress
var bar_tween: SceneTreeTween
var showing := false
var sized := false

func _ready() -> void:
	Event.listen("ridearmor_activate",self,"move_in")
	Event.listen("ridearmor_deactivate",self,"move_out")

func move_in() -> void:
	if showing:
		return
	showing = true
	sized = false
	if bar_tween:
		bar_tween.kill()
	bar_tween = create_tween()
	bar_tween.tween_property(self,"rect_position:x",23.0,0.2)

func move_out() -> void:
	if not showing:
		return
	showing = false
	if bar_tween:
		bar_tween.kill()
	bar_tween = create_tween()
	bar_tween.tween_property(self,"rect_position:x",-14.0,0.2)

func resize_bar(max_health: float) -> void:
	var bar_pos = 56 - (max_health - 16) * 2
	var bar_size = 52 + (max_health - 16) * 2
	rect_position.y = bar_pos
	rect_size.y = bar_size
	sized = true

func _process(_delta: float) -> void:
	if not is_instance_valid(GameManager.player):
		return
	var riding = is_instance_valid(GameManager.player.ride)
	if riding:
		var ride = GameManager.player.ride
		if not sized:
			resize_bar(ride.max_health)
		texture_progress.value = ceil(ride.current_health)
		if not showing:
			move_in()
	elif showing:
		move_out()
