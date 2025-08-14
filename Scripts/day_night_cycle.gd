extends CanvasModulate

# Цвета для разных времён суток
@export var dawn_color: Color = Color("c46f6b")
@export var day_color: Color = Color.WHITE
@export var sunset_color: Color = Color("ff7057")
@export var night_color: Color = Color("#1a1a2a")
@export var transition_speed: float = 120.0

@onready var left_lamp = $PointLight2D
@onready var right_lamp = $PointLight2D2

enum TimeState {
	DAWN,   # 0
	DAY,    # 1
	DUSK, # 2
	NIGHT   # 3
}

var current_time: TimeState = TimeState.DAY
var is_cycling: bool = false

signal new_day_started

signal dawn
signal day
signal night
signal dusk

func _ready():
	color = day_color
	start_cycle()

func start_cycle():
	if not is_cycling:
		is_cycling = true
		cycle()

func cycle():
	match current_time:
		TimeState.DAWN:
			left_lamp.enabled = false
			right_lamp.enabled = false
			left_lamp.scale = Vector2(0.3, 0.3)
			print("Начался рассвет")
			dawn.emit()
			new_day_started.emit()
			await change_cycle_color(day_color, Vector2(0.3, 0.3), 0.1)
			current_time = TimeState.DAY
			
		TimeState.DAY:
			await get_tree().create_timer(transition_speed).timeout
			print("Начался день")
			day.emit()
			await change_cycle_color(sunset_color, Vector2(0.4, 0.4), 0.2)
			current_time = TimeState.DUSK
			
		TimeState.DUSK:
			left_lamp.enabled = true
			right_lamp.enabled = true
			print("Начался закат")
			dusk.emit()
			await change_cycle_color(night_color, Vector2(1.0, 1.0), 0.8)
			current_time = TimeState.NIGHT
			
		TimeState.NIGHT:
			await get_tree().create_timer(transition_speed / 4.0).timeout
			print("Настала ночь")
			night.emit()
			await change_cycle_color(dawn_color, Vector2(1.2, 1.2), 1.0)
			current_time = TimeState.DAWN
	
	# Цикл продолжается автоматически
	cycle()

func change_cycle_color(target_color: Color, target_scale, target_light_energy) -> void:
	var tween = create_tween()
	tween.tween_property(self, "color", target_color, transition_speed)
	tween.parallel()
	tween.tween_property(left_lamp, "scale", target_scale, transition_speed)
	tween.parallel()
	tween.tween_property(right_lamp, "scale", target_scale, transition_speed)
	tween.parallel()
	tween.tween_property(left_lamp, "energy", target_light_energy, transition_speed)
	tween.parallel()
	tween.tween_property(right_lamp, "energy", target_light_energy, transition_speed)
	await tween.finished
	# Добавляем небольшую паузу между переходами
	await get_tree().create_timer(1.0).timeout
