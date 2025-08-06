extends Node2D

@onready var animation_player = %AnimationPlayer
@onready var visual = $"../Visual"
@onready var head = $"../Visual/Head"
@onready var body = $"../Visual/Body"
@onready var left_hand = $"../Visual/LeftHand"
@onready var right_hand = $"../Visual/RightHand"

var parent

var is_praying : bool = false
var is_pray_cancelled : bool = false

func setup_component(_parent):
	parent = _parent

func pray():
	parent.block_player_control.emit(true)
	await parent.walk_to(parent.statue)
	is_praying = true
	animation_player.play("Pray")
	await animation_player.animation_finished
	is_praying = false
	parent.emit_signal("pray_finished")
	animation_player.stop()
	await parent.walk_to(parent.initial_position)
	parent.block_player_control.emit(false)

func stop_praying():
	animation_player.stop()
	cancel_pray()
	is_praying = false

func cancel_pray():
	parent.is_pray_cancelled = true
	$Timer.stop()
	if parent.movement_tween:
		parent.movement_tween.kill()
	is_pray_cancelled = false

func apply_head_damage():
	head.frame = 2

func apply_body_damage():
	pass
