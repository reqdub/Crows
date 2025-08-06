extends Node2D

@onready var hit_sound = load("res://Sounds/SFX/hit.wav")
@onready var audio = $"../../AudioStreamPlayer2D"
@onready var drop_area = get_node("/root/World/Background/Drops")

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
		audio.stream = hit_sound
		audio.play()
		body.destroy()

func drop_bag_and_stick():
	is_bag_dropped = true
	var bag = load("res://Scenes/Items/Bag.tscn").instantiate()
	var stick = load("res://Scenes/Items/Stick.tscn").instantiate()
	bag.global_position = self.global_position
	stick.global_position = $Stick.global_position
	stick.rotation = $Stick.rotation
	self.queue_free()
	drop_area.call_deferred('add_child', bag)
	drop_area.call_deferred('add_child', stick)

func drop_stick():
	var stick = load("res://Scenes/Items/Stick.tscn").instantiate()
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
