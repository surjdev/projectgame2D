# levelfinisher.gd
extends Area2D

@export var next_scene: PackedScene

var player_inside := false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_inside = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_inside = false

func _process(_delta: float) -> void:
	if player_inside and Input.is_key_pressed(KEY_S) and next_scene:
		get_tree().change_scene_to_packed(next_scene)
		print("touch + S")
