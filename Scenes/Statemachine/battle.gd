extends Node

class_name battle_state

var character
var statemachine_node : StateMachine
var movement_node : NPC_Movement
var actions_node : Actions

func battle():
	movement_node.stop_moving()
	if character.health_component.is_knockdown: return
	await character.combat_component.start_brawl()
