extends CanvasLayer
signal dialogue_finished

var dialogue_queue = []
var is_typing = false
var is_waiting_input = false
var is_skipping = false
var current_pitch = 1.0
var indicator_tween: Tween

const TEXT_WIDTH_NARROW = 222.0
const TEXT_WIDTH_FULL = 260.0
const INDICATOR_X_NARROW = 224.0
const INDICATOR_X_FULL = 267.0
const SOUND_FREQUENCY = 3
const MAX_LINES = 3

var full_text_storage = ""
var current_char_index = 0

var portraits = {
	"Lyra_Neutral": preload("res://Characters/Lyra/Portraits/Lyra_Neutral.png"),
	"Lyra_Wink": preload("res://Characters/Lyra/Portraits/Lyra_Wink.png"),
	"Lyra_Angry": preload("res://Characters/Lyra/Portraits/Lyra_Angry.png"),
	"Lyra_Empty": preload("res://Characters/Lyra/Portraits/Lyra_Empty.png"),
	"Lyra_Surprised": preload("res://Characters/Lyra/Portraits/Lyra_Surprised.png"),
	"Lyra_Sad": preload("res://Characters/Lyra/Portraits/Lyra_Sad.png"),
	"Lyra_Happy": preload("res://Characters/Lyra/Portraits/Lyra_Happy.png"),
	"Cain_Surprised": preload("res://Characters/Cain/Portraits/Cain_Surprised.png"),
	"Cain_Angry": preload("res://Characters/Cain/Portraits/Cain_Angry.png"),
	"Cain_Empty": preload("res://Characters/Cain/Portraits/Cain_Empty.png"),
	"Cain_Pensive": preload("res://Characters/Cain/Portraits/Cain_Pensive.png"),
	"Cain_Sad": preload("res://Characters/Cain/Portraits/Cain_Sad.png"),
	"Cain_Neutral": preload("res://Characters/Cain/Portraits/Cain_Neutral.png"),
	"Cain_Happy": preload("res://Characters/Cain/Portraits/Cain_Happy.png"),
	"Shadow": preload("res://Characters/Shadows/Shadow.png")
}

var character_pitches = {
	"Cain": 0.95,
	"Lyra": 1.7,
	"???": 1.45,
	"Mask": 1
}

@onready var interaction_label = %DialogueText
@onready var interaction_panel = %DialoguePanel
@onready var portrait_rect = %Portrait
@onready var name_box = %NameBox
@onready var name_label = %NameLabel
@onready var next_indicator = %NextIndicator

@onready var audio_cain = %Cain_Blip
@onready var audio_lyra = %Lyra_Blip
@onready var audio_mask = %Mask_Blip
@onready var audio_normal = %Normal_Blip

var current_audio_player = null

@export_group("Portrait Palette")
@export var palette_1: Color = Color("004e96")
@export var palette_2: Color = Color("52b2cf")
@export var palette_3: Color = Color("7ec4cf")
@export var palette_4: Color = Color("93e7e7")
@export var palette_5: Color = Color("c8f4f4")

func _ready():
	add_to_group("DialogueSystem")
	
	# Duplicate material so Lyra and Cain don't share the same palette state
	if portrait_rect.material:
		portrait_rect.material = portrait_rect.material.duplicate()
	
	update_portrait_colors()
	
	# We REMOVED the anchor/offset code here. 
	# Now, the label will stay exactly where you placed it in the Editor.
	
	name_box.hide()
	portrait_rect.hide()
	interaction_panel.hide()
	hide_indicator()
	
	# Ensure the text wraps correctly without shifting position
	interaction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Optional: Forces the text to stay centered vertically in the box
	interaction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func update_portrait_colors():
	var mat = portrait_rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("color1", palette_1)
		mat.set_shader_parameter("color2", palette_2)
		mat.set_shader_parameter("color3", palette_3)
		mat.set_shader_parameter("color4", palette_4)
		mat.set_shader_parameter("color5", palette_5)

func _input(event):
	if event.is_action_pressed("ui_accept") and GameManager.is_dialogue_active:
		if is_typing:
			is_skipping = true
		elif is_waiting_input:
			handle_dialogue_input()

func start_dialogue(message, char_name = "", portrait_id = ""):
	GameManager.is_dialogue_active = true
	interaction_panel.show()
	full_text_storage = message
	current_char_index = 0
	interaction_label.text = ""
	interaction_label.visible_characters = 0
	is_waiting_input = false
	is_typing = false
	is_skipping = false
	hide_indicator()
	
	current_audio_player = audio_normal
	if char_name == "Cain": current_audio_player = audio_cain
	elif char_name == "Lyra": current_audio_player = audio_lyra
	elif char_name == "Mask": current_audio_player = audio_mask

	if char_name != "":
		name_label.text = char_name
		name_box.show()
		current_pitch = character_pitches.get(char_name, 1.0)
	else:
		name_box.hide()
		current_pitch = 1.0
	
	if portrait_id != "" and portraits.has(portrait_id):
		portrait_rect.texture = portraits[portrait_id]
		portrait_rect.show()
		interaction_label.custom_minimum_size.x = TEXT_WIDTH_NARROW
		next_indicator.position.x = INDICATOR_X_NARROW
	else:
		portrait_rect.hide()
		interaction_label.custom_minimum_size.x = TEXT_WIDTH_FULL
		next_indicator.position.x = INDICATOR_X_FULL
	
	await get_tree().process_frame
	prepare_next_page()

func prepare_next_page():
	interaction_label.visible_characters = 0
	interaction_label.text = ""
	while current_char_index < full_text_storage.length():
		var next_space_index = full_text_storage.find(" ", current_char_index)
		if next_space_index == -1: next_space_index = full_text_storage.length()
		var word_len = next_space_index - current_char_index
		var next_chunk = full_text_storage.substr(current_char_index, word_len + 1)
		interaction_label.text += next_chunk
		if interaction_label.get_line_count() > MAX_LINES:
			interaction_label.text = interaction_label.text.left(-next_chunk.length())
			break
		current_char_index += next_chunk.length()
	animate_text()

func animate_text():
	is_typing = true
	hide_indicator()
	var total_chars = interaction_label.text.length()
	
	while interaction_label.visible_characters < total_chars:
		if is_skipping:
			interaction_label.visible_characters = total_chars
		else:
			interaction_label.visible_characters += 1
			if interaction_label.visible_characters % SOUND_FREQUENCY == 0:
				if current_audio_player:
					current_audio_player.pitch_scale = current_pitch + randf_range(-0.05, 0.05)
					current_audio_player.play()
			await get_tree().create_timer(0.035).timeout
	
	is_typing = false
	is_waiting_input = true
	if current_char_index < full_text_storage.length():
		show_indicator()

func handle_dialogue_input():
	if is_waiting_input:
		if current_char_index >= full_text_storage.length():
			show_next_dialogue_node()
		else:
			is_waiting_input = false
			is_skipping = false
			hide_indicator()
			prepare_next_page()

func close_dialogue():
	interaction_panel.hide()
	name_box.hide()
	portrait_rect.hide()
	hide_indicator()
	interaction_label.text = ""
	
	GameManager.is_dialogue_active = false
	GameManager.can_interact = false
	
	dialogue_finished.emit()
	
	# Safety check for scene tree during transitions
	if is_inside_tree():
		await get_tree().create_timer(0.3).timeout
	
	GameManager.can_interact = true

func show_indicator():
	next_indicator.show()
	if indicator_tween: indicator_tween.kill()
	indicator_tween = create_tween().set_loops()
	indicator_tween.tween_property(next_indicator, "modulate:a", 0.0, 0.5)
	indicator_tween.tween_property(next_indicator, "modulate:a", 1.0, 0.5)

func hide_indicator():
	next_indicator.hide()
	if indicator_tween: indicator_tween.kill()
	next_indicator.modulate.a = 1.0
	
func load_dialogue(file_path: String):
	if not FileAccess.file_exists(file_path): return
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		var data = json.get_data()
		# Forced linear conversion: if it was a dictionary with branches, just take the 'start' array
		if data is Dictionary:
			dialogue_queue = data.get("start", []).duplicate()
		else:
			dialogue_queue = data.duplicate()
		show_next_dialogue_node()

func show_next_dialogue_node():
	if dialogue_queue.size() > 0:
		var node = dialogue_queue.pop_front()
		start_dialogue(
			node.get("text", "..."),
			node.get("name", ""),
			node.get("portrait", "")
		)
	else:
		close_dialogue()
