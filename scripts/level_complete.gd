extends Control

@onready var score_label = $Score
@onready var next_button = $NextLevel
@onready var clear_sound = $clear_sound
@onready var audio_click = $AudioClick # 🎵 อ้างอิงโหนดเสียงปุ่ม

func _ready():
	# แสดงคะแนน
	score_label.text = "Score: " + str(GameDatabase.total_score)

	# เล่นเสียงชนะ
	if clear_sound and clear_sound.stream:
		clear_sound.play()

	# เชื่อมปุ่มไปด่านถัดไป
	if not next_button.pressed.is_connected(_on_next_pressed):
		next_button.pressed.connect(_on_next_pressed)


func _on_next_pressed():
	# 🔊 เล่นเสียงกดปุ่ม และรอแป๊บนึงก่อนเปลี่ยนหน้า
	if audio_click:
		audio_click.play()
		await get_tree().create_timer(0.2).timeout

	# 🟢 1. รีเซ็ตตำแหน่ง เพื่อให้ไปเกิดที่ Spawn Point ของด่านใหม่
	GameDatabase.player_last_position = Vector2.ZERO
	GameDatabase.last_world_path = "" 
	
	# 🟢 2. เพิ่ม Index เพื่อไปด่านต่อไป
	GameDatabase.current_level_index += 1
	
	# 🟢 3. เช็คว่ามีด่านต่อไปไหม
	if GameDatabase.current_level_index < GameDatabase.levels.size():
		var next_level = GameDatabase.levels[GameDatabase.current_level_index]
		get_tree().change_scene_to_file(next_level)
	else:
		# 🏆 ถ้าจบด่านสุดท้ายแล้ว (world9) ให้ไปที่หน้า win_ui
		var win_scene_path = "res://scene/win_ui.tscn"
		
		# เช็คก่อนว่ามีไฟล์หน้า win_ui จริงไหม เพื่อป้องกันเกมค้าง
		if ResourceLoader.exists(win_scene_path):
			get_tree().change_scene_to_file(win_scene_path)
		else:
			# ถ้าหาไฟล์ไม่เจอ ให้กลับเมนูหลักเป็นทางเลือกสำรอง
			print("Error: ไม่พบไฟล์ win_ui.tscn กำลังกลับหน้าเมนูหลัก...")
			get_tree().change_scene_to_file("res://scene/main_menu.tscn")
