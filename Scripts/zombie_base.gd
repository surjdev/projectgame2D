# ZombieBase_Optimized.gd — รองรับหลาย AnimationPlayer (Walk/Biting แยกกัน)
extends CharacterBody2D

# -------- Gameplay --------
@export var speed: float = 70.0
@export var max_hp: int = 40
@export var damage: int = 10
@export var bite_range: float = 48.0
@export var bite_cooldown: float = 0.8
@export var walk_anim_speed: float = 1.0

# ชื่อคลิปมาตรฐาน (ปรับให้ตรงกับสกินของคุณ)
@export var anim_walk: String = "Walk"
@export var anim_bite: String = "Biting"  # ค่าเริ่มต้นตรงกับ BitingZombie1
@export var anim_die:  String = "Die"
@export var anim_hurt: String = "Hurt"

# -------- เลือกสกินแบบ PackedScene (ประหยัดทรัพยากร) --------
@export var visual_scenes: Array[PackedScene] = []   # เช่น zombie_1.tscn, zombie_2.tscn
@export var visual_index: int = -1                   # -1 = สุ่ม, อื่น ๆ = ดัชนี

# -------- Nodes --------
@onready var visuals_slot: Node2D = $Visuals
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var screen: VisibleOnScreenNotifier2D = $Screen

# -------- Internals --------
var active_visual: Node2D
var flip_target: Node2D
var base_scale := Vector2.ONE

# โหมด AnimationPlayer เดียว
var anim: AnimationPlayer

# โหมดหลาย AnimationPlayer (เช่น WalkingZombie1 / BitingZombie1)
var ap_walk: AnimationPlayer
var ap_bite: AnimationPlayer
var ap_die: AnimationPlayer
var ap_hurt: AnimationPlayer
var ap_all: Array[AnimationPlayer] = []
var use_multi_players := false

var hp := 0
var target: Node2D = null
var state := "walk"               # walk | bite | dead
var bite_cd_timer := 0.0
var doing_bite := false

func _ready() -> void:
	# ให้แน่ใจว่ามีโหนด Visuals
	if visuals_slot == null:
		visuals_slot = Node2D.new()
		visuals_slot.name = "Visuals"
		add_child(visuals_slot)

	# 1) อินสแตนซ์สกินจาก Array ถ้ามี ไม่งั้นใช้ลูกตัวแรกใต้ Visuals
	if not visual_scenes.is_empty():
		_instance_one_visual_from_array()
	else:
		_use_first_child_under_visuals()

	# 2) signals ชน/ถูกดาเมจ
	if hitbox:
		hitbox.monitoring = false
		hitbox.body_entered.connect(_on_Hitbox_body_entered)
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	# 3) on-screen culling (ประหยัด CPU)
	if screen:
		screen.screen_entered.connect(_on_screen_entered)
		screen.screen_exited.connect(_on_screen_exited)

	# 4) หา player
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0] as Node2D

	hp = max_hp

func _physics_process(delta: float) -> void:
	if state == "dead":
		return
	if bite_cd_timer > 0.0:
		bite_cd_timer -= delta

	# เดินเข้าหา player บนแกน X
	if state == "walk" and target and is_instance_valid(target):
		var dx := target.global_position.x - global_position.x
		if abs(dx) > bite_range:
			var dir: float = sign(dx)
			velocity.x = dir * speed
			_face(dir)
			_play_kind("walk", walk_anim_speed)
		else:
			velocity.x = 0.0
			if bite_cd_timer <= 0.0 and not doing_bite:
				_start_bite()

	move_and_slide()

func _start_bite() -> void:
	if state == "dead": return
	state = "bite"
	doing_bite = true
	bite_cd_timer = bite_cooldown
	velocity.x = 0.0
	_face(sign(target.global_position.x - global_position.x))
	if hitbox: hitbox.monitoring = true
	_play_kind("bite", 1.0)
	# รอให้ท่ากัดจบเฉพาะ player ที่กำลังเล่น
	if use_multi_players and ap_bite != null:
		await ap_bite.animation_finished
	elif not use_multi_players and anim != null:
		await anim.animation_finished
	if hitbox: hitbox.monitoring = false
	doing_bite = false
	if state != "dead":
		state = "walk"

# ---------- Visual instancing ----------
func _instance_one_visual_from_array() -> void:
	var idx := visual_index
	if idx < 0 or idx >= visual_scenes.size():
		idx = randi() % visual_scenes.size()
	var vis := visual_scenes[idx].instantiate()
	if vis == null:
		push_error("PackedScene at index %d is null" % idx)
		return
	visuals_slot.add_child(vis)
	vis.owner = self
	vis.visible = true
	if vis is Node2D:
		(vis as Node2D).position = Vector2.ZERO
	active_visual = vis as Node2D
	_init_visual_refs()

func _use_first_child_under_visuals() -> void:
	var kids := visuals_slot.get_children()
	if kids.is_empty():
		push_warning("No visual assigned: add child under 'Visuals' or set 'visual_scenes[]'.")
		return
	for i in range(kids.size()):
		kids[i].visible = (i == 0)
	active_visual = kids[0] as Node2D
	if active_visual is Node2D:
		(active_visual as Node2D).position = Vector2.ZERO
	_init_visual_refs()

func _init_visual_refs() -> void:
	# โหนดสำหรับ flip ซ้าย/ขวา
	flip_target = _find_flip_target(active_visual)
	if flip_target == null: flip_target = active_visual
	base_scale = flip_target.scale.abs()

	# รวบรวม AnimationPlayer ทั้งหมดในสกิน
	ap_all.clear()
	_collect_animplayers(active_visual, ap_all)

	if ap_all.size() == 0:
		anim = null
		use_multi_players = false
		push_warning("No AnimationPlayer found inside visual.")
	elif ap_all.size() == 1:
		anim = ap_all[0]
		use_multi_players = false
	else:
		use_multi_players = true
		anim = null
		ap_walk = null; ap_bite = null; ap_die = null; ap_hurt = null
		# จับคู่จาก "ชื่อคลิป" ภายในแต่ละ AnimationPlayer (ไม่สนตัวพิมพ์)
		for ap in ap_all:
			var lowers: Array[String] = []
			for n in ap.get_animation_list():
				lowers.append(String(n).to_lower())
			if ap_walk == null and lowers.has("walk"):
				ap_walk = ap
			if ap_bite == null and (lowers.has("bite") or lowers.has("biting")):
				ap_bite = ap
			if ap_die == null and (lowers.has("die") or lowers.has("death")):
				ap_die = ap
			if ap_hurt == null and (lowers.has("hurt") or lowers.has("hit")):
				ap_hurt = ap
		# กันพลาด
		if ap_walk == null and ap_all.size() > 0: ap_walk = ap_all[0]
		if ap_bite == null and ap_all.size() > 0: ap_bite = ap_all[0]

func _find_flip_target(n: Node) -> Node2D:
	if n is Skeleton2D or n is Sprite2D or n is AnimatedSprite2D: return n
	for c in n.get_children():
		var r := _find_flip_target(c)
		if r: return r
	return null

func _collect_animplayers(n: Node, out: Array[AnimationPlayer]) -> void:
	if n is AnimationPlayer:
		out.append(n)
	for c in n.get_children():
		_collect_animplayers(c, out)

# ---------- Play helpers ----------
func _play_kind(kind: String, speed_scale: float = 1.0) -> void:
	if use_multi_players:
		var ap := _get_player_for_kind(kind)
		if ap == null: return
		# หยุดตัวอื่นก่อนเล่นตัวที่ต้องการ
		for other in ap_all:
			if other != ap and other.is_playing():
				other.stop()
		var clip := _choose_clip_for_player(ap, kind)
		if clip == "": return
		ap.speed_scale = speed_scale
		ap.play(clip, 0.05)
	else:
		if anim == null: return
		var clip_single := _resolve_anim(kind)
		if clip_single == "": return
		anim.speed_scale = speed_scale
		anim.play(clip_single, 0.05)

func _get_player_for_kind(kind: String) -> AnimationPlayer:
	match kind:
		"walk": return ap_walk
		"bite": return ap_bite
		"die":  return ap_die
		"hurt": return ap_hurt
	return null

func _choose_clip_for_player(ap: AnimationPlayer, kind: String) -> String:
	# ใช้ชื่อที่ตั้งใน Inspector ก่อน
	var pref := ""
	match kind:
		"walk": pref = anim_walk
		"bite": pref = anim_bite
		"die":  pref = anim_die
		"hurt": pref = anim_hurt
	if pref != "" and ap.has_animation(pref):
		return pref

	# ลองชื่อมาตรฐาน
	var try_names := ["Walk", "Bite", "Biting", "Die", "Hurt"]
	for n in try_names:
		if ap.has_animation(n):
			return n

	# เลือกคลิปแรกที่ไม่ใช่ RESET
	for n in ap.get_animation_list():
		if String(n).to_upper() != "RESET":
			return n

	# เหลือแต่ RESET หรือไม่มีคลิปเลย
	var list := ap.get_animation_list()
	return list[0] if list.size() > 0 else ""

func _resolve_anim(kind: String) -> String:
	if anim == null: return ""
	match kind:
		"walk":
			if anim.has_animation(anim_walk): return anim_walk
			if anim.has_animation("Walk"):    return "Walk"
		"bite":
			if anim.has_animation(anim_bite): return anim_bite
			if anim.has_animation("Bite"):    return "Bite"
			if anim.has_animation("Biting"):  return "Biting"
		"die":
			if anim.has_animation(anim_die):  return anim_die
			if anim.has_animation("Die"):     return "Die"
		"hurt":
			if anim.has_animation(anim_hurt): return anim_hurt
			if anim.has_animation("Hurt"):    return "Hurt"
	return ""

# ---------- Facing ----------
func _face(dir: float) -> void:
	if dir == 0 or flip_target == null: return
	flip_target.scale = Vector2(-base_scale.x, base_scale.y) if dir < 0 else base_scale

# ---------- Damage ----------
func _on_hurtbox_area_entered(area: Area2D) -> void:
	if not area.is_in_group("player_attack"): return
	var dmg_val = area.get("damage")
	var amt: int = int(dmg_val) if (dmg_val is int or dmg_val is float) else 10
	apply_damage(amt)

func apply_damage(amount: int) -> void:
	if state == "dead": return
	hp -= amount
	if hp <= 0:
		_die()
	else:
		_play_kind("hurt", 1.0)

func _die() -> void:
	state = "dead"
	velocity = Vector2.ZERO
	if hitbox:  hitbox.monitoring = false
	if hurtbox: hurtbox.monitoring = false
	_play_kind("die", 1.0)
	if use_multi_players and ap_die != null:
		await ap_die.animation_finished
	elif not use_multi_players and anim != null and anim.has_animation(_resolve_anim("die")):
		await anim.animation_finished
	queue_free()

func _on_Hitbox_body_entered(body: Node) -> void:
	if state != "bite": return
	if body.is_in_group("player") and "apply_damage" in body:
		body.apply_damage(damage)

# ---------- On-screen culling ----------
func _on_screen_entered() -> void:
	set_physics_process(true)
	set_process(true)

func _on_screen_exited() -> void:
	set_physics_process(false)
	set_process(false)
	velocity = Vector2.ZERO
