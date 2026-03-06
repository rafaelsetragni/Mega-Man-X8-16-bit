extends ConfirmButton


func _ready() -> void:
	._ready()
	if menu_path:
		menu = get_node(menu_path)
		connect_lock_signals(menu)


func action() -> void:
	menu.on_voltar_confirmed()
