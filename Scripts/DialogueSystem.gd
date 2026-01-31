extends CanvasLayer

var is_typing = false
var is_waiting_input = false
var is_skipping = false
var current_pitch = 1.0
var indicator_tween: Tween

const TEXT_WIDTH_NARROW = 950.0
const TEXT_WIDTH_FULL = 1100.0

const INDICATOR_X_NARROW = 972.0
const INDICATOR_X_FULL = 1122.0

const SOUND_FREQUENCY = 3
const MAX_LINES = 3

var full_text_storage = ""
var current_char_index = 0

var portraits = {
	"Okabe_Neutral": preload("res://Art/Characters/Okabe/Okabe_Neutral.png"),
	"Okabe_Laugh": preload("res://Art/Characters/Okabe/Okabe_Laugh.png"),
	"Okabe_Happy": preload("res://Art/Characters/Okabe/Okabe_Happy.png"),
	"Okabe_Angry": preload("res://Art/Characters/Okabe/Okabe_Angry.png"),
	"Okabe_Proud": preload("res://Art/Characters/Okabe/Okabe_Proud.png"),
	"Okabe_Sad": preload("res://Art/Characters/Okabe/Okabe_Sad.png"),
	"Okabe_Sweating": preload("res://Art/Characters/Okabe/Okabe_Sweating.png"),
	"Okabe_Thinking": preload("res://Art/Characters/Okabe/Okabe_Thinking.png"),
	"Okabe_Traumatized": preload("res://Art/Characters/Okabe/Okabe_Traumatized.png"),
	
	"Mayuri_Neutral": preload("res://Art/Characters/Mayuri/Mayuri_Neutral.png"),
	"Mayuri_Angry": preload("res://Art/Characters/Mayuri/Mayuri_Angry.png"),
	"Mayuri_Happy": preload("res://Art/Characters/Mayuri/Mayuri_Happy.png"),
	"Mayuri_Pensive": preload("res://Art/Characters/Mayuri/Mayuri_Pensive.png"),
	"Mayuri_Sad": preload("res://Art/Characters/Mayuri/Mayuri_Sad.png"),
	"Mayuri_Tutturu": preload("res://Art/Characters/Mayuri/Mayuri_Tutturu.png"),
	"Mayuri_Worried":  preload("res://Art/Characters/Mayuri/Mayuri_Worried.png"),

	"Daru_Angry": preload("res://Art/Characters/Daru/Daru_Angry.png"),
	"Daru_Focused": preload("res://Art/Characters/Daru/Daru_Focused.png"),
	"Daru_Happy": preload("res://Art/Characters/Daru/Daru_Happy.png"),
	"Daru_Sad": preload("res://Art/Characters/Daru/Daru_Sad.png"),
	"Daru_Smug": preload("res://Art/Characters/Daru/Daru_Smug.png"),
	"Daru_Worried": preload("res://Art/Characters/Daru/Daru_Worried.png"),
	"Daru_Neutral": preload("res://Art/Characters/Daru/Daru_Neutral.png"),
	
	"Kurisu_Neutral": preload("res://Art/Characters/Kurisu/Kurisu_Neutral.png"),
	"Kurisu_Angry": preload("res://Art/Characters/Kurisu/Kurisu_Angry.png"),
	"Kurisu_Blushed": preload("res://Art/Characters/Kurisu/Kurisu_Blushed.png"),
	"Kurisu_Happy": preload("res://Art/Characters/Kurisu/Kurisu_Happy.png"),
	"Kurisu_Sad": preload("res://Art/Characters/Kurisu/Kurisu_Sad.png"),
	"Kurisu_Sigh": preload("res://Art/Characters/Kurisu/Kurisu_Sigh.png"),
	"Kurisu_Thinking": preload("res://Art/Characters/Kurisu/Kurisu_Thinking.png"),
	"Kurisu_Worried": preload("res://Art/Characters/Kurisu/Kurisu_Worried.png"),
	
	"Moeka_Angry": preload("res://Art/Characters/Moeka/Moeka_Angry.png"),
	"Moeka_Neutral": preload("res://Art/Characters/Moeka/Moeka_Neutral.png"),
	"Moeka_Phone": preload("res://Art/Characters/Moeka/Moeka_Phone.png"),
	"Moeka_Sad": preload("res://Art/Characters/Moeka/Moeka_Sad.png"),
	
	"Suzuha_Neutral": preload("res://Art/Characters/Suzuha/Suzuha_Neutral.png"),
	"Suzuha_Jolly": preload("res://Art/Characters/Suzuha/Suzuha_Jolly.png"),
	"Suzuha_Sad": preload("res://Art/Characters/Suzuha/Suzuha_Sad.png"),
	"Suzuha_Serious": preload("res://Art/Characters/Suzuha/Suzuha_Serious.png"),
	"Suzuha_Worried": preload("res://Art/Characters/Suzuha/Suzuha_Worried.png"),
	"Suzuha_Angry": preload("res://Art/Characters/Suzuha/Suzuha_Angry.png"),
	"Suzuha_Happy": preload("res://Art/Characters/Suzuha/Suzuha_Happy.png")
}

var character_pitches = {
	"Okabe": 0.95,
	"Mayuri": 1.7,
	"Daru": 0.85,
	"Kurisu": 1.45,
	"Suzuha": 1.5,
	"Moeka":  1.35
}

@onready var interaction_label = %DialogueText
@onready var interaction_panel = %DialoguePanel
@onready var portrait_rect = %Portrait
@onready var name_box = %NameBox
@onready var name_label = %NameLabel
@onready var next_indicator = %NextIndicator

@onready var audio_okabe = %Okabe_Blip
@onready var audio_mayuri = %Mayuri_Blip
@onready var audio_daru = %Daru_Blip
@onready var audio_suzuha = %Suzuha_Blip
@onready var audio_kurisu = %Kurisu_Blip
@onready var audio_normal = %Normal_Blip

var current_audio_player = null

func apply_lighting():
	if GameManager.is_night:
		portrait_rect.modulate = Color(0.6, 0.6, 0.75)
	else:
		portrait_rect.modulate = Color(1, 1, 1)

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
	
	if char_name == "Okabe":
		current_audio_player = audio_okabe
	elif char_name == "Mayuri":
		current_audio_player = audio_mayuri
	elif char_name == "Daru":
		current_audio_player = audio_daru
	elif char_name == "Suzuha":
		current_audio_player = audio_suzuha
	elif char_name == "Kurisu":
		current_audio_player = audio_kurisu
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
		
		apply_lighting()
		
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
			close_dialogue()
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
