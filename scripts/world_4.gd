extends Node2D

@onready var player = $Player 
@onready var player_spawn_point = $Spawnpoint 

# 🟢 อ้างอิง UI และโหนดเสียง (เช็คชื่อใน Scene ให้ตรงกัน)
@onready var quest_label = $CanvasLayer/QuestLabel
@onready var bgm_player = $BGMPlayer 

func _ready():
	# ==========================================
	# 1. ระบบจัดการตำแหน่งผู้เล่น
	# ==========================================
	if GameDatabase.player_last_position != Vector2.ZERO:
		player.global_position = GameDatabase.player_last_position
		GameDatabase.player_last_position = Vector2.ZERO
		print("✅ กลับมาตำแหน่งล่าสุดเรียบร้อย")
	else:
		if player_spawn_point:
			player.global_position = player_spawn_point.global_position
			print("🏠 เริ่มต้นที่จุด Spawnpoint")
			
	player.start_position = player.global_position

	# ==========================================
	# 2. เริ่มต้นระบบเสียงและเควส
	# ==========================================
	setup_bgm()
	update_quest_ui()

# --------------------------------------------------
# ระบบตั้งค่า BGM ตามด่าน
# --------------------------------------------------
func setup_bgm():
	if GameDatabase.level_bgms.size() > GameDatabase.current_level_index:
		var bgm_path = GameDatabase.level_bgms[GameDatabase.current_level_index]
		var stream = load(bgm_path)
		
		if stream:
			bgm_player.stream = stream
			bgm_player.play()
			print("🎵 กำลังเล่นเพลงด่านที่: ", GameDatabase.current_level_index + 1)

# --------------------------------------------------
# ระบบอัปเดต Quest UI และการเปลี่ยนเพลงบอส
# --------------------------------------------------
func update_quest_ui():
	# รอให้ Node มอนสเตอร์ถูกจัดการเสร็จ 1 เฟรม
	await get_tree().process_frame
	
	var mobs_count = get_tree().get_nodes_in_group("mobs").size()
	var level_num = GameDatabase.current_level_index + 1
	
	quest_label.bbcode_enabled = true
	quest_label.pivot_offset = quest_label.size / 2 

	if mobs_count > 0:
		# --- โหมดปกติ: แสดงจำนวนลูกน้องที่เหลือ ---
		quest_label.text = "[center][color=cyan]◈ ด่านที่ " + str(level_num) + " ◈[/color]\n"
		quest_label.text += "[color=white]เป้าหมาย: กำจัดลูกน้องอีก [b][color=red]" + str(mobs_count) + "[/color][/b] ตัว[/color][/center]"
		quest_label.modulate = Color(1, 1, 1)
	else:
		# --- โหมด Boss: ลูกน้องตายหมดแล้ว ---
		quest_label.text = "[center][color=yellow]◈ ด่านที่ " + str(level_num) + " ◈[/color]\n"
		quest_label.text += "[wave amp=50 freq=5][rainbow freq=0.5 sat=0.8 val=1][b]⚠️ BOSS ปรากฏตัวแล้ว! ⚠️[/b][/rainbow][/wave][/center]"
		
		# 1. เล่นอนิเมชั่น Pulse ขยายตัวหนังสือ
		var tween = create_tween()
		tween.tween_property(quest_label, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(quest_label, "modulate", Color(1, 0.9, 0), 0.2)
		tween.tween_property(quest_label, "scale", Vector2(1.0, 1.0), 0.2)

		# 2. 🟢 [เพิ่มใหม่] เปลี่ยนเป็นเพลง Boss ทันที
		var boss_music_path = "res://audio/bgm/boss_theme.mp3" # ⚠️ ใส่ที่อยู่ไฟล์เพลงบอสของคุณ
		if ResourceLoader.exists(boss_music_path):
			var boss_stream = load(boss_music_path)
			# เช็คว่าเพลงบอสเล่นอยู่แล้วหรือยัง เพื่อไม่ให้เพลงเริ่มใหม่ซ้ำๆ
			if bgm_player.stream != boss_stream:
				bgm_player.stream = boss_stream
				bgm_player.play()
				print("🔥 เพลงบอสเริ่มทำงาน!")
