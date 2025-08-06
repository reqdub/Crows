extends Node2D

var movement_tween : Tween = null # Хорошая практика: инициализировать tween как null

func move_to_point(_point : Vector2):
	# Если уже есть активный Tween, убедимся, что он остановлен перед созданием нового
	if movement_tween and movement_tween.is_valid() and movement_tween.is_running():
		movement_tween.kill()
		print("Предыдущее движение остановлено.")

	var move_distance = global_position.distance_to(_point)
	var move_time = move_distance / 1000.0 * 10 # Используем 1000.0 для float деления
	
	movement_tween = get_tree().create_tween()
	movement_tween.tween_property(self, "global_position", _point, move_time)
	
	print("Начинаю движение к точке: ", _point)
	
	# Ждем завершения Tween
	await movement_tween.finished 
	
	# !!! Ключевой момент: Проверяем, был ли Tween убит или завершился нормально
	if is_instance_valid(movement_tween) and not movement_tween.is_running():
		# Если is_running() == false, но Tween все еще валиден, это означает, 
		# что он завершился естественным путем
		print("Движение завершено до точки.")
	else:
		# Если Tween невалиден (был обнулен) или все еще запущен (что маловероятно после finished),
		# это означает, что он был убит/отменен
		print("Движение остановлено/отменено.")
		
	movement_tween = null # Обнуляем ссылку после использования, чтобы избежать висячих ссылок

func stop():
	if movement_tween and movement_tween.is_valid() and movement_tween.is_running():
		movement_tween.kill()
		movement_tween = null # Важно: обнулить ссылку
		print("Tween убит из метода stop().")
	else:
		print("Нет активного движения для остановки.")
