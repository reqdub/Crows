extends Node2D

@onready var drop_area = get_node("/root/World/Background/Drops")

var is_bag_dropped : bool = false

func _ready() -> void:
	%Character.add_ammunition(self)

func drop():
	is_bag_dropped = true
	var bag = load("res://Scenes/Items/Bag.tscn").instantiate()
	bag.global_position = self.global_position
	drop_area.call_deferred('add_child', bag)
	self.queue_free()

func _on_bag_body_entered(body: Node) -> void:
	if body.is_in_group("Throwable"):
		drop()
		AudioManager.play_sound(SoundCache.hit_sound)
		body.destroy()
