extends Node2D

@onready var tilemap = $TileMap
var selected_unit = null
var range_positions: Array = []  # Store the positions for drawing
var range_color : Color = Color(0.5, 0.0, 0.0, 0.5) # Dark Red without transparency
var attack_range_color : Color = Color(0.0, 1.0, 0.0, 0.5) # Green color for attack range

func _ready():
	range_positions.clear()
	
func _process(delta):
	var ai_unitss = get_tree().get_nodes_in_group("ai_units")
	var unitss = get_tree().get_nodes_in_group("units")
	if len(ai_unitss) <= 0:
		get_tree().change_scene_to_file("res://win.tscn")
	elif len(unitss)-len(ai_unitss) <= 0:
		get_tree().change_scene_to_file("res://loss.tscn")

# Select the unit (left-click)
func select_unit(unit):
	if unit.is_in_group("ai_units"):  # Prevent selecting AI units
		print("Cannot select AI unit!")
		return
		
	if selected_unit:
		selected_unit.is_selected = false
	selected_unit = unit
	show_movement_range()

# Display the movement range of the selected unit
func show_movement_range():
	range_positions.clear()
	var current_grid_position = tilemap.local_to_map(selected_unit.position)
	var max_move_distance = selected_unit.max_move_distance

	# Calculate movement range
	for x in range(-max_move_distance, max_move_distance + 1):
		for y in range(-max_move_distance, max_move_distance + 1):
			var target_position = Vector2(current_grid_position.x + x, current_grid_position.y + y)
			var distance = current_grid_position.distance_to(target_position)
			if distance <= max_move_distance:
				range_positions.append(target_position)

	queue_redraw()

# Display the attack range of the selected unit
func show_attack_range():
	var attack_positions = []  # List of positions within attack range
	var current_grid_position = tilemap.local_to_map(selected_unit.position)
	var attack_range = selected_unit.range  # Use the range property of the unit

	# Calculate attack range
	for x in range(-attack_range, attack_range + 1):
		for y in range(-attack_range, attack_range + 1):
			var target_position = Vector2(current_grid_position.x + x, current_grid_position.y + y)
			var distance = current_grid_position.distance_to(target_position)
			if distance <= attack_range:
				attack_positions.append(target_position)

	# Draw attack range
	for grid_position in attack_positions:
		var tile_size = tilemap.tile_set.get_tile_size()
		var tile_center = tilemap.map_to_local(Vector2(grid_position.x, grid_position.y)) + tile_size / 2.0
		var rect_position = tile_center - tile_size / 2.0
		draw_rect(Rect2(rect_position, tile_size), attack_range_color)

# Draw the movement range on the screen
func _draw():
	if range_positions.size() == 0:
		return

	var tile_size = tilemap.tile_set.get_tile_size()

	# Draw the movement range in red
	for grid_position in range_positions:
		var tile_center = tilemap.map_to_local(Vector2(grid_position.x, grid_position.y)) + tile_size / 2.0
		var rect_position = tile_center - tile_size / 2.0
		draw_rect(Rect2(rect_position, tile_size), range_color)

# Move the unit when left-clicked
func move_unit_to_tile(mouse_position: Vector2):
	var local_position = tilemap.to_local(mouse_position)
	var grid_position = tilemap.local_to_map(local_position)
	var tile_size = tilemap.tile_set.get_tile_size()
	var cell_center = tilemap.map_to_local(Vector2(grid_position.x, grid_position.y)) + tile_size / 2.0
	var current_grid_position = tilemap.local_to_map(selected_unit.position)
	var distance = current_grid_position.distance_to(grid_position)
	var tile_set = tilemap.tile_set
	var tile_data = tilemap.get_cell_tile_data(0,Vector2i(grid_position.x, grid_position.y))
	var cus_data = tile_data.get_custom_data("is_passable")
	
	if distance <= selected_unit.max_move_distance:
		if cus_data == true:
			selected_unit.position = tilemap.to_global(cell_center)
			selected_unit.is_selected = false
			range_positions.clear()
			selected_unit = null
			range_positions.clear()
			queue_redraw()
		else:
			print("Terrain is impassable!")
	else:
		print("Move too far! Maximum allowed distance is: ", selected_unit.max_move_distance)

# Handle both movement and attack based on click
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if selected_unit:
				move_unit_to_tile(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if selected_unit:
				var target_unit = get_target_under_mouse()
				if target_unit and target_unit != selected_unit:  # Check if the target is different from the selected unit
					if is_target_in_range(selected_unit, target_unit):  # Check if the target is within attack range
						selected_unit.attack_unit(target_unit)
					else:
						print("Target out of range!")

# Check if the target is within attack range
func is_target_in_range(attacker_unit: Area2D, target_unit: Area2D) -> bool:
	var current_grid_position = tilemap.local_to_map(attacker_unit.position)
	var target_grid_position = tilemap.local_to_map(target_unit.position)
	var attack_range = attacker_unit.range

	var distance = current_grid_position.distance_to(target_grid_position)
	return distance <= attack_range

# Check the target unit under the mouse for right-click attack
func get_target_under_mouse() -> Area2D:
	var mouse_position = get_global_mouse_position()
	var overlapping_bodies = get_tree().get_nodes_in_group("units")  # Changed from "player_units"
	for body in overlapping_bodies:
		if body is Area2D:
			var collision_shape = body.get_node("CollisionShape2D")
			if collision_shape and collision_shape.shape and collision_shape.shape is RectangleShape2D:
				var rect_position = body.global_position
				var rect_size = collision_shape.shape.extents * 2  # Get the size of the rectangle shape
				var rect_area = Rect2(rect_position - rect_size / 2, rect_size)
				
				if rect_area.has_point(mouse_position):
					return body
	return null

# AI Behavior (triggered by button press)
func on_ai_turn_pressed():
	selected_unit = null
	var ai_units = get_tree().get_nodes_in_group("ai_units")
	var units = get_tree().get_nodes_in_group("units")  # Changed from "player_units" to "units"
	for unit in units:
		unit.moved = false
		unit.attacked = false
	# AI decision-making
	for ai_unit in ai_units:
		if ai_unit and ai_unit is Area2D:
			# Check if the AI unit can attack any player unit (those not in ai_units group)
			var target_unit = get_target_in_range(ai_unit, units)  # Check against all units
			if target_unit:
				ai_unit.attack_unit(target_unit)
			else:
				# Move towards the nearest unit if not in attack range
				var nearest_unit = get_nearest_unit(ai_unit, units)
				if nearest_unit:
					move_towards_unit(ai_unit, nearest_unit)

# Get the target unit within attack range
func get_target_in_range(ai_unit: Area2D, units: Array) -> Area2D:
	for unit in units:
		if unit and unit is Area2D and not unit.is_in_group("ai_units"):  # Ensure target is not AI unit
			if is_target_in_range(ai_unit, unit):  # Correct call here
				return unit
	return null

# Get the nearest unit to the AI unit
func get_nearest_unit(ai_unit: Area2D, units: Array) -> Area2D:
	var closest_distance = INF
	var nearest_unit = null

	for unit in units:
		if unit and unit is Area2D and not unit.is_in_group("ai_units"):  # Ensure the unit is not AI
			var distance = ai_unit.global_position.distance_to(unit.global_position)
			if distance < closest_distance:
				closest_distance = distance
				nearest_unit = unit

	return nearest_unit

# Move the AI unit towards the nearest unit, with alternate pathfinding if tile is impassable
func move_towards_unit(ai_unit: Area2D, target_unit: Area2D):
	# Ensure AI unit moves only within its max_move_distance
	var direction = (target_unit.global_position - ai_unit.global_position).normalized()
	var move_speed = 100  # Speed of the AI unit
	var move_distance = ai_unit.max_move_distance * 15  # AI unit's movement limit
	var move_vector = direction * move_speed * get_process_delta_time()
	var new_position = ai_unit.global_position + move_vector

	# Convert to grid position to check passability
	var new_grid_position = tilemap.local_to_map(tilemap.to_local(new_position))

	# Check the destination tile and its surrounding tiles
	if !is_passable_and_surroundings(new_grid_position):
		print("Target tile or surrounding tiles are impassable! Searching for an alternate route.")
		
		# Try moving to an adjacent passable tile (excluding adjacent to impassable)
		var adjacent_positions = [
			Vector2(new_grid_position.x + 1, new_grid_position.y),  # Right
			Vector2(new_grid_position.x - 1, new_grid_position.y),  # Left
			Vector2(new_grid_position.x, new_grid_position.y + 1),  # Down
			Vector2(new_grid_position.x, new_grid_position.y - 1),  # Up
			Vector2(new_grid_position.x + 1, new_grid_position.y + 1),  # Down-Right (diagonal)
			Vector2(new_grid_position.x - 1, new_grid_position.y + 1),  # Down-Left (diagonal)
			Vector2(new_grid_position.x + 1, new_grid_position.y - 1),  # Up-Right (diagonal)
			Vector2(new_grid_position.x - 1, new_grid_position.y - 1),  # Up-Left (diagonal)
		]

		var found_valid_tile = false
		for pos in adjacent_positions:
			if is_passable_and_surroundings(pos):
				var new_local_position = tilemap.map_to_local(Vector2(pos.x, pos.y))
				# Calculate movement to this tile and ensure we don't exceed max move distance
				move_vector = (new_local_position - ai_unit.global_position).normalized() * move_distance
				ai_unit.global_position = ai_unit.global_position + move_vector
				found_valid_tile = true
				break

		# If no valid adjacent tiles are found, stop or return to the previous position
		if not found_valid_tile:
			print("No alternate passable tiles found! Stopping movement.")
	else:
		# Move to the destination tile, ensuring we do not exceed max_move_distance
		move_vector = (new_position - ai_unit.global_position).normalized() * move_distance
		ai_unit.global_position = ai_unit.global_position + move_vector

# Check if a tile and its surroundings are passable
func is_passable_and_surroundings(grid_position: Vector2) -> bool:
	# Check the destination tile
	var tile_data = tilemap.get_cell_tile_data(0, Vector2i(grid_position.x, grid_position.y))
	var cus_data = tile_data.get_custom_data("is_passable")
	
	# If the destination tile is not passable, return false
	if cus_data != true:
		return false
	
	# Check all adjacent tiles (including diagonals)
	var surrounding_positions = [
		Vector2(grid_position.x + 1, grid_position.y),  # Right
		Vector2(grid_position.x - 1, grid_position.y),  # Left
		Vector2(grid_position.x, grid_position.y + 1),  # Down
		Vector2(grid_position.x, grid_position.y - 1),  # Up
		Vector2(grid_position.x + 1, grid_position.y + 1),  # Down-Right (diagonal)
		Vector2(grid_position.x - 1, grid_position.y + 1),  # Down-Left (diagonal)
		Vector2(grid_position.x + 1, grid_position.y - 1),  # Up-Right (diagonal)
		Vector2(grid_position.x - 1, grid_position.y - 1),  # Up-Left (diagonal)
	]
	
	# Check each surrounding tile to see if it is passable
	for pos in surrounding_positions:
		tile_data = tilemap.get_cell_tile_data(0, Vector2i(pos.x, pos.y))
		cus_data = tile_data.get_custom_data("is_passable")
		if cus_data != true:
			# If any surrounding tile is not passable, return false
			return false

	# All checks passed, so the tile and its surroundings are passable
	return true


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	pass # Replace with function body.
