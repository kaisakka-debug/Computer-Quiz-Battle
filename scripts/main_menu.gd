extends Control

# ใช้ % หรือ Path ที่ถูกต้องเพื่ออ้างอิงโหนด
@onready var main_buttons = %VBoxContainer
@onready var options_panel = %OptionPanel
@onready var sound_slider = $OptionPanel/VBoxContainer/HSlider
@onready var audio_click = $AudioClick
@onready var percent_label = $OptionPanel/VBoxContainer/percentsound
func _ready() -> void:
	# ... โค้ดเดิม ...
	if sound_slider:
		sound_slider.value = 0.5
		# เรียกฟังก์ชันอัปเดตทั้งเสียงและตัวเลขทันที
		_on_h_slider_value_changed(0.5)

# --- ฟังก์ชันปรับเสียง (เชื่อมกับ Signal: value_changed) ---
func _on_h_slider_value_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("Master")
	
	# 1. ปรับระดับเสียง (โค้ดเดิม)
	if value <= 0.01:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	
	# 🟢 2. แสดงตัวเลขเปอร์เซ็นต์ (เพิ่มบรรทัดนี้ครับ)
	# เราเอาค่า 0-1 มาคูณ 100 และใช้ int() เพื่อตัดทศนิยมทิ้ง
	percent_label.text = str(int(value * 100)) + "%"
	
	# 3. เล่นเสียงติ๊ก (โค้ดเดิม)
	if audio_click and not audio_click.playing:
		audio_click.pitch_scale = randf_range(0.9, 1.1)
		audio_click.play()

func _on_button_pressed() -> void: # ปุ่ม Start
	print("เริ่มเกม...")
	play_click_and_wait()
	get_tree().change_scene_to_file("res://scene/how_to_play.tscn")

func _on_button_2_pressed() -> void: # ปุ่ม Option
	play_click_sound()
	main_buttons.visible = false
	options_panel.visible = true

func _on_button_3_pressed() -> void: # ปุ่ม Exit
	play_click_and_wait()
	get_tree().quit()

func _on_button_4_pressed() -> void: # ปุ่ม Back (ในหน้า Option)
	play_click_sound()
	options_panel.visible = false
	main_buttons.visible = true

# --- ฟังก์ชันเสริมสำหรับเสียงปุ่ม ---
func play_click_sound():
	if audio_click:
		audio_click.play()

func play_click_and_wait():
	if audio_click:
		audio_click.play()
		await get_tree().create_timer(0.2).timeout
