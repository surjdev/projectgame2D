extends Node2D


#func _on_start_button_pressed() -> void:
	#get_tree().change_scene_to_file("res://Scenes/cutscene/start_scene.tscn")

func _on_start_button_pressed() -> void:
	# Load the next scene as a PackedScene resource.
	var next_scene = load("res://Scenes/cutscene/start_scene.tscn")
	# Call the load_scene function from your SceneTransition autoload.
	# This will handle playing the animation and then changing the scene.
	SceneTransition.load_scene(next_scene)


func _on_exit_button_pressed() -> void:
	get_tree().quit()
