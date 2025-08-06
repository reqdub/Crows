extends Node

var character
var statemachine_node : StateMachine
var movement_node : NPC_Movement
var actions_node : Actions
#Заметив что-то подозрительное, NPC пройдет еще пару шагов
var delay_before_stop : float = randf_range(0.1, 0.3)
#Сколько времени NPC будет стоять на одном месте
var time_in_caution : float = randf_range(0.3, 0.8)
var delay_timer : SceneTreeTimer
var caution_timer : SceneTreeTimer

var is_stopped : bool = false

func caution():
	if not is_stopped:
		delay_timer = get_tree().create_timer(delay_before_stop)
		await delay_timer.timeout
		if not is_stopped:
			movement_node.stop_moving()
	if not is_stopped:
		caution_timer = get_tree().create_timer(time_in_caution)
		await caution_timer.timeout
		if not is_stopped:
			Logger.log(character.npc_name, " Закончилось время ожидания в состоянии осторожности, перехожу в состояние WALK")
			statemachine_node.change_state(statemachine_node.state.WALK)
	is_stopped = false

func stop_cautions():
	is_stopped = true
	if delay_timer != null:
		delay_timer.time_left = 0
	if caution_timer != null:
		caution_timer.time_left = 0
