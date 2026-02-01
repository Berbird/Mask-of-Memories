extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = create_tween()
	tween.tween_property($CanvasModulate, "color", Color(0.976, 0.948, 0.8, 0.102), 0.7).set_trans(Tween.TRANS_CUBIC)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	print("sfdsa")
	var dialogue = get_tree().get_first_node_in_group("DialogueSystem")
	if dialogue:
		dialogue.load_dialogue("res://Dialogue/rooftop_happy.json")
		await dialogue.dialogue_finished
		var tween = create_tween()
		tween.tween_property($CanvasModulate, "color", Color(0.0, 0.0, 0.0, 0.102), 2).set_trans(Tween.TRANS_CUBIC)
		await get_tree().create_timer(2).timeout
		get_tree().change_scene_to_file("res://Scenes/MemoryLane.tscn")
