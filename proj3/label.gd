extends Label
@onready var Unit = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	self.text = "Health:" + str(Unit.health) + "\nAttack:" + str(Unit.attack)
