extends Control

@onready var audio_click = $AudioClick

# ฟังก์ชันนี้จะทำงานเมื่อกดปุ่ม "Let's Play"
func _on_button_pressed() -> void:
	
	# 🔊 เล่นเสียงและรอ 0.2 วิ ก่อนเปลี่ยนหน้า
	if audio_click:
		audio_click.play()
		await get_tree().create_timer(0.2).timeout
		
	get_tree().change_scene_to_file("res://scene/world.tscn")
