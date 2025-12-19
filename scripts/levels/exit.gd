extends Area2D

@export var next_scene: PackedScene
@export var debug_enabled: bool = false

var _triggered: bool = false


func d(msg: String) -> void:
	if debug_enabled:
		print(msg)


func _ready() -> void:
	# In Godot 4 per Area2D di solito si usa body_entered per CharacterBody2D
	body_entered.connect(_on_body_entered)
	d("[Exit] Ready. next_scene set? %s" % str(next_scene != null))


func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if body is CharacterBody2D and body.name == "Player":
		_triggered = true
		if next_scene != null:
			GameManager.load_level(next_scene)
		else:
			print("LEVEL COMPLETE (no next_scene set)")
