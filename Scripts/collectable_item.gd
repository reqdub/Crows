extends RigidBody2D

class_name droppable_item

var collect_area
var is_collected = false
var direction = Vector2(0,0)
var speed = 1000
var reserve_collector
var item_texture
var item_amount : int = 1

func _ready() -> void:
	var random_x_impulse = randi_range(-5, -10)
	var random_y_impulse = randi_range(5, -10)
	apply_impulse(Vector2(random_x_impulse, random_y_impulse), Vector2.ZERO)
	if collect_area == null:
		collect_area = get_node("/root/World/Background/CollectArea")
	reserve_collector = get_node("/root/World/Background/CollectArea")
	$Sprite2D.texture = item_texture
	$Timer.start()

func _on_body_entered(_body: Node) -> void:
	AudioManager.play_sound(SoundCache.coin_flip_sound)

func _physics_process(delta: float) -> void:
	if not is_collected: return
	if collect_area != null:
		global_position -= (global_position.direction_to(collect_area.global_position).normalized()) * -1 * speed * delta

func set_item(item_name : String, custom_collector = null, item_category : String = "", _item_amount : int = 1):
	collect_area = custom_collector
	item_amount = _item_amount
	if item_category == "":
		if _item_amount != 1:
			pass
		match item_name:
			"coin" : item_texture = load("res://Sprites/Items/" + item_name + ".png")

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
