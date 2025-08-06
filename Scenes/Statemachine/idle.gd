extends Node

var character
var statemachine_node : StateMachine
var movement_node : NPC_Movement
var actions_node : Actions

func idle():
	character.idle()
func enter_state():
	pass
func exit_state():
	pass
