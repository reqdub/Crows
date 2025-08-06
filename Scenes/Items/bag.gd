extends RigidBody2D

@onready var loot = preload("res://item.tscn")
@export var item_deletion_time : float = 3.0
var timer
var has_loot : bool = true
var loot_in_bag : Dictionary = {
	"Money" : randi_range(0, 10)
}

func _ready() -> void:
	randomize()
	apply_central_impulse(Vector2(randi_range(-300, 300), randi_range(-300, 300)))
	await get_tree().create_timer(10.0).timeout
	self.queue_free()

func drop_loot():
	if loot_in_bag.is_empty(): return
	var loot_dict_keys : Array = loot_in_bag.keys()
	var random_item_in_bag = loot_dict_keys[randi_range(0, loot_dict_keys.size() - 1)]
	var number_of_items = loot_in_bag[random_item_in_bag]
	var random_number_of_items = randi_range(0, number_of_items)
	loot_in_bag[random_item_in_bag] -= random_number_of_items
	for i in random_number_of_items:
		var loot_instance = loot.instantiate()
		loot_instance.set_item(random_item_in_bag)
		loot_instance.global_position = $DropPosition.global_position
		get_node("/root/World/Background/Walk_Area").call_deferred("add_child", loot_instance)
	if number_of_items == 0:
		loot_in_bag.erase(random_item_in_bag)
		return

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Throwable"):
		call_deferred("set_contact_monitor", false)
		call_deferred("set_freeze_enabled", true)
		$Sprite2D.visible = false
		drop_loot()
		$CPUParticles2D.emitting = true

func _on_cpu_particles_2d_finished() -> void:
	self.queue_free()
