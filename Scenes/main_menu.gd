extends Control

func _input(event):
	if event.is_action_pressed("ui_accept"):
		start_game()

func start_game():
	var error = get_tree().change_scene_to_file("res://Scenes/Basement.tscn")
	if error != OK:
		print("Sahne yuklenirken hata olustu")
