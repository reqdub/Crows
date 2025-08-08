extends Node2D

class_name Brawl

var origin_positions = {}

var player_node
var fighter_1
var fighter_2
var fighter_1_origin_position : Vector2
var brawl_winner : Node2D

var battle_tween : Tween

var time_in_brawl := 1.5
var brawl_cooldown := 2.0

var is_brawl_running := false
var is_brawl_cancelled := false

signal brawl_ended

func set_brawl_start_point():
	global_position = fighter_2.global_position

func start_brawl(fighter, target) -> void:
	if is_brawl_running:
		return
	# Инициализация боя
	is_brawl_running = true
	is_brawl_cancelled = false
	fighter_1 = fighter
	fighter_2 = target
	set_brawl_start_point()
	log_brawl_start()
	
	fighter.combat_component.start_combat(fighter_2)
	target.combat_component.start_combat(fighter_1)
	cache_origin_position(fighter)
	
	play_brawl_effects()
	await animate_fighter_approach()
	await wait_during_brawl()
	await animate_fighter_return()
	finalize_brawl_result(brawl_winner)

func stop_brawl() -> void:
	if not is_brawl_running:
		return
	cancel_tween()
	Logger.log(fighter_1.npc_name, " нокаутирован, бой завершен")
	is_brawl_running = false
	is_brawl_cancelled = true
	stop_brawl_effects()
	var stop_battle_tween = create_tween().set_parallel(true)
	stop_battle_tween.tween_property(fighter_1, "global_position", fighter_1_origin_position, 0.3)
	stop_battle_tween.tween_property(fighter_1, "rotation", 0, 0.3)
	if brawl_winner == fighter_1:
		fighter_1.combat_component.end_combat(true, fighter_1)
		fighter_2.combat_component.end_combat(false, fighter_1)
		is_brawl_running = false
	else:
		fighter_1.combat_component.end_combat(false, fighter_2)
		fighter_2.combat_component.end_combat(true, fighter_2)
		is_brawl_running = false

func log_brawl_start():
	Logger.log(fighter_1.npc_name, " начал бой")

func cache_origin_position(fighter):
	origin_positions[fighter] = fighter.global_position
	fighter_1_origin_position = fighter.global_position

func play_brawl_effects():
	$Smoke.emitting = true
	$Stars.emitting = true
	$Ding.play()
	$Fight.play()

func stop_brawl_effects():
	$Smoke.emitting = false
	$Stars.emitting = false
	$Ding.stop()
	$Fight.stop()

func animate_fighter_approach() -> void:
	if not is_brawl_running or is_brawl_cancelled:
		return
	var angle := get_fighter_approach_angle()
	battle_tween = create_tween().set_parallel(true)
	battle_tween.tween_property(fighter_1, "global_position", fighter_2.global_position, 0.3)
	battle_tween.tween_property(fighter_1, "rotation", angle, 0.3)
	await wait_for_tween(battle_tween)

func wait_during_brawl() -> void:
	if not is_brawl_running or is_brawl_cancelled:
		return
	$PunchTimer.start()
	await brawl_ended

func animate_fighter_return() -> void:
	await get_tree().create_timer(randf_range(0.5, 1.0)).timeout
	if not is_brawl_running or is_brawl_cancelled:
		return
	var origin_position = origin_positions.get(fighter_1, fighter_1_origin_position)
	battle_tween = create_tween().set_parallel(true)
	battle_tween.tween_property(fighter_1, "global_position", origin_position, 0.3)
	battle_tween.tween_property(fighter_1, "rotation", 0, 0.3)
	await wait_for_tween(battle_tween)

func finalize_brawl_result(winner):
	if not is_brawl_running or is_brawl_cancelled:
		return
	if winner == fighter_1:
		fighter_1.combat_component.end_combat(true, fighter_1)
		fighter_2.combat_component.end_combat(false, fighter_1)
	else:
		fighter_1.combat_component.end_combat(false, fighter_2)
		fighter_2.combat_component.end_combat(true, fighter_2)
	is_brawl_running = false
	is_brawl_cancelled = false

func wait_for_tween(tween: Tween) -> void:
	while tween.is_running():
		if is_brawl_cancelled:
			tween.kill()
			return
		await get_tree().process_frame

func cancel_tween():
	is_brawl_cancelled = true
	$PunchTimer.stop()
	if battle_tween:
		battle_tween.kill()
	is_brawl_running = false

func get_fighter_approach_angle() -> float:
	return deg_to_rad(-90) if fighter_1.global_position.x > fighter_2.global_position.x else deg_to_rad(90)

func _on_punch_timer_timeout() -> void:
	if not is_brawl_running: return
	if is_brawl_cancelled: return
	if fighter_1.health_component.is_knockdown:
		brawl_winner = fighter_2
		$PunchTimer.stop()
		stop_brawl()
		brawl_ended.emit()
		return
	elif fighter_2.health_component.is_knockdown:
		brawl_winner = fighter_1
		$PunchTimer.stop()
		stop_brawl()
		brawl_ended.emit()
		return
	fighter_1.combat_component.deal_damage(fighter_2)
	fighter_2.combat_component.deal_damage(fighter_1)
