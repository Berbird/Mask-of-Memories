extends Area2D

@export_file("*.tscn") var target_scene_path
@export var return_offset: Vector2 = Vector2(0, 50)
@export var memory_id: String = ""

func _ready():
	if memory_id != "" and GameManager.get_flag(memory_id):
		queue_free()
		return

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body is CharacterBody2D:
		if memory_id != "":
			GameManager.set_flag(memory_id, true)
		
		call_deferred("set_monitoring", false)
		
		if body_entered.is_connected(_on_body_entered):
			body_entered.disconnect(_on_body_entered)
		
		GameManager.last_player_position = body.global_position + return_offset
		GameManager.is_returning_from_memory = true
		
		if target_scene_path:
			get_tree().change_scene_to_file(target_scene_path)
		else:
			print("Target scene not found")
