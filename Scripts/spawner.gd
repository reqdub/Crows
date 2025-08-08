extends Node2D

var npc_with_bag_and_stick = preload("res://Scenes/NPC/TravellerWithBagAndStick.tscn")
var guard = preload("res://Scenes/NPC/Guard.tscn")
var bandit = preload("res://Scenes/NPC/Bandit.tscn")

@onready var left_despawn_point =  $Despawn_Area/CollisionShapeLeft
@onready var right_despawn_point = $Despawn_Area/CollisionShapeRight

@export var spawn_speed = 2.5
@export var spawn_chance = 100
@export var max_number_of_npc = 2

var area_danger_level : int = 0
var area_danger_points_per_level = 10
var spawn_enabled : bool = true
var current_number_of_npc : int = 0
var number_of_guards : int = 0
var left_side_blocked : bool = true

enum spawn_directions {
	LEFT,
	RIGHT
}
var last_spawn_direction : spawn_directions = spawn_directions.LEFT

func _ready() -> void:
	start_spawn()

func _on_timer_timeout() -> void:
	if not spawn_enabled:
		start_spawn()
		return
	if spawn_chance <= randi_range(0, 100): return
	else: spawn(select_spawn_direction())
	current_number_of_npc += 1
	start_spawn()
	if current_number_of_npc == max_number_of_npc:
		spawn_enabled = false

func stop_spawn():
	$Timer.stop()

func start_spawn():
	$Timer.start(spawn_speed)

func select_spawn_direction() -> spawn_directions:
	if last_spawn_direction == spawn_directions.LEFT:
		last_spawn_direction = spawn_directions.RIGHT
		return spawn_directions.RIGHT
	else:
		last_spawn_direction = spawn_directions.LEFT
		return spawn_directions.LEFT

func spawn(spawn_direction : spawn_directions):
	var new_npc
	var danger_ratio = float(area_danger_level) / 100.0
	# NPC уменьшается от 95% до 5%
	var npc_chance = 0.75 - (danger_ratio * danger_ratio) * 0.65
	print("Шанс спавна для NPC = ", str(npc_chance))
	#Квадратичная функия уменьшения спавна для NPC с повышение уровня опасности зоны
	# Бандит растет от 0% до 45%
	   # 3. Рассчитываем шанс для бандита с заданными ограничениями
	# Шанс должен быть в диапазоне от 5% до 15%
	var bandit_min_chance = 0.15
	var bandit_max_chance = 0.25
	var bandit_chance = bandit_min_chance + (bandit_max_chance - bandit_min_chance) * danger_ratio
	print("Шанс спавна для Бандита = ", str(bandit_chance))
	# Стражник растет от 5% до 50%
	var remaining_chance = 1.0 - npc_chance - bandit_chance
	var guard_chance = remaining_chance
	print("Шанс спавна для Стражи = ", str(guard_chance))
	var roll = randf()
	#if roll < npc_chance:
		#new_npc = npc_with_bag_and_stick.instantiate()
	#elif roll < bandit_chance:
		#new_npc = bandit.instantiate()
	#else:
		#new_npc = guard.instantiate()
	if roll < 0.5:
		new_npc = bandit.instantiate()
	else:
		new_npc = guard.instantiate()
	var spawn_point
	var despawn_point
	if spawn_direction == spawn_directions.LEFT:
		spawn_point = $LeftPosition
		despawn_point = $Despawn_Area/CollisionShapeRight
	elif spawn_direction == spawn_directions.RIGHT:
		spawn_point = $RightPosition
		despawn_point = $Despawn_Area/CollisionShapeLeft
	new_npc.setup_npc(spawn_point, despawn_point)
	%Walk_Area.call_deferred("add_child", new_npc)
	await get_tree().create_timer(0.5).timeout
	new_npc.karma_component.connect("karma_changed", %UI._on_karma_changed)
	#Перезаписываю позицию спавна на CollisionShape, в котором NPC задеспавнится
	if spawn_direction == spawn_directions.LEFT:
		new_npc.spawn_position = left_despawn_point
	elif spawn_direction == spawn_directions.RIGHT:
		new_npc.spawn_position = right_despawn_point

func _on_despawn_area_body_entered(body: Node2D) -> void:
	if (body.is_in_group("Character")):
		body.queue_free()
		current_number_of_npc -= 1
	if current_number_of_npc == 0:
		spawn_enabled = true
	
func _on_danger_increases():
	area_danger_level += area_danger_points_per_level
	if area_danger_level >= 100:
		area_danger_level = 100
	%UI.increase_area_dangerous(area_danger_level)
