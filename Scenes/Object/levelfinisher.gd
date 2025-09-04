extends Area2D

@export var next_scene: PackedScene

func _ready() -> void:
	# ให้แน่ใจว่า Area2D ตรวจการทับซ้อนได้
	monitoring = true
	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	# 1) เช็กว่ามีตัวที่อยู่ใน group "player" / "Player" ทับซ้อนอยู่ไหม (คำนวณสดทุกเฟรม)
	var player_is_inside := false
	for b in get_overlapping_bodies():
		if b.is_in_group("player") or b.is_in_group("Player"):
			player_is_inside = true
			break

	# 2) ให้เปลี่ยนฉากเฉพาะ “กดครั้งเดียว” ตอนที่กำลังยืนในประตูจริง ๆ
	#    แนะนำให้แมปปุ่ม S เป็น action ชื่อ "interact"
	if player_is_inside and Input.is_action_just_pressed("interact") and next_scene:
		get_tree().change_scene_to_packed(next_scene)
