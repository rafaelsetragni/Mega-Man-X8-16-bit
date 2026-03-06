extends NinePatchRect

onready var weapon_icon: TextureRect = $"../WeaponIcon"
onready var ammo_bar: TextureProgress = $textureProgress

var weapon
var _riding := false

signal displayed(weapon)
signal hidden


func display(current_weapon) -> void :
	if is_exception(current_weapon):
		weapon = null
		hide()
		return
	weapon = current_weapon
	var icon = weapon.weapon.icon
	var palette = weapon.weapon.palette
	weapon_icon.texture.atlas = icon
	ammo_bar.material.set_shader_param("palette", palette)
	ammo_bar.value = get_bar_value()
	if _riding:
		return
	show()
	emit_signal("displayed", current_weapon)

func is_exception(current_weapon) -> bool:
	if "Buster" in current_weapon.name:
		return true
	if "Pistol" in current_weapon.name:
		return true
	if "Saber" in current_weapon.name:
		return true
	return false

func _process(_delta: float) -> void :
	if weapon:
		ammo_bar.value = get_bar_value()
		if weapon.current_ammo > 0 and weapon.current_ammo < 1:
			ammo_bar.value = 1

func get_bar_value() -> float:
	return inverse_lerp(0.0, weapon.max_ammo, weapon.current_ammo) * 28

func _ready() -> void :
	Event.listen("changed_weapon", self, "display")
	Event.listen("new_camera_focus", self, "_on_camera_focus")
	Event.listen("ridearmor_activate", self, "_on_ride_activate")
	Event.listen("ridearmor_deactivate", self, "_on_ride_deactivate")
	hide()

func _on_camera_focus(new_focus) -> void :
	if new_focus == GameManager.player:
		_riding = false
		if GameManager.player and GameManager.player.has_method("get_current_weapon"):
			var current = GameManager.player.get_current_weapon()
			if current:
				display(current)
	else:
		_riding = true
		hide()

func _on_ride_activate() -> void :
	_riding = true
	hide()

func _on_ride_deactivate() -> void :
	_riding = false

func hide() -> void :
	weapon_icon.visible = false
	visible = false
	emit_signal("hidden")

func show() -> void :
	weapon_icon.visible = true
	visible = true
