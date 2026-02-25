extends CharacterBody2D

@export var mob_id: int = 1
@export var speed: float = 60

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detect_area: Area2D = $DetectArea
@onready var battle_area: Area2D = $BattleArea

var player: CharacterBody2D = null
var is_chasing := false
var is_triggered := false
var can_battle := false

func _ready():
	add_to_group("mobs")
	if GameDatabase.defeated_mobs.has(mob_id):
		queue_free()
		return

	await get_tree().process_frame
	player = get_tree().current_scene.get_node_or_null("Player")
	
	detect_area.body_entered.connect(_on_detect_entered)
	detect_area.body_exited.connect(_on_detect_exited)
	battle_area.body_entered.connect(_on_battle_entered)

	await get_tree().create_timer(0.5).timeout
	can_battle = true

func _on_detect_entered(body):
	if body == player: is_chasing = true

func _on_detect_exited(body):
	if body == player: is_chasing = false

func _on_battle_entered(body):
	if not can_battle or is_triggered or body != player:
		return

	is_triggered = true
	
	# 🟢 บันทึกพิกัดล่าสุด (ใช้ global_position เพื่อความแม่นยำ)
	GameDatabase.player_last_position = player.global_position
	# 🟢 บันทึกชื่อด่านปัจจุบันไว้
	if get_tree().current_scene:
		GameDatabase.last_world_path = get_tree().current_scene.scene_file_path
	
	print("💾 บันทึกพิกัดก่อนสู้: ", GameDatabase.player_last_position)

	if not GameDatabase.defeated_mobs.has(mob_id):
		GameDatabase.defeated_mobs.append(mob_id)

	GameDatabase.is_boss_battle = false
	
	# 🟢 ใช้ call_deferred เพื่อเปลี่ยนฉากอย่างปลอดภัย
	get_tree().call_deferred("change_scene_to_file", "res://scene/battle_ui.tscn")

func _physics_process(_delta):
	if player == null: return
	if is_chasing:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed
		move_and_slide()
		if anim:
			anim.flip_h = direction.x < 0
			if anim.sprite_frames.has_animation("walk"): anim.play("walk")
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		if anim and anim.sprite_frames.has_animation("idle"): anim.play("idle")
