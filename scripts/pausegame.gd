extends Control

# อ้างอิงปุ่มและเสียง
@onready var resume_button = $VBoxContainer/ResumeButton
@onready var menu_button = $VBoxContainer/MenuButton
@onready var audio_click = $AudioClick # 🟢 เพิ่มบรรทัดนี้

func _ready():
	visible = false
	if not resume_button.pressed.is_connected(_on_resume_button_pressed):
		resume_button.pressed.connect(_on_resume_button_pressed)
	if not menu_button.pressed.is_connected(_on_menu_button_pressed):
		menu_button.pressed.connect(_on_menu_button_pressed)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state
	
	# ถ้าอยากให้มีเสียงตอนเปิด/ปิดเมนูด้วย ใส่ตรงนี้ได้ครับ
	if audio_click:
		audio_click.play()

# --- ฟังก์ชันเมื่อกดปุ่ม ---

func _on_resume_button_pressed():
	# 🔊 เล่นเสียงคลิกก่อน
	if audio_click:
		audio_click.play()
	
	# รอจังหวะเสียงนิดนึงก่อนเริ่มเกมต่อ (เพื่อความสมจริง)
	await get_tree().create_timer(0.1).timeout 
	toggle_pause()

func _on_menu_button_pressed():
	# 🔊 เล่นเสียงคลิก
	if audio_click:
		audio_click.play()
	
	# รอเสียงแป๊บนึงก่อนเปลี่ยนฉาก
	await get_tree().create_timer(0.1).timeout
	
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
