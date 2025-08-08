extends Node

var character
var statemachine_node : StateMachine
var movement_node : NPC_Movement

func walk():
	movement_node.move_to_point()
func enter_state():
	pass
func exit_state():
	pass
