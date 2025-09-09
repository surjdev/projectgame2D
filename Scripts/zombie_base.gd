extends CharacterBody2D
# ซอมบี้เดินสุ่ม-หยุด และหัน/ไล่ผู้เล่นเมื่อเข้ารัศมี Sense (Godot 4.x)

# ==== ปรับจาก Inspector ====
@export var walk_speed: float = 50.0              # ความเร็วเดินปกติ (wander)
@export var chase_speed: float = 90.0             # ความเร็วตอนไล่
@export var walk_time: Vector2 = Vector2(1.2, 2.5) # ระยะเวลาเดินแบบสุ่ม
@export var stop_time: Vector2 = Vector2(0.5, 1.2) # ระยะเวลาหยุดแบบสุ่ม
@export var chase_when_seen: bool = false          # true=ไล่ทันทีที่เห็น / false=เพียงแค่มอง

# ==== Node refs ====
@onready var visuals: Node2D = $Visuals
@onready var ap_walk: AnimationPlayer = $Visuals/Zombie1/WalkingZombie1
@onready var sense: Area2D = $Sense

# ==== Runtime ====
var base_scale: Vector2 = Vector2.ONE
var player: Node2D = null
var see_player: bool = false

# สถานะ wander
var state: String = "idle"   # "idle" | "walk"
var state_timer: float = 0.0
var walk_dir: int = 1        # -1 ซ้าย, 1 ขวา

func _ready() -> void:
	if visuals:
		base_scale = visuals.scale.abs()
	if sense:
		sense.body_entered.connect(_on_sense_entered)
		sense.body_exited.connect(_on_sense_exited)
	# หา player จาก group "player"
	player = get_tree().get_first_node_in_group("player") as Node2D
	_set_next_state("idle")

func _physics_process(delta: float) -> void:
	if see_player and player and is_instance_valid(player):
		var dx: float = player.global_position.x - global_position.x
		var dir: int = (-1 if dx < 0.0 else 1)
		_face(dir)
		if chase_when_seen:
			velocity.x = float(dir) * chase_speed
			_play_walk(true)
		else:
			velocity.x = 0.0
			_play_walk(false)
	else:
		# เดิน/หยุดแบบสุ่ม
		state_timer -= delta
		if state_timer <= 0.0:
			_set_next_state("walk" if state == "idle" else "idle")

		if state == "walk":
			velocity.x = float(walk_dir) * walk_speed
			_face(walk_dir)
			_play_walk(true)
		else:
			velocity.x = 0.0
			_play_walk(false)

	move_and_slide()

# -------- helpers --------
func _set_next_state(next: String) -> void:
	state = next
	if state == "walk":
		walk_dir = (-1 if (randi() % 2 == 0) else 1)
		state_timer = randf_range(walk_time.x, walk_time.y)
	else:
		state_timer = randf_range(stop_time.x, stop_time.y)

func _play_walk(moving: bool) -> void:
	if ap_walk == null:
		return
	if moving:
		if ap_walk.current_animation != "Walk" or not ap_walk.is_playing():
			ap_walk.play("Walk")
	else:
		if ap_walk.is_playing():
			ap_walk.stop()

func _face(dir: int) -> void:
	if visuals == null or dir == 0:
		return
	visuals.scale = Vector2(-base_scale.x, base_scale.y) if dir < 0 else base_scale

# -------- Sense (Area2D) --------
func _on_sense_entered(body: Node) -> void:
	if body.is_in_group("player"):
		see_player = true
		player = body as Node2D

func _on_sense_exited(body: Node) -> void:
	if body == player:
		see_player = false
