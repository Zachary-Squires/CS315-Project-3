extends Camera2D

func zoom():
	if Input.is_action_just_released('wheel_down'):
		set_zoom(get_zoom() - Vector2(0.25, 0.25))
	if Input.is_action_just_released('wheel_up'):
		set_zoom(get_zoom() + Vector2(0.25, 0.25))

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Move the camera to the clicked position when the right mouse button is pressed
			var target_position = get_local_mouse_position()
			set_position(target_position)

func _physics_process(delta):
	zoom()
