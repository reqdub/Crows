extends Node

var character
var statemachine_node : StateMachine
var movement_node : NPC_Movement
var actions_node : Actions

func knockdown():
	character.ammunition_component.drop_ammunition()
	movement_node.stop_moving()
