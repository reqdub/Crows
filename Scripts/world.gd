extends Node2D

var player_node : player
@onready var indicator_node = $Background/OffScreenIcon
@onready var offscreen_indicator = preload("res://Scenes/entity_off_screan_indicator.tscn")
@onready var audio_manager = $AudioManager

func _ready() -> void:
	%DayNightCycle.connect("dawn", %Spawner._on_daytime_dawn)
	%DayNightCycle.connect("day", %Spawner._on_daytime_day)
	%DayNightCycle.connect("dusk", %Spawner._on_daytime_dusk)
	%DayNightCycle.connect("night", %Spawner._on_daytime_night)
	$Background/Player_Position.add_child(load("res://Scenes/Player.tscn").instantiate())
	player_node = get_node("Background/Player_Position/Player")
	player_node.statue = %GoddessPosition.global_position
	player_node.connect("weapon_count_changed", %WeaponScrollBar._on_weapon_count_changed)
	player_node.connect("add_weapon", %WeaponScrollBar._on_weapon_added)
	player_node.connect("update_inventory", %UI._on_update_inventory)
	%WeaponScrollBar.connect("weapon_changed", player_node.change_weapon)
	Karma.player_node = player_node
	Karma.connect("danger_increases", %Spawner._on_danger_increases)
	%UI.connect_player(player_node)
	%Brawl.player_node = player_node
	AudioManager.setup()
	audio_manager.setup()
	audio_manager.play_music()

func _on_dead_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Throwable"): body.destroy()

func _on_collect_area_body_entered(body: Node2D) -> void:
	body.queue_free()
	%UI.add_item("coin", 1)

func _on_drop_area_body_entered(_body: Node2D) -> void:
	pass

func _on_floor_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("Throwable"): body.disable()

func _on_destroy_throwable_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Throwable"):
		body.destroy()

func _on_off_screen_icon_body_entered(body: Node2D) -> void:
	if body.is_in_group("Character"):
		return
		if body.is_indicator_active: return
		var offscreen_indicator_instance = offscreen_indicator.instantiate()
		if body.global_position.x < 0:
			offscreen_indicator_instance.setup_indicator($Background/OffScreenIcon/LeftPositionMarker.global_position)
		else: offscreen_indicator_instance.setup_indicator($Background/OffScreenIcon/RightPositionMarker.global_position)
		indicator_node.call_deferred("add_child", offscreen_indicator_instance)
		body.is_indicator_active = true
