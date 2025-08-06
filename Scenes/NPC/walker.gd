extends Node2D

class_name walker

var parent
var movement_component
@onready var drop_position = $Drop_Position
@onready var battle : Brawl = get_node("/root/World/Brawl")

var speed
var is_indicator_active : bool = false
var spawn_point
var despawn_point
var is_moving_to_the_left_side : bool
var walker_name : String
var movement_tween : Tween = null
var names = ["Alex","Cooper","Cob","Matew","Alan","Michael","Bob","Spaghetti","Volter",
"Adam","Nicolas","Hash","Kevin","Tyler","John","George","Daniel","Steven","Luke","Joseph"]
var position_before_chase : Vector2

func setup_component(_spawn_point, _despawn_point, _parent, _movement_component):
	parent = _parent
	movement_component = _movement_component
	walker_name = names[randi_range(0, names.size() - 1)]
	$DebugLabel.set_text(walker_name)
	self.spawn_point = _spawn_point
	self.despawn_point = _despawn_point
	parent.global_position = _spawn_point.global_position

#func look_at_direction(_point : Vector2):
	#%ViewArea.rotation = parent.global_position.angle_to_point(_point)
	#if parent.global_position.x < _point.x:
		#parent.scale = Vector2(1,1)
		#%Dialogue/Background.global_position = %Dialogue/LeftSide.global_position
	#else: 
		#parent.scale = Vector2(-1,1)
		#%Dialogue/Background.global_position = %Dialogue/RightSide.global_position

#func move_to_point(_point = despawn_point.global_position):
	#Logger.log(walker_name, str(" Двигаюсь из ", parent.global_position, " к ",  movement_component.movement_target))
	#_point = movement_component.movement_target
	#look_at_direction(_point)
	#Logger.log(walker_name, str(" Двигаюсь из ", parent.global_position, " в ",  _point))
	#var move_distance = parent.global_position.distance_to(_point)
	#speed = move_distance / 1000.0 * movement_component.walk_speed
	#print("I'm here")
	#movement_tween = create_tween()
	#movement_tween.tween_property(parent, "global_position", _point, speed)
	#%Actions.add_action(movement_tween, str(walker_name, " Движение к ", _point))

#func stop_moving():
	#%Actions.cancel_action(movement_tween)
	#%Character.stop_animation()

#func _process(_delta: float) -> void:
	#pass
	##$DebugLabel.set_text(str(%StateMachine.state.keys()[%StateMachine.current_state]))
	##$DebugLabel.set_text(str(character.is_head_damaged))

func _on_collect_area_body_entered(body: Node2D) -> void:
	body.destroy()
