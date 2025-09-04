extends Node2D



func _on_backto_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/menu/menu.tscn")
	
	

func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/levels/level_01.tscn")
