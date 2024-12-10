extends ProgressBar
@onready var Unit = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.value = Unit.health


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.value = Unit.health
