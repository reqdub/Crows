extends Node

var character
var statemachine_node : StateMachine
var movement_node : NPC_Movement

func panic():
	var distance_to_despawn_point = character.global_position.distance_to(character.despawn_position.global_position)
	var distance_to_spawn_point = character.global_position.distance_to(character.spawn_position.global_position)
	if distance_to_despawn_point < distance_to_spawn_point:
		movement_node.movement_target = character.despawn_position.global_position
	else:
		movement_node.movement_target = character.spawn_position.global_position
	character.is_panic = true
	var panic_is_triggered_by = character.health_component.damage_source_list[-1]
	character.ammunition_component.drop_ammunition(panic_is_triggered_by)
	movement_node.walk_speed *= randf_range(2.0, 2.5)
	movement_node.movement_target = Vector2.ZERO
	movement_node.move_to_point()
