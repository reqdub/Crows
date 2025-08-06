extends RigidBody2D

class_name droppable_item

var collect_area
var is_collected = false
var direction = Vector2(0,0)
var speed = 1000
var reserve_collector

func _ready() -> void:
	var random_x_impulse = randi_range(-100, -200)
	var random_y_impulse = randi_range(100, -300)
	apply_impulse(Vector2(random_x_impulse, random_y_impulse), Vector2.ZERO)
	if collect_area == null:
		collect_area = get_node("/root/World/Background/CollectArea")
	reserve_collector = get_node("/root/World/Background/CollectArea")
	$Timer.start()

func _on_body_entered(_body: Node) -> void:
	AudioManager.play_sound(SoundCache.coin_flip_sound)

func _physics_process(delta: float) -> void:
	if not is_collected: return
	if collect_area != null:
		global_position -= (global_position.direction_to(collect_area.global_position).normalized()) * -1 * speed * delta

func set_item(item_name : String, custom_collector = null):
	collect_area = custom_collector
	match item_name:
		"Money" : $Sprite2D.texture = load("res://Sprites/Items/coin.png")

func destroy():
	$Timer.stop()
	self.queue_free()

func _on_timer_timeout() -> void:
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	gravity_scale = 0.0
	is_collected = true
	if collect_area == null:
		direction = global_position.direction_to(reserve_collector.global_position).normalized() * -1
	await get_tree().create_timer(4.0).timeout
	self.queue_free()
