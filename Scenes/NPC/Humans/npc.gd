extends Node2D

class_name npc213

@export var dialogues : Resource
@export var walk_speed = randi_range(500, 1000)

@onready var brawl_node : brawl = get_node("/root/World/Brawl")
@onready var walker_node : walker
@onready var loot = preload("res://item.tscn")
@onready var signal_bus = get_node("/root/World/Signal_Bus")
@onready var statemachine_node : StateMachine = %StateMachine
@onready var hit_sound = load("res://Sounds/SFX/hit.wav")
@onready var danger_point = get_node("/root/World/Background/DangerPoint")

@onready var damage_indicator = preload("res://Scenes/damage_indicator.tscn")
@onready var on_screen_text = get_node("/root/World/OnScreenText")

var state = statemachine_node.state

#Задержка перед началом боя, чтобы NPC успел произнести фразу, либо совершить лишь ему известные действия
var delay_before_start_fight : float = 0.5
var npc_reaction_time : float = 0.3
var base_speed = randi_range(4, 8)#4,6 default
var move_speed

var is_hands_empty : bool = true
var ammunition : Array = []
var loot_in_pockets : Dictionary = {
	"Money" : randi_range(0, 10)
}
var is_enemy_in_sight : bool = false
var movement_target
var potential_enemy
var is_enemy_been_seeing : bool = false
var point_before_chase : Vector2

var loot_chance = 10
var drop_position

var fear_chance : int = randi_range(0, 30)
var caution_chance : int = randi_range(50, 100)
var number_of_warnings : int = randi_range(2, 3)
var number_of_cautions : int = randi_range(1, 3)

var find_enemy_multiplier : float = 1.0
var panic_karma_factor : int = 2
var damage_taking_karma_factor : int = 5
var knockdown_karma_factor : int = 10
var base_karma_damage : int = 1

var is_head_damaged : bool = false
var is_body_damaged : bool = false

var is_in_fight : bool = false
var is_angry : bool = false
var is_dead : bool = false
var is_panic : bool = false
var is_damaged : bool = false
var is_knockdown : bool = false

var max_health : int = 0
var health : int = 0

signal health_changed(_amount)
signal karma_changed(_amount)
signal display_speech(_text)

enum vitality {
	WEAK,
	NORMAL,
	TOUGH
}

func _ready() -> void:
	randomize()
	randomize_vitality()
	randomize_visual()
	move_speed = base_speed
	drop_position = $Drop_Position
	%HealthBar.max_value = max_health
	%HealthBar.value = health

func randomize_vitality():
	var random_vitality = randi_range(0, vitality.size() - 1)
	match random_vitality:
		vitality.WEAK:
			max_health = 10
		vitality.NORMAL: 
			max_health = 15
		vitality.TOUGH: 
			max_health = 25
	max_health = 10
	health = max_health

func randomize_visual():
	var random_head = randi_range(1, 3)
	var head_texture_path = "res://Sprites/NPC/Heads/Male/Head" + str(random_head) + ".png"
	$Visual/Head.texture = load(head_texture_path)
	$Visual/Head.frame = 0

func chech_is_feared(fear_modifier = 1) -> bool:
	if dice_roll() <= (fear_chance * fear_modifier):
		Logger.log(walker_node.walker_name, " Испуган")
		potential_enemy = null
		movement_target = null
		return true
	Logger.log(walker_node.walker_name, " Прошёл проверку на испуг")
	return false

func reaction_on(event : String, source = null):
	if check_terminal_statuses(is_dead, is_knockdown, is_panic, is_in_fight): return
	match event:
		#region Реакция на оружие
		"Weapon" :
			if chech_is_feared():
				if check_terminal_statuses(is_dead, is_knockdown, is_panic, is_in_fight): return
				statemachine_node.change_state(statemachine_node.state.PANIC)
				say("panic")
			elif is_damaged:
				say("swearing")
				return
			elif is_enemy_in_sight and not is_damaged:
				number_of_warnings -= 1
				say("warning")
				Logger.log(walker_node.walker_name, "Игрок рядом бросил камень, я не ранен, но предупреждаю его")
				change_state(state.WARNING)
				if number_of_warnings <= 0:
					await get_tree().create_timer(delay_before_start_fight).timeout
					if check_terminal_statuses(is_dead, is_knockdown, is_panic): return
					before_fight(potential_enemy)
					Logger.log(walker_node.walker_name, "Игрок рядом бросил камень, хватит предупреждать, бой!")
					change_state(state.BATTLE)
			elif is_enemy_in_sight and is_damaged:
				Logger.log(walker_node.walker_name, "Игрок рядом бросил камень, я был ранен, начинаю бой")
				await get_tree().create_timer(npc_reaction_time).timeout
				if check_terminal_statuses(is_dead, is_knockdown, is_panic): return
				before_fight(potential_enemy)
				change_state(state.BATTLE)
			else: #Игрок находится далеко
				if randi_range(0, 100) <= caution_chance:
					await get_tree().create_timer(npc_reaction_time).timeout
					if check_terminal_statuses(is_dead, is_knockdown, is_panic): return
					movement_target = danger_point
					point_before_chase = walker_node.global_position
					Logger.log(walker_node.walker_name, "Игрок рядом бросил камень, но проверять я не буду, лучше быстрее уйду")
					walk_speed /= 1.2
					say("what")
					number_of_cautions -= 1
					change_state(state.CAUTION)
				else:
					is_angry = true
					Logger.log(walker_node.walker_name, "Игрок рядом бросил камень, я был далеко, но всё равно зол и иду проверять")
					say("swearing")
					number_of_cautions -= 1
					movement_target = danger_point
					change_state(state.CHASE)
		#endregion
		#region Реакция на раненого NPC
		"Damaged_Character" :
			if chech_is_feared():
				if check_terminal_statuses(is_dead, is_knockdown, is_panic, is_in_fight): return
				walker_node.stop_moving()
				say("call_for_help")
				change_state(state.PANIC)
			else:
				if source.is_panic:
					say("joke")
		#endregion
		#region Реакция на Игрока
		"Player" :
			source.look_at_target(self)
			potential_enemy = source
			Logger.log(walker_node.walker_name, "Реагирую на игрока")
			if source.check_stealth(find_enemy_multiplier):
				Logger.log(walker_node.walker_name, "Игрок спрятался")
				potential_enemy = null
				walker_node.stop_moving()
				if is_enemy_been_seeing:
					say("it_seemed")
				else:
					say("where_are_you")
				await get_tree().create_timer(1.0).timeout
				if check_terminal_statuses(is_dead, is_knockdown, is_panic, is_in_fight): return
				if check_is_current_state(state.WALK) or check_is_current_state(state.CHASE):
					movement_target = null
					walker_node.move_to_point()
			elif source.is_in_battle:
				is_enemy_been_seeing = true
				find_enemy_multiplier = 2.0
				Logger.log(source.get_name(), "Игрок в бою")
				say("taunt")
				if check_is_current_state(state.WALK) or check_is_current_state(state.CHASE):
					movement_target = null
					walker_node.move_to_point()
			elif source.is_knockdown:
				is_enemy_been_seeing = true
				find_enemy_multiplier = 2.0
				Logger.log(walker_node.walker_name, "Игрок без сознания")
				say("taunt")
				if check_is_current_state(state.WALK) or check_is_current_state(state.CHASE):
					movement_target = null
					walker_node.move_to_point()
			elif source.is_praying and not is_damaged:
					is_enemy_been_seeing = true
					find_enemy_multiplier = 2.0
					Logger.log(walker_node.walker_name, "Игрок молится")
					walker_node.stop_moving()
					if dice_roll() < 50:
						say("pray")
					await get_tree().create_timer(1.0).timeout
					if check_is_current_state(state.WALK) or check_is_current_state(state.CHASE):
						walker_node.move_to_point()
			else: #Игрок ничего не делает
				if is_damaged:
					walker_node.stop_moving()
					is_enemy_been_seeing = true
					find_enemy_multiplier = 3.0
					Logger.log(walker_node.walker_name, "Я ранен игроком, угрожаю и вступаю в бой")
					await get_tree().create_timer(delay_before_start_fight).timeout
					if check_terminal_statuses(is_dead, is_knockdown, is_panic): return
					before_fight(source)
					say("threat")
					change_state(state.BATTLE)
				else:
					is_enemy_been_seeing = true
					find_enemy_multiplier = 2.5
					if is_angry:
						Logger.log(walker_node.walker_name, "Я зол, предупреждаю игрока")
						number_of_warnings -= 1
						if number_of_warnings <= 0:
							Logger.log(walker_node.walker_name, "Последнее предупреждение исчерпано, вступаю в бой")
							await get_tree().create_timer(delay_before_start_fight).timeout
							if check_terminal_statuses(is_dead, is_knockdown, is_panic): return
							before_fight(source)
							change_state(state.BATTLE)
						else:
							Logger.log(walker_node.walker_name, "Предупреждаю игрока!")
							say("warning")
							change_state(state.WARNING)
					else:
						if dice_roll() <= caution_chance:
							Logger.log(walker_node.walker_name, "Обнаружил игрока")
							change_state(state.CAUTION)
							say("find_you")
		#endregion
		 #region Реакция на пустое место
		"Empty_Space":
			return
			if is_enemy_in_sight: return
			if randi_range(0, 100) <= 50:
				if not is_enemy_been_seeing:
					Logger.log(walker_node.walker_name, "Игрок не был замечен")
					potential_enemy = null
					walker_node.stop_moving()
					say("it_seemed")
					await get_tree().create_timer(1.0).timeout
					if check_terminal_statuses(is_dead, is_knockdown, is_panic, is_in_fight): return
					if check_is_current_state(state.WALK) or check_is_current_state(state.CHASE):
						movement_target = null
						walker_node.move_to_point()
				else:
					if not is_enemy_in_sight:
						find_enemy_multiplier = 4.0
						Logger.log(walker_node.walker_name, "Игрок ушёл")
						potential_enemy = null
						walker_node.stop_moving()
						say("where_are_you")
						await get_tree().create_timer(1.0).timeout
						if check_terminal_statuses(is_dead, is_knockdown, is_panic, is_in_fight): return
						if check_is_current_state(state.WALK) or check_is_current_state(state.CHASE):
							movement_target = null
							walker_node.move_to_point()
			else:
				await get_tree().create_timer(1.0).timeout
				if check_terminal_statuses(is_dead, is_knockdown, is_panic, is_in_fight): return
				if check_is_current_state(state.WALK) or check_is_current_state(state.CHASE):
					movement_target = null
					walker_node.move_to_point()
		#endregion empty_space_reaction

func before_fight(with):
	Logger.log(walker_node.walker_name, " Подготовка перед боем")
	if is_knockdown: return
	%HealthBar.visible = false
	is_in_fight = true
	with.is_in_battle = true

func start_fight():
	set_vision(false)
	$"../DebugLabel".visible = false
	%SpeechBubble.visible = false
	%HealthBar.visible = false
func end_fight(win : bool):
	if is_knockdown: return
	Logger.log(walker_node.walker_name, str(" Бой завершился, я победил? ", win))
	await get_tree().create_timer(0.1).timeout
	if is_knockdown: return
	if win:
		is_angry = false
		potential_enemy = null
		Logger.log(walker_node.walker_name, "Бой завершился, я победил, продолжаю путь")
		emit_signal("display_speech", SpeechReplicas.random_dialogue("taunt"))
		statemachine_node.change_state(statemachine_node.state.WALK)
	else:
		if is_knockdown: return
		Logger.log(walker_node.walker_name, "Бой завершился, я проиграл, падаю без сознания")
		statemachine_node.change_state(statemachine_node.state.KNOCKDOWN)
	set_vision(true)
	await get_tree().create_timer(1.0).timeout
	$"../DebugLabel".visible = true
	is_in_fight = false

func drop_loot():
	if loot_in_pockets.is_empty(): return
	if randi_range(0, 100) <= loot_chance:
		var loot_dict_keys : Array = loot_in_pockets.keys()
		var random_item_in_pocket = loot_dict_keys[randi_range(0, loot_dict_keys.size() - 1)]
		var number_of_items = loot_in_pockets[random_item_in_pocket]
		var random_number_of_items = randi_range(0, number_of_items)
		for i in random_number_of_items:
			var loot_instance = loot.instantiate()
			loot_instance.set_item(random_item_in_pocket)
			loot_instance.global_position = drop_position.global_position
			get_node("/root/World/Background/Walk_Area").call_deferred("add_child", loot_instance)
		if number_of_items == 0:
			loot_in_pockets.erase(random_item_in_pocket)
			return

func add_ammunition(item):
	is_hands_empty = false
	ammunition.append(item)
func drop_ammunition(all = false, _item = null):
	if all:
		for item in ammunition:
			ammunition.erase(item)
			if item != null:
				item.drop()
	else:
		ammunition.erase(_item)
		_item.drop()
	if ammunition.is_empty(): is_hands_empty = true

func take_damage(_dmg_source, _amount, _is_headhshot = false):
	if health <= 0: return
	if _amount > 1:
		add_damage_indicator(_amount)
		is_damaged = true
		health -= _amount
		if health < max_health:
			%HealthBar.visible = true
			$"../HealthBar/Label".set_text(str(health, " / ", max_health))
		health_changed.emit(health)
		if _is_headhshot:
			Logger.log(walker_node.walker_name, str("Получено урона в голову ", _amount))
		else: Logger.log(walker_node.walker_name, str("Получено урона в туловище ", _amount))
		var health_tween = get_tree().create_tween()
		health_tween.tween_property(%HealthBar, "value", health, 0.3)
		if health <= 3:
			brawl_node.stop_brawl()
			%HealthBar.visible = false
			emit_signal("karma_changed", -base_karma_damage * panic_karma_factor)
			say("knockdown")
			Logger.log(walker_node.walker_name, "Получено слишком много урона, падаю без сознания")
			change_state(state.KNOCKDOWN)
			$Visual/Head.frame = 3
			$Visual/Body.frame = 1
			return
		if check_terminal_statuses(false, false, is_panic, is_in_fight): return
		Logger.log(walker_node.walker_name, " не в панике и не в бою")
		emit_signal("karma_changed", -base_karma_damage * panic_karma_factor)
		say("damaged")
		if _is_headhshot:
			$Visual/Head.frame = 3
			is_head_damaged = true
		else:
			$Visual/Body.frame = 1
			is_body_damaged = true
		if is_enemy_in_sight:
			if is_in_fight: return
			is_in_fight = true
			say("threat")
			await get_tree().create_timer(delay_before_start_fight).timeout
			if check_terminal_statuses(is_dead, is_knockdown, is_panic, is_in_fight): return
			Logger.log(walker_node.walker_name, "Игрок рядом и именно он нанёс удар, начинаю бой")
			if not is_knockdown:
				change_state(state.BATTLE)
		else:	#Получил удар издалека
			if check_terminal_statuses(is_dead, is_knockdown, is_panic, is_in_fight): return
			movement_target = danger_point
			point_before_chase = walker_node.global_position
			Logger.log(walker_node.walker_name, "Игрок далеко, иду к его позиции")
			say("swearing")
			if check_is_current_state(state.CHASE): return
			change_state(state.CHASE)
	else:
		add_damage_indicator(0)

func dice_roll() -> int:
	return randi_range(0, 100)

func check_is_current_state(state):
	if statemachine_node.current_state == state: return true
	return false

func change_state(state):
	statemachine_node.change_state(state)

func say(replica_type : String):
	emit_signal("display_speech", SpeechReplicas.random_dialogue(replica_type))

func check_terminal_statuses(_is_dead = null, _is_in_knockdown = null, _is_in_panic = null, _is_in_fight = null) -> bool:
	if _is_dead != null and _is_dead: return true
	if _is_in_knockdown != null and _is_in_knockdown: return true
	if _is_in_panic != null and _is_in_panic: return true
	if _is_in_fight != null and _is_in_fight: return true
	return false

func knockdown_animation():
	Logger.log(walker_node.walker_name, " Без сознания")
	%SpeechBubble.visible = false
	%HealthBar.visible = false
	drop_ammunition(true)
	set_vision(false)
	$Visual/Body/BodyArea.queue_free()
	$Visual/Head/HeadCollision.queue_free()
	$AnimationPlayer.play("Knockdown")
	await $AnimationPlayer.animation_finished
	is_knockdown = false
	set_vision(true)
	Logger.log(walker_node.walker_name, " Пришел в сознание")
	emit_signal("display_speech", SpeechReplicas.random_dialogue("call_for_help"))
	statemachine_node.change_state(statemachine_node.state.PANIC)

func walk_animation():
	$AnimationPlayer.play("Walk")

func chase_animation():
	$AnimationPlayer.play("Walk")

func idle_animation():
	$AnimationPlayer.stop()

func panic_animation():
	drop_ammunition(true)
	$AnimationPlayer.play("Panic")

func caution_animation():
	$AnimationPlayer.stop()

func blink():
	var blink_chance = 50
	if blink_chance <= randi_range(0, 100): return
	var timer = get_tree().create_timer(0.4)
	if is_head_damaged:
		$Visual/Head.frame = 2
		await timer.timeout
		$Visual/Head.frame = 3
	else:
		$Visual/Head.frame = 1
		await timer.timeout
		$Visual/Head.frame = 0

func stop_animation():
	$AnimationPlayer.stop()

func set_vision(can_see : bool = true):
	$"../ViewArea".set_deferred("monitorable", can_see)
	$"../ViewArea".set_deferred("monitoring", can_see)

func start_brawl():
	if is_knockdown: return
	if not brawl_node.is_brawl_running:
		await brawl_node.start_brawl(walker_node)
	else:
		change_state(state.WALK)

func _on_view_area_body_entered(body: Node2D) -> void:
	if is_knockdown: return
	if is_panic: return
	if is_in_fight: return
	if body == walker_node : return
	if body.is_in_group("Throwable"):
		Logger.log(walker_node.walker_name, " Реагирую на камень")
		reaction_on("Weapon", body)
	elif body.is_in_group("Player"):
		Logger.log(walker_node.walker_name, " Заметил игрока!")
		potential_enemy = body
		is_enemy_in_sight = true
		reaction_on("Player", body)
	elif body.is_in_group("Character"):
		if body.character.is_damaged: 
			reaction_on("Damaged_Character", body.character)
			Logger.log(walker_node.walker_name, "Реагирую на раненого")
	elif body.is_in_group("Empty_Space"):
		reaction_on("Empty_Space", body)

func _on_view_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		is_enemy_in_sight = false

func _on_head_collision_body_entered(body: Node2D) -> void:
	if body.is_in_group("Throwable"):
		body.destroy()
		$AudioStreamPlayer2D.stream = hit_sound
		$AudioStreamPlayer2D.pitch_scale = randf_range(0.9, 1.1)
		$AudioStreamPlayer2D.play()
		take_damage(body, body.deal_damage(), true)

func _on_body_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Throwable"):
		body.destroy()
		$AudioStreamPlayer2D.stream = hit_sound
		$AudioStreamPlayer2D.pitch_scale = randf_range(0.9, 1.1)
		$AudioStreamPlayer2D.play()
		take_damage(body, body.deal_damage())

func add_damage_indicator(_amount):
	var damage_indicator_instance = damage_indicator.instantiate()
	damage_indicator_instance.damage_amount(_amount)
	damage_indicator_instance.global_position = %OnScreenIndicators.global_position
	on_screen_text.call_deferred("add_child", damage_indicator_instance)
