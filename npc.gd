class_name TaskManager
extends Node2D

var task_list: Array = []  # Очередь задач
var is_running: bool = false  # Флаг выполнения текущей задачи

func _ready():
	add_task(task1)
	add_task(task2)

func task1():
	print("task 1 started")
	await get_tree().create_timer(1.0).timeout
	print("task 1 finished")

func task2():
	print("task 2 started")
	await get_tree().create_timer(1.0).timeout
	print("task 2 finished")

# Добавляет функцию в очередь (с аргументами, если нужно)
func add_task(task_callable: Callable, args: Array = []) -> void:
	task_list.push_back({"callable": task_callable, "args": args})
	_process_next_task()

# Запускает следующую задачу, если очередь не пуста
func _process_next_task() -> void:
	if is_running or task_list.is_empty():
		return
	
	is_running = true
	var current_task = task_list.pop_front()
	
	# Вызываем задачу с её аргументами
	var task_result = await current_task["callable"].callv(current_task["args"])
	
	# Если задача возвращает сигнал (например, анимация или HTTP-запрос), 
	# ждём его завершения через await
	if task_result is Signal:
		await task_result
	# Иначе сразу переходим к следующей
	_on_task_completed()

# Обработчик завершения задачи
func _on_task_completed() -> void:
	is_running = false
	_process_next_task()  # Рекурсивный вызов для следующей задачи
