extends Control


@onready var score_label = $score_label
@onready var menu_button = $MenuButton
@onready var win_sound = $WinSound
func _ready():
	# ตั้งข้อความ
	
	score_label.text = "Final Score: " + str(GameDatabase.total_score)

	# ทำให้ UI อยู่กลางจอ (กันพลาด)
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# เล่นเสียงชนะ (ถ้ามี AudioStreamPlayer)
	if has_node("WinSound"):
		$WinSound.play()

func _on_menu_button_pressed():
	GameDatabase.reset_game_progress()
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
