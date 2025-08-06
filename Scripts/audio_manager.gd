# audiomanager.gd
extends Node

# Словарь для отслеживания времени последнего воспроизведения каждого звука.
# Это поможет избежать слишком частого повторения одного и того же звука.
var last_played_time = {}
var music_list = []
var last_player_music
# Минимальный интервал в секундах между воспроизведениями одного и того же звука.
const PLAY_DELAY = 0.05

var sound_players

func setup():
	sound_players = get_node("/root/World/AudioManager/SFX").get_children()
	music_list.append("Forest.mp3")
	music_list.append("ForestDay.mp3")
	music_list.append("Oakvale.mp3")

func play_music():
	var temp_music = music_list
	var random_music = temp_music[randi_range(0, temp_music.size() - 1)]
	if last_player_music == random_music:
		temp_music.erase(random_music)
		random_music = temp_music[randi_range(0, temp_music.size() - 1)]
	last_player_music = random_music
	%MusicPlayer.stream = load(str("res://Music/", random_music))
	%MusicPlayer.play()

func play_sound(sound: AudioStream):
	# Проверяем, не проигрывался ли этот звук слишком недавно
	if last_played_time.has(sound) and Time.get_ticks_msec() - last_played_time[sound] < PLAY_DELAY * 1000:
		return # Игнорируем вызов, если звук проигрывался недавно

	# Ищем свободный проигрыватель
	for sound_player : AudioStreamPlayer in sound_players:
		if not sound_player.is_playing():
			# Загружаем и проигрываем звук
			sound_player.stream = sound
			sound_player.play()
			# Обновляем время последнего воспроизведения
			last_played_time[sound] = Time.get_ticks_msec()
			return # Выходим из функции, так как звук запущен

	# Если все проигрыватели заняты, можно либо ничего не делать,
	# либо реализовать логику приоритетов (например, прерывать звук с низким приоритетом).

func _on_music_player_finished() -> void:
	play_music()
