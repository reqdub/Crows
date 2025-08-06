extends Node2D

@export var dialogues : Resource
@export var walk_speed = randi_range(500, 1000)
@export var loot_chance = 25

@onready var loot = preload("res://item.tscn")
@onready var drop_area = get_node("/root/World/Drops")
@onready var signal_bus = get_node("/root/World/Signal_Bus")
@onready var statemachine = $StateMachine

var drop_position
var fear_chance = randi_range(0, 100)
var move_speed = randi_range(15, 15)
var panic_karma_factor : int = 2
var damage_taking_karma_factor : int = 5
var knockdown_karma_factor : int = 10
var base_karma_damage : int = 1

var is_dead = false
var is_panic = false
var is_damaged = false
var is_bag_dropped : bool = false
var is_knockdown : bool = false

var max_health : int = 10
var health : int = 10

signal health_changed(_amount)
signal karma_changed(_amount)
signal display_speech(_text)

func _ready() -> void:
	drop_position = $Drop_Position.global_position

func chech_is_feared(fear_modifier = 1):
	if fear_chance * fear_modifier <= randi_range(0, 100):
		statemachine.change_state(statemachine.state.PANIC)

func reaction_on(event : String):
	if (is_knockdown or is_panic or is_dead) : return
	match event:
		"Weapon" :  chech_is_feared()
		"Damaged_Character" : chech_is_feared()
		"Knockdown_Character" : chech_is_feared()

func drop_loot():
	var loot_amount = randi_range(1, 10)
	for i in loot_amount:
		var loot_instance = loot.instantiate()
		loot_instance.global_position = drop_position.global_position
		get_node("/root/World").call_deferred("add_child", loot_instance)

func drop_bag_and_stick():
	is_bag_dropped = true
	emit_signal("karma_changed", base_karma_damage * panic_karma_factor)
	emit_signal("display_speech", SpeechReplicas.random_dialogue("Panic"))
	var bag = load("res://Scenes/Items/Bag.tscn").instantiate()
	var stick = load("res://Scenes/Items/Stick.tscn").instantiate()
	bag.global_position = $Visual/Bag.global_position
	stick.global_position = $Visual/Bag/Stick.global_position
	stick.rotation = $Visual/Bag/Stick.rotation
	$Visual/Bag.queue_free()
	drop_area.call_deferred('add_child', bag)
	drop_area.call_deferred('add_child', stick)

func drop_stick():
	emit_signal("karma_changed", base_karma_damage * panic_karma_factor)
	emit_signal("display_speech", SpeechReplicas.random_dialogue("Panic"))
	var stick = load("res://Scenes/Items/Stick.tscn").instantiate()
	stick.global_position = $Character/Bag/Stick.global_position
	stick.rotation = $Character/Bag/Stick.rotation
	get_parent().call_deferred('add_child', stick)
	$Character/Bag/Stick.queue_free()

func drop_bag():
	emit_signal("karma_changed", base_karma_damage * panic_karma_factor)
	emit_signal("display_speech", SpeechReplicas.random_dialogue("Panic"))
	var bag = load("res://Scenes/Items/Bag.tscn").instantiate()
	bag.global_position = $Character/Bag/Bag.global_position
	$Character/Bag/DampedSpringJoint2D.queue_free()
	$Character/Bag/Anchor.queue_free()
	$Character/Bag/Bag.queue_free()
	get_parent().call_deferred('add_child', bag)

func _on_bag_body_entered(body: Node) -> void:
	if body.is_in_group("Throwable"):
		drop_bag()
		$HitSound.play()
		drop_loot()
		body.destroy()
		chech_is_feared()

func _on_head_collision_body_entered(body: Node2D) -> void:
	if body.is_in_group("Throwable"):
		body.destroy()
		headshot()

func headshot():
	emit_signal("karma_changed", base_karma_damage * panic_karma_factor)
	emit_signal("display_speech", SpeechReplicas.random_dialogue("knockdown"))
	statemachine.change_state(statemachine.state.KNOCKDOWN)

func knockdown():
	get_parent().stop_moving()
	if not is_bag_dropped: drop_bag_and_stick()
	$Visual/Head/HeadCollision.queue_free()
	$AnimationPlayer.play("Knockdown")
	await $AnimationPlayer.animation_finished
	statemachine.change_state(statemachine.state.PANIC)

func run():
	if is_damaged: $AnimationPlayer.play("Walk_Damaged")
	else: $AnimationPlayer.play("Walk")
	get_parent().move_to_point()

func walk():
	$AnimationPlayer.play("Walk")
	get_parent().move_to_point()
