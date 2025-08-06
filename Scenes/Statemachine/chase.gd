extends Node

class_name chase_state

var character
var statemachine_node : StateMachine
var movement_node : NPC_Movement
var actions_node : Actions

func chase():
	movement_node.stop_moving()
	movement_node.move_to_point(movement_node.movement_target)
	%Visuals.play_chase_animation()

func enter_state():
	pass
func exit_state():
	pass
