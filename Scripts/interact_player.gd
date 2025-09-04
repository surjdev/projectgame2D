# InteractPlayer.gd  (flip ที่ Warp, Idle/Walk/Jump แยกกัน)
extends CharacterBody2D

@export var speed: float = 180.0
@export var jump_speed: float = 350.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float

@onready var warp: Node2D = $Warp
@onready var ap_idle: AnimationPlayer = $Warp/Player/Idle
@onready var ap_walk: AnimationPlayer = $Warp/Player/Walk
@onready var ap_jump: AnimationPlayer = $Warp/Player/Jump

var base_warp_scale := Vector2.ONE
var _state := ""   # "idle" | "walk" | "jump"

# ==== เพิ่ม: ตัวแปรสำหรับซ่อนในล็อกเกอร์ ====
var is_hidden: bool = false
var _hidden_locker: Node2D = null
var _saved_z_index := 0

func _ready() -> void:
	base_warp_scale = warp.scale.abs()
	_stop_all()
	# เข้ากลุ่ม Player (กันพลาด)
	if not is_in_group("Player"):
		add_to_group("Player")

func _physics_process(delta: float) -> void:
	# ถ้ากำลังซ่อน: ไม่ขยับ ไม่อัปเดตฟิสิกส์
	if is_hidden:
		velocity = Vector2.ZERO
		return

	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# A/D only
	var dir := 0
	if Input.is_key_pressed(KEY_A): dir -= 1
	if Input.is_key_pressed(KEY_D): dir += 1
	velocity.x = dir * speed

	# W กระโดด
	if is_on_floor() and Input.is_key_pressed(KEY_W):
		velocity.y = -jump_speed

	move_and_slide()

	# flip ที่ Warp
	if dir != 0:
		warp.scale.x = -base_warp_scale.x if dir < 0 else base_warp_scale.x
		warp.scale.y =  base_warp_scale.y

	# state → เล่นอนิเมชันทีละตัว
	var target := "jump" if not is_on_floor() else ("walk" if dir != 0 else "idle")
	if target != _state:
		match target:
			"jump": _play_only(ap_jump, "Jump")
			"walk": _play_only(ap_walk, "Walk")
			"idle": _play_only(ap_idle, "Idle")
		_state = target

func _play_only(ap: AnimationPlayer, name: String) -> void:
	_stop_all()
	if ap:
		ap.play(name)

func _stop_all() -> void:
	if ap_idle and ap_idle.is_playing(): ap_idle.stop()
	if ap_walk and ap_walk.is_playing(): ap_walk.stop()
	if ap_jump and ap_jump.is_playing(): ap_jump.stop()

# ==== เพิ่ม: ฟังก์ชันที่ล็อกเกอร์จะเรียก ====

# locker: โหนดล็อกเกอร์, hide_point: จุดวางตัวผู้เล่น, face_left: ให้ผู้เล่นหันซ้ายไหม (หันออกจากตู้)
func hide_in_locker(locker: Node2D, hide_point: Node2D, face_left: bool) -> void:
	if is_hidden: return
	_hidden_locker = locker
	global_position = hide_point.global_position
	velocity = Vector2.ZERO
	is_hidden = true
	_saved_z_index = z_index
	z_index = 999  # ให้อยู่หน้าฉากเล็กน้อย

	# ปิดคอลลิชันทั้งหมดของผู้เล่น
	for c in find_children("*", "CollisionShape2D", true):
		(c as CollisionShape2D).disabled = true

	# หันออกจากล็อกเกอร์ + เล่น Idle
	warp.scale.x = -base_warp_scale.x if face_left else base_warp_scale.x
	warp.scale.y = base_warp_scale.y
	_play_only(ap_idle, "Idle")

func exit_locker() -> void:
	if not is_hidden: return
	is_hidden = false
	z_index = _saved_z_index

	# เปิดคอลลิชันกลับมา
	for c in find_children("*", "CollisionShape2D", true):
		(c as CollisionShape2D).disabled = false

	_hidden_locker = null
