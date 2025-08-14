extends Node2D

@onready var drop_area = get_node("/root/World/Background/Drops")
@onready var weapon = preload("res://Scenes/Droppable/droppable_weapon.tscn")

var is_bag_dropped : bool = false

func _ready() -> void:
	%Ammunition.add_ammunition(self)

func drop():
	if is_bag_dropped:
		drop_stick()
	else:
		drop_bag_and_stick()

func _on_bag_body_entered(body: Node) -> void:
	if body.is_in_group("Throwable"):
		drop_bag()
		AudioManager.play_sound(SoundCache.hit_sound)
		body.destroy()

func drop_bag_and_stick():
	is_bag_dropped = true
	drop_bag()
	drop_stick()
	self.queue_free()

func drop_stick():
	var stick : droppable_weapon = weapon.instantiate()
	stick.set_item("polearm", "stick", %Health.damage_source_list[-1])
	stick.global_position = $Stick.global_position
	stick.rotation = $Stick.rotation
	drop_area.call_deferred('add_child', stick)
	$Stick.queue_free()

func drop_bag():
	is_bag_dropped = true
	var bag = load("res://Scenes/Items/Bag.tscn").instantiate()
	bag.global_position = self.global_position
	$DampedSpringJoint2D.queue_free()
	$Anchor.queue_free()
	$Bag.queue_free()
	drop_area.call_deferred('add_child', bag)
