extends Node

class_name NPC_Karma

var parent_npc

var karma_multiplier : int = 5

signal karma_changed(amount : int)

func setup_component(_parent_npc):
	parent_npc = _parent_npc

func add_karma(amount):
	karma_changed.emit(amount * karma_multiplier)

func remove_karma(amount):
	Logger.log(parent_npc.npc_name, str(" отнимаю ", amount, " кармы"))
	karma_changed.emit(-amount * karma_multiplier)

func calculate_karma(damage_amount, is_headshot, health_before_damage_taken, current_health, max_health):
	if current_health != max_health:
		karma_multiplier += 1
	if damage_amount >= max_health:
		return
	elif damage_amount > health_before_damage_taken:
		karma_multiplier += 1
		remove_karma(randi_range(1, 3))
	elif is_headshot and damage_amount <= current_health:
		karma_multiplier += 1
		remove_karma(randi_range(1, 2))
	elif not is_headshot and damage_amount <= current_health:
		remove_karma(randi_range(1, 2))
	else:
		remove_karma(randi_range(1, 3))
