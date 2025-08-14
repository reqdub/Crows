# npc_movement.gd
extends Node
class_name NPC_Movement

@onready var view_area = %ViewArea
# References to other components and nodes
var parent_npc
var statemachine_node : StateMachine
var reactions_component
var health_component
var visual_component

# Movement parameters
@export var walk_speed = 3 # Default value, can be overridden per NPC
@export var base_speed = 15 # From your `_ready` in npc.gd, consider if this is a default or calculated
@export var speed_multiplier = 1.0 # For temporary speed changes (e.g., panic, caution)

# Internal movement state
var movement_target : Vector2 = Vector2.ZERO
var point_before_chase : Vector2 = Vector2.ZERO

func setup_component(_parent_npc, _statemachine_node, _reactions_component, _health_component, _visual_component) -> void:
	# Initialize walker_node speed
	parent_npc = _parent_npc
	statemachine_node = _statemachine_node
	reactions_component =_reactions_component
	health_component = _health_component
	visual_component = _visual_component
	walk_speed = base_speed * speed_multiplier # Start with base speed

# --- Core Movement Functions ---
func move_to_point(target_point: Vector2 = Vector2.ZERO) -> void:
	if target_point == Vector2.ZERO:
		movement_target = parent_npc.despawn_position.global_position
		Logger.log(parent_npc.npc_name, " цель движения - точка деспавна")
	else:
		Logger.log(parent_npc.npc_name, str(" цель движения - ", target_point))
		movement_target = target_point
	Logger.log(parent_npc.npc_name, str(" Двигаюсь из ", parent_npc.global_position, " к ",  movement_target))
	look_at_direction(movement_target)
	var move_direction = parent_npc.global_position.direction_to(movement_target).normalized()
	var move_speed = base_speed * walk_speed
	parent_npc.set_movement(move_direction, move_speed)
	visual_component.play_walk_animation()

func stop_moving() -> void:
	parent_npc.set_movement(Vector2.ZERO, 0)
	Logger.log(parent_npc.npc_name, " движение остановлено")
	visual_component.stop_movement_animation()

func set_move_speed(speed: float) -> void:
	speed = speed

func look_at_direction(target : Vector2):
	if view_area != null:
		view_area.rotation = parent_npc.global_position.angle_to_point(target)
	if parent_npc.global_position.x < target.x:
		%Visual.scale = Vector2(1,1)
		%Dialogue/Background.global_position = %Dialogue/LeftSide.global_position
	else: 
		%Visual.scale = Vector2(-1,1)
		%Dialogue/Background.global_position = %Dialogue/RightSide.global_position

func move_away_from_target(target_position: Vector2) -> void:
	var current_pos = parent_npc.global_position
	var direction_away = (current_pos - target_position).normalized()
	movement_target = current_pos + direction_away * 500
	move_to_point(movement_target)

# --- Reactions to external events that affect movement ---
func _on_reactions_player_detected(player_node: Node2D) -> void:
	# If the NPC is supposed to chase upon detection, this is where it would be set.
	# For now, this is just an example of how reactions can feed into movement.
	# The actual state change to CHASE is handled by Reactions/Combat.
	if parent_npc.reactions_component.is_enemy_in_sight \
	and parent_npc.reactions_component.potential_enemy == player_node:
		movement_target = player_node.global_position
		point_before_chase = parent_npc.global_position
