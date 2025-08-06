extends Node

var ui

var player_node : player

var karma : int = 0

var next_karma_break_point = -5

signal danger_increases

func _ready() -> void:
	ui = get_node("/root/World/UI")

func get_current_karma() -> int:
	return karma

func add_karma(amount):
	karma += amount

func remove_karma(amount):
	karma -= amount
	if karma >= 0 : return
	if karma <= next_karma_break_point:
		danger_increases.emit()
		next_karma_break_point *= 2

func remove_all_karma():
	ui.remove_karma()
	next_karma_break_point = -5
