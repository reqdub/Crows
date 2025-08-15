extends Node

var character
var statemachine_node : StateMachine
var movement_node : NPC_Movement
func knockdown():
	movement_node.stop_moving()
