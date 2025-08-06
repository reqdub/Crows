extends Node2D

var npc_with_bag_and_stick = preload("res://Scenes/NPC/TravellerWithBagAndStick.tscn")
var guard = preload("res://Scenes/NPC/Guard.tscn")

@onready var left_despawn_point =  $Despawn_Area/CollisionShapeLeft
@onready var right_despawn_point = $Despawn_Area/CollisionShapeRight

@export var spawn_speed = 1.5
@export var spawn_chance = 50
@export var max_entities = 2
@export var max_guards = 1

var area_danger_level : int = 0
var area_danger_points_per_level = 10
var spawn_enabled : bool = true
var current_number_of_npc : int = 0
var number_of_guards : int = 0

func _ready() -> void:
	start_spawn()

func _on_timer_timeout() -> void:
	if not spawn_enabled: return
	if spawn_chance <= randi_range(0, 100): return
	if current_number_of_npc >= max_entities: return
	else: spawn(random_spawn_direction())
	current_number_of_npc += 1
	start_spawn()

func stop_spawn():
	$Timer.stop()

func start_spawn():
	$Timer.start(spawn_speed)

func random_spawn_direction() -> bool:
	var left_side : bool = true
	var side_chance = randi_range(0, 100)
	if side_chance <= 50: 
		left_side = true
	else: 
		left_side = false
	return left_side

func spawn(from_left_side : bool):
	var new_npc
	var new_npc_type
	var danger_ratio = float(area_danger_level) / 100.0
	# NPC уменьшается от 95% до 5%
	var npc_chance = 0.05 - (danger_ratio * danger_ratio) * 0.90
	print("Шанс спавна для NPC = ", str(npc_chance))
	#Квадратичная функия уменьшения спавна для NPC с повышение уровня опасности зоны
	Logger.log("Шанс спавна NPC = ", str(npc_chance))
	# Бандит растет от 0% до 45%
	#var bandit_chance = danger_ratio * 0.45
	# Стражник растет от 5% до 50%
	var guard_chance = 1.0 - npc_chance
	print("Шанс спавна для Стражи = ", str(guard_chance))
	Logger.log("Шанс спавна стражника = ", str(guard_chance))
	var roll = randf()
	if roll < npc_chance:
		new_npc = npc_with_bag_and_stick.instantiate()
		new_npc_type = 0
#	elif roll < npc_chance + bandit_chance:
#		spawn_bandit()
	else:
		new_npc = guard.instantiate()
		new_npc_type = 1
	var spawn_point
	var despawn_point
	if from_left_side:
		spawn_point = $LeftPosition
		despawn_point = $Despawn_Area/CollisionShapeRight
	else:
		spawn_point = $RightPosition
		despawn_point = $Despawn_Area/CollisionShapeLeft
	new_npc.setup_npc(new_npc_type ,spawn_point, despawn_point)
	%Walk_Area.call_deferred("add_child", new_npc)
	await get_tree().create_timer(0.5).timeout
	new_npc.karma_component.connect("karma_changed", %UI._on_karma_changed)
	#Перезаписываю позицию спавна на CollisionShape, в котором NPC задеспавнится
	if from_left_side:
		new_npc.spawn_position = left_despawn_point
	else:
		new_npc.spawn_position = right_despawn_point

func _on_despawn_area_body_entered(body: Node2D) -> void:
	if (body.is_in_group("Character")):
		body.queue_free()
		current_number_of_npc -= 1
		
func _on_danger_increases():
	area_danger_level += area_danger_points_per_level
	if area_danger_level >= 100:
		area_danger_level = 100
	%UI.increase_area_dangerous(area_danger_level)
