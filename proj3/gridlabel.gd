extends Label
var ai_units
var units

func _ready() -> void:
	ai_units = get_tree().get_nodes_in_group("ai_units")
	units = get_tree().get_nodes_in_group("units")

func _process(delta: float) -> void:
	ai_units = get_tree().get_nodes_in_group("ai_units")
	units = get_tree().get_nodes_in_group("units")
	self.text = "AI Units: " + str(len(ai_units)) + "\nPlayer Units: " + str(len(units)-len(ai_units))
