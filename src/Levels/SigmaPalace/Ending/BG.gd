extends Sprite

onready var tween: = TweenController.new(self, false)

export  var duration: = 80

func _ready() -> void :
	ascent()

func ascent():
	tween.create(Tween.EASE_OUT, Tween.TRANS_SINE)
	var target_rect = Rect2(region_rect.position.x, 224, region_rect.size.x, region_rect.size.y)
	tween.add_attribute("region_rect", target_rect, 120.0)
	tween.attribute("modulate", Color.white, 160.0)
	


