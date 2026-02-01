extends CanvasLayer

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
	"Lyra_Neutral": preload("res://Characters/Lyra/Portraits/Lyra_Neutral.png")
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

func _ready():
	add_to_group("DialogueSystem")
	
	interaction_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_KEEP_SIZE)
	interaction_label.grow_horizontal = Control.GROW_DIRECTION_END
	
	if interaction_label.get_parent() is Control:
		interaction_label.get_parent().set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_KEEP_SIZE)
		interaction_label.get_parent().grow_horizontal = Control.GROW_DIRECTION_END
	
	name_box.hide()
	portrait_rect.hide()
	interaction_panel.hide()
	hide_indicator()
	interaction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	interaction_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	
	interaction_label.lines_skipped = 0
	interaction_label.max_lines_visible = -1

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
	
	if char_name == "Cain":
		current_audio_player = audio_cain
	elif char_name == "Lyra":
		current_audio_player = audio_lyra
	elif char_name == "Mask":
		current_audio_player = audio_mask
	else:
		current_audio_player = audio_normal

	if char_name != "":
		name_label.text = char_name
		name_box.show()
		
		if character_pitches.has(char_name):
			current_pitch = character_pitches[char_name]
		else:
			current_pitch = 1.0
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
	await get_tree().process_frame
	prepare_next_page()

func prepare_next_page():
	interaction_label.visible_characters = 0
	interaction_label.text = ""
	while current_char_index < full_text_storage.length():
		var next_space_index = full_text_storage.find(" ", current_char_index)
		if next_space_index == -1:
			next_space_index = full_text_storage.length()
			
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
			
			var char_index = interaction_label.visible_characters - 1
			
			if char_index >= 0 and interaction_label.text[char_index] != " ":
				if interaction_label.visible_characters % SOUND_FREQUENCY == 0:
					if current_audio_player:
						current_audio_player.pitch_scale = current_pitch + randf_range(-0.05, 0.05)
						current_audio_player.play()
			
			await get_tree().create_timer(0.035).timeout
	
	is_typing = false
	is_waiting_input = true
	
	if current_char_index < full_text_storage.length():
		show_indicator()
	else:
		hide_indicator()

func handle_dialogue_input():
	if is_waiting_input:
		if current_char_index >= full_text_storage.length():
			show_next_dialogue_node();
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
	if not FileAccess.file_exists(file_path):
		printerr("Dialogue file doesn't exist: ", file_path)
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result == OK:
		dialogue_queue = json.get_data()
		show_next_dialogue_node()
	else:
		printerr("JSON Error: ", json.get_error_message())

func show_next_dialogue_node():
	if dialogue_queue.size() > 0:
		var current_node = dialogue_queue.pop_front()
		start_dialogue(
			current_node.get("text", ""),
			current_node.get("name", ""),
			current_node.get("portrait", "")
		)
	else:
		close_dialogue()
