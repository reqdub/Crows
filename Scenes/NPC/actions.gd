extends Node
class_name Actions

var current_action: Tween
var cancel_tween := false

var actions_queue: Array = []
var action_descriptions: Dictionary = {}
var is_running := false

func add_action(tween: Tween, description: String = "") -> void:
	Logger.log("Добавлено действие", description)
	actions_queue.append(tween)
	action_descriptions[tween] = description

	if not is_running:
		Logger.log("Начато выполнение действия", description)
		await _run_next_action()
		Logger.log("Действие выполнено", description)

func _run_next_action() -> void:
	is_running = true
	current_action = actions_queue.pop_front()

	while current_action.is_running():
		if cancel_tween:
			Logger.log("Текущее действие прервано", action_descriptions.get(current_action, ""))
			current_action.kill()
			cancel_tween = false
			break
		await get_tree().process_frame

	action_descriptions.erase(current_action)
	current_action = null
	is_running = false

	if not actions_queue.is_empty():
		await _run_next_action()

func cancel_action(tween: Tween) -> void:
	if tween == current_action:
		Logger.log("Отмена текущего действия", action_descriptions.get(tween, ""))
		cancel_tween = true
	else:
		actions_queue.erase(tween)
		Logger.log("Удалено ожидающее действие", action_descriptions.get(tween, ""))
		action_descriptions.erase(tween)

func cancel_all_actions() -> void:
	Logger.log("Отмена всех действий. В очереди:", str(actions_queue.size()))
	if is_running:
		Logger.log("Прерывание текущего действия", action_descriptions.get(current_action, ""))
		cancel_tween = true

	for tween in actions_queue:
		Logger.log("Удалено ожидающее действие", action_descriptions.get(tween, ""))
		action_descriptions.erase(tween)

	actions_queue.clear()
