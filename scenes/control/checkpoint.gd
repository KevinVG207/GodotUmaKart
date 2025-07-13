extends BasePoint

class_name Checkpoint

@export var is_key: bool = false

@export var begin_node := false
@export var end_node := false
var segment: CheckpointManager.CheckpointSegment
var index: int = -1

var length: float = 1.0
var length_until: float = 0.0
var segment_fraction: float = -1
var segment_fraction_start: float = -1
@export var gravity_zone: Node3D = null

# Called when the node enters the scene tree for the first time.
func _ready():
	#visible = false
	pass
