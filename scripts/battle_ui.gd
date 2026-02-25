extends Control

# =========================
# UI REFERENCES
# =========================
@onready var question_label = $main/QuestionSection/QuestionLabel
@onready var choices_container = $main/AnswerSection
@onready var hp_bar = $main/TopSection/PlayerHPBar
@onready var boss_hp_bar = $main/TopSection/BossHPBar 
@onready var score_label = $main/TopSection/ScoreLabel
@onready var time_label = $main/TopSection/TimeLabel
@onready var combo_label = $main/TopSection/ComboLabel

# 🎵 เสียง
@onready var audio_click = $AudioClick
@onready var audio_correct = $AudioCorrect
@onready var audio_wrong = $AudioWrong

# =========================
# ค่าพื้นฐาน
# =========================
var max_hp = 3.0
var current_hp = 3.0
var boss_hp = 3.0
var current_max_boss_hp = 5.0 # <--- แก้ไขเป็น 5.0 เพื่อให้ต้องตอบ 5 ข้อ
var current_question_data = {}

# =========================
# สถานะ
# =========================
var input_locked := false
var battle_ended := false

# =========================
# ระบบเวลา
# =========================
var time_limit := 10.0
var time_left := 10.0
var timer_active := false

# =========================
# ระบบคอมโบ
# =========================
var combo := 0

# =====================================================
# READY
# =====================================================
func _ready():
	# เช็คประเภทการต่อสู้เพื่อตั้งค่า HP ศัตรู
	if GameDatabase.is_boss_battle:
		current_max_boss_hp = 5.0 # บอสเลือด 5
	else:
		current_max_boss_hp = 1.0 # ม็อบปกติเลือด 1
	
	boss_hp = current_max_boss_hp
	current_hp = max_hp
	
	update_hp_bar()
	update_boss_hp_bar()
	update_score_display()
	update_combo_display()
	display_new_question()

# =====================================================
# แสดงคำถามใหม่
# =====================================================
# =====================================================
# แสดงคำถามใหม่ (พร้อมระบบสุ่มลำดับคำตอบ)
# =====================================================
func display_new_question():
	if battle_ended:
		return

	input_locked = false
	set_buttons_disabled(false)

	var mode = "boss" if GameDatabase.is_boss_battle else "mob"
	current_question_data = GameDatabase.get_question_by_difficulty(mode)
	
	question_label.text = current_question_data["text"]

	# --- [ใหม่] ระบบสุ่มลำดับคำตอบ ---
	# 1. สร้าง Array ของลำดับคำตอบ (เช่น [0, 1, 2, 3])
	var answer_indices = []
	for i in range(current_question_data["answers"].size()):
		answer_indices.append(i)
	
	# 2. สลับลำดับใน Array (เช่น กลายเป็น [2, 0, 3, 1])
	answer_indices.shuffle() 

	time_left = time_limit
	timer_active = true
	update_time_display()
	
	var buttons = choices_container.get_children()
	for i in range(buttons.size()):
		var btn = buttons[i]
		
		# เช็คว่าปุ่มลำดับที่ i มีคำตอบที่สุ่มมารองรับไหม
		if i < answer_indices.size():
			# 3. ดึงลำดับจริง (Original Index) ออกมาจากการสุ่ม
			var original_idx = answer_indices[i]
			
			# 4. แสดงข้อความจากลำดับที่สุ่มได้
			btn.text = current_question_data["answers"][original_idx]
			btn.visible = true
			
			if btn.pressed.is_connected(_on_answer_selected):
				btn.pressed.disconnect(_on_answer_selected)
			
			# 5. ส่งค่า original_idx กลับไป เพื่อให้เช็คกับค่า 'correct' ใน Database ได้ถูกต้อง
			btn.pressed.connect(_on_answer_selected.bind(original_idx))
		else:
			btn.visible = false

# =====================================================
# ระบบเวลา (ทำงานทุกเฟรม)
# =====================================================
func _process(delta):
	if timer_active and not battle_ended:
		time_left -= delta
		update_time_display()

		if time_left <= 0:
			timer_active = false
			time_left = 0
			update_time_display()
			handle_time_out()

# เมื่อเวลาหมด
func handle_time_out():
	if input_locked:
		return

	input_locked = true
	set_buttons_disabled(true)

	if audio_wrong:
		audio_wrong.play()

	combo = 0
	update_combo_display()

	current_hp -= 1
	update_hp_bar()

	check_lose_condition()

	if not battle_ended and current_hp > 0:
		await get_tree().create_timer(0.5).timeout
		display_new_question()

# =====================================================
# เมื่อเลือกคำตอบ
# =====================================================
func _on_answer_selected(index):
	if input_locked or battle_ended:
		return
	
	input_locked = true
	timer_active = false
	set_buttons_disabled(true)

	if audio_click:
		audio_click.play()

	if index == current_question_data["correct"]:
		# --- กรณีตอบถูก ---
		if audio_correct:
			audio_correct.play()

		combo += 1
		update_combo_display()

		# คำนวณคะแนน (พื้นฐาน + โบนัสคอมโบ)
		var base_reward = 50 if GameDatabase.is_boss_battle else 10
		var total_reward = base_reward + (combo * 2)
		GameDatabase.total_score += total_reward
		update_score_display()
		
		boss_hp -= 1
		update_boss_hp_bar()
		check_win_condition()
	else:
		# --- กรณีตอบผิด ---
		if audio_wrong:
			audio_wrong.play()

		combo = 0
		update_combo_display()

		current_hp -= 1
		update_hp_bar()
		check_lose_condition()

	# ถ้าเกมยังไม่จบ ให้ขึ้นข้อใหม่
	if not battle_ended and current_hp > 0 and boss_hp > 0:
		await get_tree().create_timer(0.5).timeout
		display_new_question()

# =====================================================
# ฟังก์ชันจัดการ UI และสถานะ
# =====================================================
func set_buttons_disabled(state: bool):
	for btn in choices_container.get_children():
		btn.disabled = state

func update_score_display():
	score_label.text = "Score: " + str(GameDatabase.total_score)

func update_combo_display():
	combo_label.text = "Combo: x" + str(combo)

func update_time_display():
	time_label.text = "Time: " + str(int(time_left))

func update_hp_bar():
	var percentage = (current_hp / max_hp) * 100
	hp_bar.value = percentage
	hp_bar.modulate = Color(1,0,0) if percentage <= 30 else Color(0,1,0)

func update_boss_hp_bar():
	# หลอดเลือดบอสจะคำนวณตาม max_hp ล่าสุด (5.0 หรือ 1.0)
	boss_hp_bar.value = (boss_hp / current_max_boss_hp) * 100

# =====================================================
# ตรวจสอบการแพ้/ชนะ
# =====================================================
func check_lose_condition():
	if current_hp <= 0:
		battle_ended = true
		timer_active = false
		GameDatabase.player_last_position = Vector2.ZERO
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file("res://scene/game_over_ui.tscn")

func check_win_condition():
	if boss_hp <= 0:
		battle_ended = true
		timer_active = false

		if audio_correct:
			audio_correct.play()

		await get_tree().create_timer(0.8).timeout
		
		if GameDatabase.is_boss_battle:
			# 🏆 เช็คว่าเป็นด่านสุดท้าย (ด่านที่ 10 หรือ index 9) หรือยัง
			if GameDatabase.current_level_index == GameDatabase.levels.size() - 1:
				print("ชนะบอสใหญ่แล้ว! ไปหน้า Win UI")
				get_tree().change_scene_to_file("res://scene/win_ui.tscn")
			else:
				# ถ้ายังไม่ใช่ด่านสุดท้าย ให้ไปหน้าสรุปผลเลเวลตามปกติ
				print("ชนะบอสประจำด่าน! ไปหน้า Level Complete")
				get_tree().change_scene_to_file("res://scene/level_complete.tscn")
		else:
			# ชนะมอนสเตอร์ปกติ ให้กลับไปด่านล่าสุดที่ตำแหน่งเดิม
			if GameDatabase.last_world_path != "":
				get_tree().change_scene_to_file(GameDatabase.last_world_path)
			else:
				var current_world = GameDatabase.levels[GameDatabase.current_level_index]
				get_tree().change_scene_to_file(current_world)
