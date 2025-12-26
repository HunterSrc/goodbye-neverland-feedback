extends Control

@export var prefix: String = "NOISE:"
@export var show_only_when_present: bool = true

@onready var label: Label = $Label
var gm


func _ready() -> void:
	gm = _get_gm()
	_update_text()


func _process(_delta: float) -> void:
	_update_text()


func _update_text() -> void:
	if gm == null:
		gm = _get_gm()
		if gm == null:
			return

	var progress: Dictionary = gm.get_noise_progress()
	var destroyed: int = int(progress.get("destroyed", 0))
	var total: int = int(progress.get("total", 0))

	if show_only_when_present and total == 0:
		visible = false
		return

	visible = true
	label.text = "%s %d / %d" % [prefix, destroyed, total]


func _get_gm():
	if Engine.has_singleton("GameManager"):
		return GameManager
	return get_tree().root.get_node_or_null("GameManager")
