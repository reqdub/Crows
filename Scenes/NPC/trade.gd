extends Node

var character
var statemachine_node : StateMachine
var movement_node : NPC_Movement

func trade():
	movement_node.stop_moving()
	character.show_trade_icon()
