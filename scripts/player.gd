extends CharacterBody2D

const SPEED := 150.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var step_sound: AudioStreamPlayer2D = $StepSound # 👣 โน้ตเสียงเดิน

var start_position: Vector2

func _ready():
	# ให้ world.gd เป็นคนจัดการตำแหน่งล่าสุด เพื่อป้องกันการลำดับการทำงานผิดพลาด
	start_position = global_position


func _physics_process(_delta):
	var direction := Vector2.ZERO

	# รับค่า Input
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * SPEED
		
		# เล่นแอนิเมชันเดิน
		play_walk_animation(direction)
		
		# 👣 เล่นเสียงเดิน
		play_step_sound()
	else:
		velocity = Vector2.ZERO
		
		# เล่นแอนิเมชันยืนนิ่ง
		play_idle_animation()
		
		# 🛑 หยุดเสียงเดินทันทีเมื่อหยุดเดิน
		if step_sound.playing:
			step_sound.stop()

	move_and_slide()
	check_fall()


# --------------------------------------------------
# ระบบฟังก์ชันเสริม
# --------------------------------------------------

func play_step_sound():
	# เล่นเสียงถ้าตอนนี้เสียงยังไม่ได้เล่นอยู่ (ป้องกันเสียงซ้อนกันจนหนวกหู)
	if not step_sound.playing:
		# สุ่ม Pitch เล็กน้อยเพื่อให้เสียงเดินดูเป็นธรรมชาติ ไม่ซ้ำซาก
		step_sound.pitch_scale = randf_range(0.8, 1.2)
		step_sound.play()


func check_fall():
	# ระบบกันตกแผนที่ (ปรับตัวเลขตามขนาดด่านของคุณ)
	if global_position.y > 1000 or global_position.y < -1000 \
	or global_position.x > 1500 or global_position.x < -1500:
		respawn()


func respawn():
	global_position = start_position
	velocity = Vector2.ZERO


func play_walk_animation(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		animated_sprite.play("side_walk")
		animated_sprite.flip_h = dir.x < 0
	else:
		if dir.y > 0:
			animated_sprite.play("front_walk")
		else:
			animated_sprite.play("back_walk")


func play_idle_animation():
	match animated_sprite.animation:
		"side_walk":
			animated_sprite.play("side_idle")
		"back_walk":
			animated_sprite.play("back_idle")
		_:
			animated_sprite.play("front_idle")
