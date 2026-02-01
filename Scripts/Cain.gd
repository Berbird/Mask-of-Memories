extends CharacterBody2D

const SPEED = 50
var current_direction = "front"

@onready var anim_sprite = $AnimatedSprite2D

func _ready():
	if GameManager.is_returning_from_memory:
		global_position = GameManager.last_player_position
		GameManager.is_returning_from_memory = false


func _input(event):
	if event.is_action_pressed("ui_accept"):
		if !GameManager.is_dialogue_active && GameManager.can_interact:
			check_interaction()

func check_interaction():
	var areas = $InteractionZone.get_overlapping_areas()
	var closest_area = null
	var shortest_distance = INF
	
	for area in areas:
		if area.has_meta("interaction_data"):
			var distance = global_position.distance_to(area.global_position)
			
			if distance < shortest_distance:
				shortest_distance = distance
				closest_area = area
	
	if closest_area != null:
		var raw_data = closest_area.get_meta("interaction_data")
		var final_data = GameManager.resolve_interaction(raw_data)
		
		if final_data.is_empty():
			return

		var text = final_data.get("text", "...")
		var char_name = final_data.get("name", "")
		var portrait = final_data.get("portrait", "")
		
		get_tree().call_group("DialogueSystem", "start_dialogue", text, char_name, portrait)

func _physics_process(_delta):
	if GameManager.is_dialogue_active:
		velocity = Vector2.ZERO
		play_anim(0)
		move_and_slide()
		return
	
	player_movement(_delta)

func player_movement(_delta):
	var dx = Input.get_axis("ui_left", "ui_right")
	var dy = Input.get_axis("ui_up", "ui_down")
	var direction = Vector2(dx, dy)

	velocity = direction * SPEED
	
	if direction.length() > 0:
		if abs(direction.y) > abs(direction.x):
			current_direction = "front" if direction.y > 0 else "back"
		else:
			current_direction = "right" if direction.x > 0 else "left"
		play_anim(1)
	else:
		play_anim(0)
	
	move_and_slide()

func play_anim(movement):
	var suffix = "walk" if movement == 1 else "idle"
	var anim_name = current_direction + "_" + suffix
	
	if anim_sprite.animation != anim_name:
		anim_sprite.play(anim_name)
