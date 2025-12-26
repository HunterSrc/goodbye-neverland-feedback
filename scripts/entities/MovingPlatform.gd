extends StaticBody2D

@export var amplitude: Vector2 = Vector2(120, 0)
@export var speed: float = 80.0
@export var start_offset: float = 0.0
@export var debug_enabled: bool = false

var _origin: Vector2
var _time: float = 0.0
var _last_position: Vector2 = Vector2.ZERO
var _riders: Array[Node2D] = []

@onready var carry_area: Area2D = get_node_or_null("CarryArea")


func d(msg: String) -> void:
	if debug_enabled:
		print("[MovingPlatform] " + msg)


func _ready() -> void:
	_origin = global_position
	_time = start_offset
	_last_position = global_position
	if carry_area:
		carry_area.body_entered.connect(_on_carry_body_entered)
		carry_area.body_exited.connect(_on_carry_body_exited)


func _physics_process(delta: float) -> void:
	_time += delta * speed / 100.0
	var t := sin(_time)
	var target := _origin + amplitude * t
	var delta_move := target - global_position
	global_position = target
	_move_riders(delta_move)
	_last_position = global_position


func _on_carry_body_entered(body: Node) -> void:
	if body is Node2D and body.is_in_group("player"):
		if not _riders.has(body):
			_riders.append(body)


func _on_carry_body_exited(body: Node) -> void:
	if body is Node2D and _riders.has(body):
		_riders.erase(body)


func _move_riders(delta_move: Vector2) -> void:
	if delta_move == Vector2.ZERO:
		return
	for i in range(_riders.size() - 1, -1, -1):
		var rider := _riders[i]
		if rider == null or not is_instance_valid(rider):
			_riders.remove_at(i)
			continue
		rider.global_position += delta_move
