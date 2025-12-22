extends StaticBody2D

@export var amplitude: Vector2 = Vector2(120, 0)
@export var speed: float = 80.0
@export var start_offset: float = 0.0
@export var debug_enabled: bool = false

var _origin: Vector2
var _time: float = 0.0


func d(msg: String) -> void:
	if debug_enabled:
		print("[MovingPlatform] " + msg)


func _ready() -> void:
	_origin = global_position
	_time = start_offset


func _physics_process(delta: float) -> void:
	_time += delta * speed / 100.0
	var t := sin(_time)
	global_position = _origin + amplitude * t
