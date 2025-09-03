# InteractPlayer.gd  (flip ที่ Warp, Idle/Walk/Jump แยกกัน)
extends CharacterBody2D

@export var speed: float = 180.0
@export var jump_speed: float = 200.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float

@onready var warp: Node2D = $Warp
@onready var ap_idle: AnimationPlayer = $Warp/Player/Idle
@onready var ap_walk: AnimationPlayer = $Warp/Player/Walk
@onready var ap_jump: AnimationPlayer = $Warp/Player/Jump

var base_warp_scale := Vector2.ONE
var _state := ""   # "idle" | "walk" | "jump"

func _ready() -> void:
	base_warp_scale = warp.scale.abs()
	_stop_all()

func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# A/D only (S ไม่ทำอะไร)
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
