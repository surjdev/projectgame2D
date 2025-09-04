extends Node2D

const MAX_HEALTH = 100
var health = MAX_HEALTH

func _ready() -> void:
	update_health_ui()
	$CanvasLayer/HealthBar.max_value = MAX_HEALTH

func update_health_ui():
	#set_health_label()
	set_health_bar()

#func set_health_label() -> void:
	#$CanvasLayer/HealthLabel.text = "Health : %s" % health

func set_health_bar() -> void:
	$CanvasLayer/HealthBar.value = health

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		damage()

func damage() -> void:
	health -= 20
	if health < 0:
		health = MAX_HEALTH
	update_health_ui()
