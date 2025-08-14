extends Control

@onready var throwing_progress_bar = $ThrowStrength
@onready var aim = $Aim
@onready var good_karma_icon = load("res://Sprites/UI/GoodKarma.png")
@onready var bad_karma_icon = load("res://Sprites/UI/BadKarma.png")

@export var throwing_max_strength = 0.5

@export var throw_cooldown_time = 2.0
@export var stealth_cooldown_time = 2.0

var coin_tween : Tween

var player_inventory : Dictionary = {}

var throw_strength
var tween : Tween
var player_node : player

var is_stealth_on_cooldown : bool = false
var is_throw_on_cooldown : bool = false
var is_aiming : bool = false
var is_player_control_blocked : bool = false
var is_stealth_mode_on : bool = false

func _ready() -> void:
	Inventory.add_money(50)
	$MarginContainer/Karma/Label.set_text(str(Karma.get_current_karma()))
	$MarginContainer/Karma/KarmaTexture.texture = good_karma_icon
	$MarginContainer/Inventory/Money.set_text(str(Inventory.get_money_count()))

func connect_player(_player):
	player_node = _player
	player_node.connect("block_player_control", _player_control_blocked)
	player_node.connect("pray_finished", _on_player_pray_finished)
	player_node.connect("item_dropped", _on_player_item_dropped)
	player_node.connect("criminal", _on_player_criminal)

func _unhandled_input(event: InputEvent) -> void:
	if is_aiming and event.is_action_released("Mouse_Left"):
		throw()
	if is_player_control_blocked: return
	if is_stealth_mode_on: return
	if is_throw_on_cooldown: return
	if event.is_action_pressed("Mouse_Left"):
		%WeaponScrollBar.visible = false
		is_aiming = true
		aim.visible = true
		$ThrowStrength.value = 0
		$ThrowStrength.visible = true
		$Aim/AimSound.play()
		tween = get_tree().create_tween()
		tween.tween_property($ThrowStrength, "value", 100, throwing_max_strength)

func throw():
	if is_player_control_blocked : return
	is_aiming = false
	aim.visible = false
	throw_strength = $ThrowStrength.value / 100
	if tween != null: tween.kill()
	$Aim/AimSound.stop()
	$ThrowStrength.value = 0
	$ThrowStrength.visible = false
	var angle = player_node.global_position.angle_to(%Camera.get_global_mouse_position())
	player_node.throw(throw_strength, angle)
	$Cooldown.visible = true
	var throw_tween = get_tree().create_tween()
	throw_tween.tween_property($Cooldown, "value", 100, throw_cooldown_time - 0.1)
	is_throw_on_cooldown = true
	$ThrowCooldown.start(throw_cooldown_time)

func _on_karma_changed(amount):
	change_karma(amount)

func change_karma(amount: int):
	var step = 1
	if abs(amount) >= 1000:
		step = 100
	elif abs(amount) >= 100:
		step = 10
	else:
		step = 1
	# Убеждаемся, что шаг не превышает оставшуюся сумму
	#if amount < 0:
		#step = -step
	var current_amount = abs(amount)
	# Запускаем цикл для изменения кармы
	while current_amount != 0:
		var change_step = 0
		if abs(current_amount) >= abs(step):
			change_step = step
		else:
			# Если оставшаяся сумма меньше шага, меняем на неё
			change_step = current_amount
		# Обновляем карму и UI
		if amount > 0:
			Karma.add_karma(change_step)
		else:
			Karma.remove_karma(change_step)
		$MarginContainer/Karma/Label.text = str(Karma.karma)
		# Вычитаем из оставшейся суммы
		current_amount -= change_step
		# Задержка
		await get_tree().create_timer(0.01).timeout
	if Karma.karma >= 0: $MarginContainer/Karma/KarmaTexture.texture = good_karma_icon
	else: $MarginContainer/Karma/KarmaTexture.texture = bad_karma_icon

func remove_karma():
	if Karma.karma > 0: return
	var karma_needed_to_became_zero = abs(Karma.karma)
	change_karma(karma_needed_to_became_zero)
	var guard_progress_tween = create_tween()
	guard_progress_tween.tween_property(%GuardProgress, "value", 0, 2.0)
	$MarginContainer/Karma/KarmaTexture.texture = good_karma_icon

func increase_area_dangerous(amount):
	var guard_progress_tween = create_tween()
	guard_progress_tween.tween_property(%GuardProgress, "value", amount, 2.0)

func add_item(item_name, amount):
		if amount == 0: return
		if item_name == "coin":
			if coin_tween != null:
				coin_tween = create_tween()
				coin_tween.tween_property($MarginContainer/Inventory/Coin, "scale", Vector2(1.2, 1.2), 0.2)
				coin_tween.tween_property($MarginContainer/Inventory/Coin, "scale", Vector2(1.0, 1.0), 0.2)
			$MarginContainer/Inventory/Money.set_text(str(Inventory.get_money_count()))
		else:
			Inventory.add_item(item_name, amount)

func remove_item(item_name, amount):
	if amount == 0: return
	Inventory.remove_item(item_name, amount)
	if item_name == "coin":
		if coin_tween != null:
			coin_tween = create_tween()
			coin_tween.tween_property($MarginContainer/Inventory/Coin, "scale", Vector2(1.2, 1.2), 0.2)
			coin_tween.tween_property($MarginContainer/Inventory/Coin, "scale", Vector2(1.0, 1.0), 0.2)
	$MarginContainer/Inventory/Money.set_text(str(Inventory.player_inventory[item_name]))

func _process(delta: float) -> void:
	if is_aiming and not is_player_control_blocked:
		aim.global_position = get_global_mouse_position()
		aim.rotation += delta
	$DebugLabel.set_text(str(is_player_control_blocked))

func _player_control_blocked(blocked : bool):
	if blocked:
		is_stealth_mode_on = false
		is_player_control_blocked = true
		$Aim.visible = false
		$ThrowStrength.visible = false
		$ThrowStrength.value = 0
		$StealthLeft/StealthCooldown.value = 0
		$StealthLeft/StealthCooldown.visible = false
		$StealthRight/StealthCooldown.value = 0
		$StealthRight/StealthCooldown.visible = false
		$Pray.disabled = true
		$StealthLeft.disabled = true
		$StealthRight.disabled = true
		is_throw_on_cooldown = false
		is_stealth_on_cooldown = false
		player_node.cancel_all_actions()
	else:
		is_stealth_mode_on = false
		$Pray.disabled = false
		$StealthLeft.disabled = false
		$StealthRight.disabled = false
		is_player_control_blocked = false

func stealth_mode(mode : bool):
	if is_aiming : return
	is_stealth_mode_on = mode
	if is_stealth_mode_on == true:
		$Pray.disabled = true
		player_node.stealth()
		AudioManager.play_sound(SoundCache.sneak_sound)
	else:
		$Pray.disabled = false
		player_node.remove_stealth()

func _on_throw_cooldown_timeout() -> void:
	$Cooldown.value = 0
	is_throw_on_cooldown = false
	$Cooldown.visible = false

func _on_stealth_button_down() -> void:
	if not is_player_control_blocked: 
		stealth_mode(true)

func _on_stealth_button_up() -> void:
	if not is_player_control_blocked:
		stealth_mode(false)
		$StealthLeft.disabled = true
		$StealthRight.disabled = true
		$StealthLeft/StealthCooldown.visible = true
		$StealthRight/StealthCooldown.visible = true
		var stealth_tween = create_tween()
		stealth_tween.tween_property($StealthLeft/StealthCooldown, "value", 100, stealth_cooldown_time - 0.1)
		stealth_tween.parallel()
		stealth_tween.tween_property($StealthRight/StealthCooldown, "value", 100, stealth_cooldown_time - 0.1)
		await stealth_tween.finished
		is_stealth_on_cooldown = false
		if not is_player_control_blocked:
			$StealthLeft/StealthCooldown.visible = false
			$StealthLeft/StealthCooldown.value = 0
			$StealthLeft.disabled = false
			$StealthRight/StealthCooldown.visible = false
			$StealthRight/StealthCooldown.value = 0
			$StealthRight.disabled = false

func _on_pray_pressed() -> void:
	player_node.visual_component.pray()

func _on_player_pray_finished():
	var karma_amount = Karma.karma
	if karma_amount < 0:
		if abs(karma_amount) > Inventory.get_money_count(): return
	else:
		remove_karma()
		Inventory.remove_money(abs(karma_amount))

func _on_player_criminal(is_criminal : bool):
	if is_criminal:
		$CriminalIcon.visible = true
		$CriminalIcon/AnimationPlayer.play("Fly")
	else:
		$CriminalIcon.visible = false
		$CriminalIcon/AnimationPlayer.stop()

func _on_player_item_dropped(item_name, item_amount):
	match item_name:
		"coin":
			remove_item("coin", item_amount)

func _on_player_change_money_count(amount):
	if amount > 0:
		add_item("coin", amount)
	else:
		remove_item("coin", abs(amount))
