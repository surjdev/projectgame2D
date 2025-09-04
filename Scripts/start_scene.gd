extends Node2D
func _ready() -> void:
	$BombAnimation.play("Bomb")


func _on_bomb_animation_animation_finished(anim_name: StringName) -> void:
	# Change the scene to the next level.
	# Replace "res://levels/level_01.tscn" with your target scene path.
	var next_scene = load("res://Scenes/levels/level_01.tscn")
	SceneTransition.load_scene(next_scene)
