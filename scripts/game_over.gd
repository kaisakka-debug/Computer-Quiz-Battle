extends Control

# =========================
# 🎵 เสียง
# =========================
# อ้างอิงโหนดเสียง
@onready var audio_click = $AudioClick 
@onready var gameover = $gameover

# =========================
# ทำงานทันทีที่เปิด Scene นี้
# =========================
func _ready():
	# 🔊 เล่นเสียง Game Over ทันทีที่ฉากโหลดขึ้นมา
	if gameover:
		gameover.play()

# =========================
# เมื่อกดปุ่มต่างๆ
# =========================
func _on_retry_pressed():
	print("เริ่มเล่นใหม่...")
	
	# 🔊 เล่นเสียงกดปุ่ม
	if audio_click:
		audio_click.play()
		# รอ 0.2 วินาทีเพื่อให้เสียงเล่นออกมาก่อนสลับฉาก
		await get_tree().create_timer(0.2).timeout
		
	# สำคัญ: ต้องรีเซ็ตค่าต่างๆ ใน GameDatabase ก่อนเริ่มใหม่
	if GameDatabase.has_method("reset_game_progress"):
		GameDatabase.reset_game_progress()
	
	# โหลดฉาก World ด่านแรก
	get_tree().change_scene_to_file("res://scene/world.tscn")

func _on_menu_pressed():
	print("กลับเมนูหลัก...")
	
	# 🔊 เล่นเสียงกดปุ่ม
	if audio_click:
		audio_click.play()
		await get_tree().create_timer(0.2).timeout
		
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
