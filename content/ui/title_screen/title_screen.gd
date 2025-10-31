extends CanvasLayer


func _input(event: InputEvent) -> void:
	if event.is_pressed():
		GSceneAdmin.switch_scene("MainMenu")
