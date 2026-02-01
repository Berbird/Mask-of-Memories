extends CharacterBody2D

# Assign your audio file in the Inspector or here via code
@onready var sfx_player = $"../AudioStreamPlayer2D"

func _ready() -> void:
	if sfx_player.stream:
		sfx_player.play()
		print("JUMPSCARE: Audio Playing")
	else:
		push_error("JumpscareSFX is missing an AudioStream!")

	# 2. Optional: Trigger dialogue after the scream
	await trigger_glitch_scare()
	
	get_viewport().get_camera_2d().offset = Vector2(0, 0)
	get_tree().change_scene_to_file("res://Scenes/MemoryLane.tscn")

func trigger_scare_dialogue():
	# Finds the dialogue system to add context to the scare
	var dialogue = get_tree().get_first_node_in_group("DialogueSystem")
	if dialogue:
		dialogue.load_dialogue("res://Dialogue/memory_1.json")
		await dialogue.dialogue_finished
		
func trigger_glitch_scare():
	await apply_camera_shake(4)
	# 1. Flash the entity rapidly to make it look unstable
	for i in range(10):
		self.visible = !self.visible
		await apply_camera_shake(4)
		# Randomize pitch for a "distorted" scream effect
		sfx_player.pitch_scale = randf_range(0.5, 1.5)
		await get_tree().create_timer(0.05).timeout
	self.show() # Ensure it stays visible at the end
	# 2. Add a heavy camera shake (See Step 2 below)
	await apply_camera_shake(10)
	await trigger_scare_dialogue()
	
func apply_camera_shake(num):
	var camera = get_viewport().get_camera_2d()
	if camera:
		var original_pos = camera.offset
		for i in range(num):
			camera.offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
			await get_tree().create_timer(0.02).timeout
		camera.offset = original_pos
