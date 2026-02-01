extends Node3D

func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	pass


func _on_trigger_zone_body_entered(body: Node3D) -> void:
	print("collision")
	get_tree().change_scene_to_file("res://Scenes/FirstJumpscare.tscn")
