extends Area2D

@export var is_ai = false
var is_selected = false
var max_move_distance = 4
var health = 10
var attack = 2
var range = 20
var moved = false
var attacked = false

func _ready():
	add_to_group("units")
	if is_ai:
		add_to_group("ai_units")
		$Sprite2D2.set_visible(true)
func _process(delta):
	if is_ai:
		moved = false
		attacked = false

# Called when a unit is selected or clicked on
func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not moved:
			is_selected = true
			get_tree().root.get_child(0).select_unit(self)  # Inform the game controller
			moved = true
		else:
			print("Unit already moved!")

# Called when this unit takes damage
func take_damage(damage: int):
	health -= damage
	print("Unit took damage, remaining health: ", health)
	if health <= 0:
		print("Unit has been defeated!")
		remove_from_group("units")
		if is_ai:
			remove_from_group("ai_units")  
		queue_free()
		# Remove the unit from the scene

func attack_unit(target_unit: Area2D):
	if attacked == false:
		if target_unit and target_unit is Area2D:
			attacked = true
			target_unit.take_damage(attack)
		else:
			print("This unit already attacked this turn.")


func _on_button_pressed() -> void:
	moved = false
	attacked = false
