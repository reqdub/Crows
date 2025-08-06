extends Node

class_name TaskManager

var task_list: Array = []  # Очередь задач
var is_running: bool = false  # Флаг выполнения текущей задачи

# Добавляет функцию в очередь (с аргументами, если нужно)
func add_task(task_callable: Callable) -> void:
	if task_list.has(task_callable) : return
	Logger.log(str(task_callable), " Добавлена задача")
	task_list.push_back({"callable": task_callable, "args": null})
	process_next_task()

func clear_tasks():
	task_list.clear()

# Запускает следующую задачу, если очередь не пуста
func process_next_task() -> void:
	if is_running or task_list.is_empty():
		return
	is_running = true
	var current_task = task_list.pop_front()
	Logger.log(str(current_task["callable"]), " Запущена")
	 #Вызываем задачу с её аргументами
	var task_result = await current_task["callable"].call()
	# Если задача возвращает сигнал (например, анимация или HTTP-запрос), 
	# ждём его завершения через await
	if task_result is Signal:
		await task_result
	Logger.log(str(current_task["callable"]), " Завершена")
	# Иначе сразу переходим к следующей
	_on_task_completed()

# Обработчик завершения задачи
func _on_task_completed() -> void:
	is_running = false
	process_next_task()  # Рекурсивный вызов для следующей задачи
