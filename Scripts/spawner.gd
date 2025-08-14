extends Node2D

@onready var peasant = preload("res://Scenes/NPC/TravellerWithBagAndStick.tscn")
@onready var guard = preload("res://Scenes/NPC/Guard.tscn")
@onready var bandit = preload("res://Scenes/NPC/Bandit.tscn")
@onready var merchant = preload("res://Scenes/NPC/Trader.tscn")

@onready var left_despawn_point =  $Despawn_Area/CollisionShapeLeft
@onready var right_despawn_point = $Despawn_Area/CollisionShapeRight

@export var spawn_speed = 2.5
@export var spawn_chance = 100
@export var max_number_of_npc = 2
@export var max_number_of_bandits = 1

var weigth_spawn_dict = {
	"peasant" : 5.0,
	"guard" : 2.5,
	"bandit" : 1.0,
	"merchant" : 1.5
}

var npc_count = {
	"Bandit" : 0,
	"Peasant" : 0,
	"Guard" : 0,
	"Merchant" : 0
}

var npc_count_past_day = {
	"Bandit" : 0,
	"Peasant" : 0,
	"Guard" : 0,
	"Merchant" : 0
}

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

enum npc_type {
	PEASANT,
	BANDIT,
	GUARD,
	MERCHANT
}

func _ready() -> void:
	setup_npc_spawn_weigths()
	start_spawn()
	%DayNightCycle.connect("new_day_started", _on_new_day_started)

func _on_timer_timeout() -> void:
	if not spawn_enabled:
		start_spawn()
		return
	if current_number_of_npc == max_number_of_npc:
		spawn_enabled = false
		start_spawn()
		return
	if spawn_chance <= randi_range(0, 100): return
	else: spawn(select_spawn_direction())
	start_spawn()

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
	var new_npc_parameters = get_random_weigthed_npc()
	if new_npc_parameters.is_empty(): return
	var new_npс = new_npc_parameters[0] #npc instance
	var new_npc_type = new_npc_parameters[1]
	var spawn_point
	var despawn_point
	if spawn_direction == spawn_directions.LEFT:
		spawn_point = $LeftPosition
		despawn_point = $Despawn_Area/CollisionShapeRight
	elif spawn_direction == spawn_directions.RIGHT:
		spawn_point = $RightPosition
		despawn_point = $Despawn_Area/CollisionShapeLeft
	new_npс.setup_npc(spawn_point, despawn_point)
	if new_npc_type == npc_type.GUARD:
		new_npс.add_day_statistics(npc_count_past_day)
	%Walk_Area.call_deferred("add_child", new_npс)
	await get_tree().create_timer(0.5).timeout
	new_npс.karma_component.connect("karma_changed", %UI._on_karma_changed)
	#Перезаписываю позицию спавна на CollisionShape, в котором NPC задеспавнится
	if spawn_direction == spawn_directions.LEFT:
		new_npс.spawn_position = left_despawn_point
	elif spawn_direction == spawn_directions.RIGHT:
		new_npс.spawn_position = right_despawn_point
	current_number_of_npc += 1

func setup_npc_spawn_weigths():
	var danger_factor = sqrt(float(area_danger_level)) / 100.0
	weigth_spawn_dict.peasant = lerp(weigth_spawn_dict.peasant, weigth_spawn_dict.peasant * 0.1, danger_factor)
	weigth_spawn_dict.guard = lerp(weigth_spawn_dict.guard, weigth_spawn_dict.guard * 2.0, danger_factor)
	weigth_spawn_dict.bandit = lerp(weigth_spawn_dict.bandit, weigth_spawn_dict.bandit * 3.0, danger_factor)

func get_random_weigthed_npc() -> Array:
	var new_npс : Node2D
	var type
	var total_weigth : float = 0.0
	for npc_weigth in weigth_spawn_dict.values():
		total_weigth += npc_weigth
	if total_weigth <= 0:
		return ["Ошибка в значениях весов, сумма не должна быть равно либо ниже 0"]
	var random_value = randf() * total_weigth
	for npc_to_spawn in weigth_spawn_dict.keys():
		random_value -= weigth_spawn_dict[npc_to_spawn]
		if random_value <= 0:
			match npc_to_spawn:
				"peasant" : 
					npc_count["Peasant"] += 1
					npc_count_past_day["Peasant"] += 1
					new_npс = peasant.instantiate()
					type = npc_type.PEASANT
					return [new_npс, type]
				"bandit" : 
					npc_count["Bandit"] += 1
					npc_count_past_day["Bandit"] += 1
					new_npс = bandit.instantiate()
					type = npc_type.BANDIT
					return [new_npс, type]
				"guard" : 
					npc_count["Guard"] += 1
					npc_count_past_day["Guard"] += 1
					new_npс = guard.instantiate()
					type = npc_type.GUARD
					return [new_npс, type]
				"merchant" :
					npc_count["Merchant"] += 1
					npc_count_past_day["Merchant"] += 1
					new_npс = merchant.instantiate()
					type = npc_type.MERCHANT
					return [new_npс, type]
				_: return ["None"]
	return ["None"]

func _on_despawn_area_body_entered(body: Node2D) -> void:
	if (body.is_in_group("Character")):
		body.queue_free()
		current_number_of_npc -= 1
		if body.is_in_group("Peasant"):
			npc_count["Peasant"] -= 1
		elif body.is_in_group("Bandit"):
			npc_count["Bandit"] -= 1
		elif body.is_in_group("Guard"):
			npc_count["Guard"] -= 1
	if current_number_of_npc == 0:
		spawn_enabled = true
	
func _on_danger_increases():
	setup_npc_spawn_weigths()
	area_danger_level += area_danger_points_per_level
	if area_danger_level >= 100:
		area_danger_level = 100
	%UI.increase_area_dangerous(area_danger_level)

func _on_new_day_started():
	for number_of_npc in npc_count_past_day.keys():
		npc_count_past_day[number_of_npc] = 0

func _on_daytime_dawn():
	weigth_spawn_dict.peasant *= 2.0
	weigth_spawn_dict.merchant *= 2.5
	weigth_spawn_dict.bandit *= 0.5
	weigth_spawn_dict.guard *= 0.5
func _on_daytime_day():
	weigth_spawn_dict.peasant *= 2.0
	weigth_spawn_dict.merchant *= 2.5
	weigth_spawn_dict.bandit *= 0.5
	weigth_spawn_dict.guard *= 0.5
func _on_daytime_dusk():
	weigth_spawn_dict.peasant *= 0.2
	weigth_spawn_dict.bandit *= 2.0
	weigth_spawn_dict.guard *= 0.5
	weigth_spawn_dict.merchant *= 0.0
func _on_daytime_night():
	weigth_spawn_dict.peasant *= 0.2
	weigth_spawn_dict.bandit *= 2.0
	weigth_spawn_dict.guard *= 0.5
	weigth_spawn_dict.merchant *= 0.0
