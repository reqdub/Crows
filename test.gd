extends Node2D
class_name test

var origin_position: Vector2
var is_movement_running := false
var current_tween: Tween  # Только один активный твин
var is_cancelled := false

func _ready() -> void:
	origin_position = $Sprite2D.global_position
	await start_movement()

func start_movement() -> void:
	if is_movement_running: return
	is_movement_running = true
	is_cancelled = false
	var sprite := $Sprite2D
	var target_pos = $World/Marker2D.global_position
	print("Start movement")
	# Первая анимация
	current_tween = create_tween().set_parallel(true)
	current_tween.tween_property(sprite, "global_position", target_pos, 0.3)
	current_tween.tween_property(sprite, "rotation", deg_to_rad(30), 1.3)
	await safe_await_tween(current_tween)
	if is_cancelled: return
	print("First phase done")
	# Вторая анимация
	current_tween = create_tween().set_parallel(true)
	current_tween.tween_property(sprite, "global_position", origin_position, 1.3)
	current_tween.tween_property(sprite, "rotation", 0.0, 1.3)
	await safe_await_tween(current_tween)
	print("Movement complete")
	is_movement_running = false

# Безопасное ожидание с проверкой отмены
func safe_await_tween(tween: Tween) -> void:
	while tween.is_running():
		if is_cancelled:
			tween.kill()
			return
		await get_tree().process_frame

func cancel_movement() -> void:
	is_cancelled = true
	if current_tween:
		current_tween.kill()
	# Мгновенный сброс позиции
	$Sprite2D.global_position = origin_position
	$Sprite2D.rotation = 0.0
	is_movement_running = false

func _on_tween_stop_pressed() -> void:
	cancel_movement()
