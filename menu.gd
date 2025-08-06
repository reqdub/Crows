extends TextureRect

var is_buttons_blocked : bool = false

var is_music_playing : bool = true
var is_spawn_enabled : bool = true
var is_debug_enabled : bool = false
var temp_npc_count : int = 0

func _ready() -> void:
	temp_npc_count = %Spawner.max_entities
	is_debug_enabled = Logger.is_log_enabled
	if is_debug_enabled == true:
		$VBoxContainer/MarginContainer/HBoxContainer/Value/Debug/Label.set_text("Вкл")
	else:
		$VBoxContainer/MarginContainer/HBoxContainer/Value/Debug/Label.set_text("Выкл")

func _on_music_button_pressed() -> void:
	if is_buttons_blocked: return
	%MusicPlayer.stream_paused = !%MusicPlayer.stream_paused
	is_music_playing = !is_music_playing
	if is_music_playing == true:
		$VBoxContainer/MarginContainer/HBoxContainer/Value/MusicValue/Label.set_text("Вкл")
	else: $VBoxContainer/MarginContainer/HBoxContainer/Value/MusicValue/Label.set_text("Выкл")

func _on_enemies_count_button_pressed() -> void:
	if is_buttons_blocked: return
	$HScrollBar/Label.set_text(str(%Spawner.max_entities))
	is_buttons_blocked = true
	$HScrollBar.visible = true
	$ScrollOk.visible = true

func _on_spawn_button_pressed() -> void:
	if is_buttons_blocked: return
	%Spawner.spawn_enabled = !%Spawner.spawn_enabled
	is_spawn_enabled = ! is_spawn_enabled
	if is_spawn_enabled == true:
		$VBoxContainer/MarginContainer/HBoxContainer/Value/Spawn/Label.set_text("Вкл")
	else: $VBoxContainer/MarginContainer/HBoxContainer/Value/Spawn/Label.set_text("Выкл")

func _on_debug_button_pressed() -> void:
	if is_buttons_blocked: return
	Logger.is_log_enabled = !Logger.is_log_enabled
	is_debug_enabled = !is_debug_enabled
	if is_debug_enabled == true:
		$VBoxContainer/MarginContainer/HBoxContainer/Value/Debug/Label.set_text("Вкл")
	else:
		$VBoxContainer/MarginContainer/HBoxContainer/Value/Debug/Label.set_text("Выкл")

func _on_close_button_pressed() -> void:
	if is_buttons_blocked: return
	self.visible = false
	get_tree().paused = !get_tree().paused

func _on_menu_button_pressed() -> void:
	if is_buttons_blocked: return
	self.visible = !self.visible
	get_tree().paused = !get_tree().paused

func _on_h_scroll_bar_value_changed(value: float) -> void:
	temp_npc_count = int(value)
	$HScrollBar/Label.set_text(str(temp_npc_count))

func _on_ok_button_pressed() -> void:
	$ScrollOk.visible = false
	is_buttons_blocked = false
	$VBoxContainer/MarginContainer/HBoxContainer/Value/EnemiesCount/Label.set_text(str(temp_npc_count))
	%Spawner.max_entities = temp_npc_count
	$HScrollBar.visible = false

func _on_log_pressed() -> void:
	%Log.visible = !%Log.visible
