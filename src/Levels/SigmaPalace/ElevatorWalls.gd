extends Sprite

onready var tween: = TweenController.new(self, false)

export  var speed: = 80

func _ready() -> void :
	region_rect.position.y = CharacterManager.elevator_walls_y
	descent()

func descent():
	tween.reset()
	var target_rect = Rect2(region_rect.position.x, region_rect.position.y + speed, region_rect.size.x, region_rect.size.y)
	tween.attribute("region_rect", target_rect, 1.0)
	Tools.timer(1.0, "descent", self)
	
