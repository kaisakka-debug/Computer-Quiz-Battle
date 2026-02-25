extends CharacterBody2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D
@onready var audio_before_battle: AudioStreamPlayer2D = $AudioBeforeBattle

var is_triggered := false
var battle_scene_path := "res://scene/battle_ui.tscn"

func _ready():
	# 🟢 1. รอ 1 เฟรมให้ระบบเคลียร์มอนสเตอร์ที่เคยตายไปแล้วออกจากฉากให้เสร็จก่อน
	await get_tree().process_frame
	
	# 🟢 2. นับจำนวนลูกน้อง (Mob) ที่ยังเหลือรอดอยู่ในฉาก
	var active_mobs = 0
	for node in get_tree().get_nodes_in_group("mobs"):
		if not node.is_queued_for_deletion(): # นับเฉพาะตัวที่ยังไม่โดนลบ
			active_mobs += 1
			
	# 🟢 3. ถ้ายังมีลูกน้องเหลืออยู่ ให้ลบบอสทิ้งไปก่อน
	if active_mobs > 0:
		print("ลูกน้องยังไม่ตาย บอสยังไม่ออกมา! (เหลือ ", active_mobs, " ตัว)")
		queue_free()
		return
		
	print("🔥 ลูกน้องตายหมดแล้ว! บอสปรากฏตัวได้!")

	# 🔹 เล่น idle (ถ้าบอสได้เกิด ค่อยรันโค้ดปกติ)
	if anim_sprite and anim_sprite.sprite_frames:
		if anim_sprite.sprite_frames.has_animation("idle"):
			anim_sprite.play("idle")
	else:
		push_error("AnimatedSprite2D ไม่ถูกต้อง")

	# 🔹 connect signal
	if not area.body_entered.is_connected(_on_area_2d_body_entered):
		area.body_entered.connect(_on_area_2d_body_entered)


# --------------------------------------------------
# PLAYER ชน
# --------------------------------------------------
func _on_area_2d_body_entered(body):
	if is_triggered:
		return

	if not body.is_in_group("player"):
		return

	is_triggered = true
	set_physics_process(false)
	
	GameDatabase.player_last_position = body.global_position

	print("🎬 Encounter Triggered")
	play_trigger_sequence()


# --------------------------------------------------
# ลำดับ Animation + เสียง
# --------------------------------------------------
func play_trigger_sequence() -> void:
	# 🎬 1. เล่น animation trigger
	if anim_sprite and anim_sprite.sprite_frames.has_animation("trigger"):
		anim_sprite.play("trigger")
		await anim_sprite.animation_finished
		
	# 🔊 2. เล่นเสียงก่อนเข้า battle
	if audio_before_battle and audio_before_battle.stream:
		audio_before_battle.play()
		await get_tree().create_timer(1.0).timeout 

	# 3. เปลี่ยนฉาก!
	start_battle()


# --------------------------------------------------
# เปลี่ยนฉาก
# --------------------------------------------------
func start_battle():
	GameDatabase.is_boss_battle = true

	# ⚠️ อย่าลืมบันทึกชื่อด่านก่อนสลับฉาก! (กันวาร์ปผิดด่าน)
	if get_tree().current_scene:
		GameDatabase.last_world_path = get_tree().current_scene.scene_file_path

	if not ResourceLoader.exists(battle_scene_path):
		push_error("❌ ไม่พบ scene: " + battle_scene_path)
		is_triggered = false
		set_physics_process(true)
		return

	var result = get_tree().change_scene_to_file(battle_scene_path)

	if result != OK:
		push_error("❌ เปลี่ยนฉากล้มเหลว: " + str(result))
		is_triggered = false
		set_physics_process(true)
