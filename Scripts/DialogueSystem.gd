extends CanvasLayer
signal dialogue_finished

var all_dialogue_data = {} # JSON'daki tüm dalları tutar
var dialogue_queue = []
var current_node_data = {} # O anki aktif diyalog verisi
var choice_button_scene = preload("res://Scenes/ChoiceButton.tscn")
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
	"Cain_Happy": preload("res://Characters/Cain/Portraits/Cain_Happy.png")
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
@onready var choice_container = %ChoiceContainer # EKLEDİĞİMİZ SATIR

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
	
	if portrait_rect.material:
		portrait_rect.material = portrait_rect.material.duplicate()
	
	update_portrait_colors()
	
	interaction_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_KEEP_SIZE)
	interaction_label.grow_horizontal = Control.GROW_DIRECTION_END
	
	if interaction_label.get_parent() is Control:
		interaction_label.get_parent().set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_KEEP_SIZE)
		interaction_label.get_parent().grow_horizontal = Control.GROW_DIRECTION_END
	
	name_box.hide()
	portrait_rect.hide()
	interaction_panel.hide()
	choice_container.hide()
	hide_indicator()
	
	interaction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	interaction_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	interaction_label.lines_skipped = 0
	interaction_label.max_lines_visible = -1

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
		# Eğer seçenekler ekrandaysa, Enter ile geçmeyi engelle
		if choice_container.visible: return 
		
		if is_typing:
			is_skipping = true
		elif is_waiting_input:
			handle_dialogue_input()

func start_dialogue(message, char_name = "", portrait_id = ""):
	GameManager.is_dialogue_active = true
	interaction_panel.show()
	choice_container.hide() # Her yeni cümlede temizle
	full_text_storage = message
	current_char_index = 0
	interaction_label.text = ""
	interaction_label.visible_characters = 0
	is_waiting_input = false
	is_typing = false
	is_skipping = false
	hide_indicator()
	
	# Karakter ses ayarı
	if char_name == "Cain": current_audio_player = audio_cain
	elif char_name == "Lyra": current_audio_player = audio_lyra
	elif char_name == "Mask": current_audio_player = audio_mask
	else: current_audio_player = audio_normal

	# İsim kutusu ayarı
	if char_name != "":
		name_label.text = char_name
		name_box.show()
		current_pitch = character_pitches.get(char_name, 1.0)
	else:
		name_box.hide()
		current_pitch = 1.0
	
	# Portre ayarı
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
	
	
	if current_char_index >= full_text_storage.length() and current_node_data.has("choices"):
		show_choices(current_node_data["choices"])
	else:
		is_waiting_input = true
		if current_char_index < full_text_storage.length():
			show_indicator()

# 

func show_choices(choices):
	is_waiting_input = false
	for child in choice_container.get_children():
		child.queue_free()
	
	choice_container.show()
	
	# Textbox görselini buton için hazırlayalım (Kendi yolunu yaz)
	var btn_texture = preload("res://Other Art/Palettes/BluePalette.png") # BURAYA KENDİ GÖRSEL YOLUNU YAZ
	
	# Stil ayarlarını kodla tanımlıyoruz
	var style = StyleBoxTexture.new()
	style.texture = btn_texture
	# Görselin kenarlarının bozulmaması için (9-slice ayarı)
	style.texture_margin_left = 10
	style.texture_margin_right = 10
	style.texture_margin_top = 5
	style.texture_margin_bottom = 5
	# Yazının kenarlara yapışmaması için boşluklar
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5

	for choice in choices:
		var btn = Button.new() 
		btn.text = choice["text"]
		
		
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART 
		btn.custom_minimum_size.y = 24 
		btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN 
		
		
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style) 
		btn.add_theme_stylebox_override("pressed", style) 
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new()) 
		

		btn.add_theme_color_override("font_color", Color.WHITE)
		
	
		btn.pressed.connect(_on_choice_selected.bind(choice))
		
		choice_container.add_child(btn)
	is_waiting_input = false
	for child in choice_container.get_children():
		child.queue_free()
	
	choice_container.show()
	
	for choice in choices:
		
		var btn = choice_button_scene.instantiate() 
		btn.text = choice["text"]
		
		
		btn.pressed.connect(_on_choice_selected.bind(choice))
		choice_container.add_child(btn)
	is_waiting_input = false
	for child in choice_container.get_children():
		child.queue_free()
	
	choice_container.show()
	for choice in choices:
		var btn = Button.new()
		btn.text = choice["text"]
		btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_choice_selected.bind(choice))
		choice_container.add_child(btn)

func _on_choice_selected(choice_data):
	
	GameManager.corruption_points += choice_data.get("impact", 0)
	choice_container.hide()
	
	
	var target = choice_data.get("target", "")
	if all_dialogue_data.has(target):
		dialogue_queue = all_dialogue_data[target].duplicate()
		show_next_dialogue_node()
	else:
		close_dialogue()



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
	choice_container.hide()
	hide_indicator()
	interaction_label.text = ""
	GameManager.is_dialogue_active = false
	GameManager.can_interact = false
	emit_signal("dialogue_finished")
	await get_tree().create_timer(0.3).timeout
	GameManager.can_interact = true
	dialogue_finished.emit()

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
		if data is Dictionary:
			all_dialogue_data = data
			dialogue_queue = all_dialogue_data.get("start", []).duplicate()
		else:
			all_dialogue_data = {"start": data}
			dialogue_queue = data.duplicate()
		show_next_dialogue_node()

func show_next_dialogue_node():
	if dialogue_queue.size() > 0:
		current_node_data = dialogue_queue.pop_front()
		start_dialogue(
			current_node_data.get("text", "..."),
			current_node_data.get("name", ""),
			current_node_data.get("portrait", "")
		)
	else:
		close_dialogue()
