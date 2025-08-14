extends RigidBody2D

@onready var collectable_loot = preload("res://Scenes/Droppable/collectable_item.tscn")
@onready var non_collectable_loot = preload("res://Scenes/Droppable/non_collectable_item.tscn")
@export var item_deletion_time : float = 3.0
var timer
var has_loot : bool = true

var non_coollectable_drop_chance : int = 25

var bag_inventory : Dictionary = {
	"Collectable" : {
		"coin" : randi_range(0, 5)
	},
	"Non-Collectable" :
		{
			"apple" : randi_range(0, 2),
			"tomato" : randi_range(0, 2),
			"rotten_tomato" : randi_range(0, 2),
			"rotten_apple" : randi_range(0, 2)
		}
}

func _ready() -> void:
	randomize()
	apply_central_impulse(Vector2(randi_range(-300, 300), randi_range(-300, 300)))
	await get_tree().create_timer(10.0).timeout
	self.queue_free()

func drop_loot():
	for collectable_item : String in bag_inventory["Collectable"]:
		for number_of_items in bag_inventory["Collectable"][collectable_item]:
			var collectable_loot_instance = collectable_loot.instantiate()
			collectable_loot_instance.set_item(collectable_item)
			collectable_loot_instance.global_position = $DropPosition.global_position
			get_node("/root/World/Background/Walk_Area").call_deferred("add_child", collectable_loot_instance)
	for non_collectable_item : String in bag_inventory["Non-Collectable"]:
		for number_of_items in bag_inventory["Non-Collectable"][non_collectable_item]:
			if randi_range(0, 100) <= non_coollectable_drop_chance:
				var collectable_loot_instance = non_collectable_loot.instantiate()
				collectable_loot_instance.set_item(non_collectable_item)
				collectable_loot_instance.global_position = $DropPosition.global_position
				get_node("/root/World/Background/Drops").call_deferred("add_child", collectable_loot_instance)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Throwable"):
		call_deferred("set_contact_monitor", false)
		call_deferred("set_freeze_enabled", true)
		$Sprite2D.visible = false
		drop_loot()
		$CPUParticles2D.emitting = true

func _on_cpu_particles_2d_finished() -> void:
	self.queue_free()
