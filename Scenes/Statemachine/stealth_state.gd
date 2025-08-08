extends Node

var character
var statemachine_node : StateMachine
var movement_node : NPC_Movement

func stealth():
	character.stealth_component.stealth()

func remove_stealth():
	character.stealth_component.remove_stealth()
