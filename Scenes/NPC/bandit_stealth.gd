extends Node2D

class_name Bandit_Stealth

var guard_list : Array = []

var parent_npc : Bandit
var visual_comonent : Bandit_Visuals
var statemahine : StateMachine
var stealth_chance = randi_range(50, 100)

func setup_component(_parent_npc, _visual_comonent, _statemahine):
	parent_npc = _parent_npc
	visual_comonent = _visual_comonent
	statemahine = _statemahine

func check_stealth():
	if randi_range(0, 100) < stealth_chance: return true
	return false

func stealth():
	$StealthBush.visible = true
	var invisibility_tween = create_tween()
	invisibility_tween.tween_property(visual_comonent.visual_node, "modulate", Color(1.0, 1.0, 1.0, 0.1), 0.3)

func remove_stealth():
	parent_npc.say("bandit_stealth")
	$StealthBush.visible = false
	visual_comonent.visual_node.modulate = Color8(255, 255, 255, 255)

func _on_guard_sense_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Guard"):
		guard_list.append(body)
		parent_npc.combat_component.target_enemy = body
		if parent_npc.reactions_component.check_terminal_statuses(): return
		if parent_npc.combat_component.is_in_fight: return
		statemahine.change_state(statemahine.state.STEALTH)

func _on_guard_sense_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Guard"):
		if guard_list.has(body):
			guard_list.erase(body)
		if guard_list.is_empty():
			if parent_npc.reactions_component.check_terminal_statuses(): return
			parent_npc.movement_component.movement_target = Vector2.ZERO
			statemahine.change_state(statemahine.state.WALK)
