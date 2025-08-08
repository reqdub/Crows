extends Control

@onredy var line : Line2D = $Buttons/Line2D
var buttons : Array = [$Buttons/Inventory, $Buttons/Skills, $Buttons/Menu]
var selected_menu
var drag_started : bool = false

func _on_menu_button_button_down() -> void:
	drag_started = true

func _on_menu_button_button_up() -> void:
	drag_started = false

func menu_category_selected():
	pass
	
func find_nearest_menu():
	pass

func _process(delta: float) -> void:
	if drag_started:
		line.points[1] = %Camera.get_global_mouse_position()
