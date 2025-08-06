extends Node

var character
var statemachine_node : StateMachine
var movement_node : NPC_Movement
var actions_node : Actions
var delay_timer : SceneTreeTimer
var warning_timer : SceneTreeTimer
var warning_time : float = randf_range(0.4, 1.0)
var delay_before_stop : float = randf_range(0.2, 0.5)

var is_stopped : bool = false

func warning():
	if not is_stopped:
		delay_timer = get_tree().create_timer(delay_before_stop)
		await delay_timer.timeout
	movement_node.stop_moving()
	if not is_stopped:
		warning_timer = get_tree().create_timer(warning_time)
		await warning_timer.timeout
	if not is_stopped:
		if character.combat_component.is_in_fight: return
		Logger.log(character.npc_name, " Закончилось время ожидания в состоянии предупреждения, перехожу в состояние WALK")
		statemachine_node.change_state(statemachine_node.state.WALK)
		is_stopped = false
	is_stopped = false

func stop_warnings():
	is_stopped = true
	if delay_timer != null:
		delay_timer.time_left = 0
		delay_timer = null
	if warning_timer != null:
		warning_timer.time_left = 0
		warning_timer = null
