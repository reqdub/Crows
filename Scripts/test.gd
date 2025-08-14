extends Node2D
class_name test

enum daytime {
	DUSK,
	DAY,
	DAWN,
	MIDNIGHT
}
var current_daytime : daytime = daytime.DAWN

func _ready() -> void:
	weigth_spawner()

func spawn():
	var area_danger_level = 70
	var danger_ratio : float = float(area_danger_level) / 100.0
	var npc_chance = 0.75 - (danger_ratio * danger_ratio) * 0.60
	var bandit_min_chance = 0.40
	var bandit_max_chance = 0.70
	var bandit_chance = bandit_min_chance + (bandit_max_chance - bandit_min_chance) * danger_ratio
	var remaining_chance = 1.0 - npc_chance - bandit_chance
	var guard_chance = remaining_chance
	var roll = randf()
	if roll < npc_chance:
		$Peasant.value += 1
		return
	if roll <= bandit_chance:
		$Bandit.value += 1
	else:
		$Guard.value += 1

func weigth_spawner():
	var weigth_spawn_dict = {
		"peasant" : 5.0,
		"guard" : 2.5,
		"bandit" : 1.0,
		"merchant" : 1.0
	}
	match current_daytime:
		daytime.DAWN, daytime.DAY:
			weigth_spawn_dict.peasant *= 2.0
			weigth_spawn_dict.merchant *= 2.5
			weigth_spawn_dict.bandit *= 0.5
			weigth_spawn_dict.guard *= 0.5
		daytime.DUSK, daytime.MIDNIGHT:
			weigth_spawn_dict.peasant *= 0.2
			weigth_spawn_dict.bandit *= 2.0
			weigth_spawn_dict.guard *= 0.5
			weigth_spawn_dict.merchant *= 0.0
	var area_danger_level : int = 0
	var danger_factor = sqrt(float(area_danger_level)) / 100.0
	
	weigth_spawn_dict.peasant = lerp(weigth_spawn_dict.peasant, weigth_spawn_dict.peasant * 0.1, danger_factor)
	weigth_spawn_dict.guard = lerp(weigth_spawn_dict.guard, weigth_spawn_dict.guard * 2.0, danger_factor)
	weigth_spawn_dict.bandit = lerp(weigth_spawn_dict.bandit, weigth_spawn_dict.bandit * 3.0, danger_factor)
	
	print(weigth_spawn_dict)
	
	for i in range(250):
		if $Peasant.value == 100: return
		if $Bandit.value == 100: return
		if $Guard.value == 100: return
		if $Merchant.value == 100: return
		var random_npc = get_random_weigthed_npc(weigth_spawn_dict)
		match random_npc:
			"peasant" : $Peasant.value += 1
			"bandit" : $Bandit.value += 1
			"guard" : $Guard.value += 1
			"merchant" : $Merchant.value += 1
		await get_tree().create_timer(0.02).timeout
	
func get_random_weigthed_npc(weigth : Dictionary) -> String:
	var total_weigth : float = 0.0
	for npc_weigth in weigth.values():
		total_weigth += npc_weigth
	if total_weigth <= 0:
		return "Ошибка в значениях весов, сумма не должна быть равно либо ниже 0"
	var random_value = randf() * total_weigth
	for npc_to_spawn in weigth.keys():
		random_value -= weigth[npc_to_spawn]
		if random_value <= 0:
			return npc_to_spawn
	return "None"

func _on_timer_timeout() -> void:
	spawn()
	$Timer.start()
