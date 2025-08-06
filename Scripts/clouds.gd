extends Node2D

@onready var cloud = preload("res://Scenes/cloud.tscn")

var number_of_possible_clouds = 7

enum side {
	LEFT,
	RIGHT
}

func _ready() -> void:
	$Timer.start(randi_range(1, 5))

func spawn_cloud():
	var cloud_instance = cloud.instantiate()
	cloud_instance.texture = load(str("res://Sprites/Background/Clouds/Cloud", randi_range(1,7), ".png"))
	
	var spawn_side
	if randi_range(0, 100) >= 50:
		spawn_side = side.LEFT
	else: spawn_side = side.RIGHT
	
	var position_y_offset = randi_range(-200, 100)
	
	match spawn_side:
		side.LEFT:
			cloud_instance.direction = Vector2($Right.global_position.x, $Right.global_position.y + position_y_offset)
			cloud_instance.position = Vector2($Left.position.x, $Left.position.y + position_y_offset)
		side.RIGHT:
			cloud_instance.position = Vector2($Right.position.x, $Right.position.y + position_y_offset)
			cloud_instance.direction = Vector2($Left.global_position.x, $Left.global_position.y + position_y_offset)
	
	var wind_speed = randf_range(10.0, 50.0)
	cloud_instance.speed = wind_speed
	
	call_deferred("add_child", cloud_instance)

func _on_timer_timeout() -> void:
	spawn_cloud()
	$Timer.start(randi_range(1, 15))
