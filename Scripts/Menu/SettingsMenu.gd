extends PopupPanel

# Displays current controls on the buttons
func _ready():
	pass

func _on_exit_pressed():
	get_tree().quit()

func _on_return_to_menu_pressed():
	get_tree().reload_current_scene()

func _on_check_box_toggled(button_pressed):
	GameManager.fpsCounter = button_pressed
