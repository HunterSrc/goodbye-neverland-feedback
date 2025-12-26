extends Area2D

signal attack_hit(target: Node)

var player: Node = null
var _hit_emitted: bool = false


func _ready() -> void:
	player = get_parent()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func is_on_beat_attack() -> bool:
	if player and player.has_method("is_on_beat_attack"):
		return player.is_on_beat_attack()
	return false


func is_attack_active() -> bool:
	if player and player.has_method("is_attack_active"):
		return player.is_attack_active()
	return false


func reset_for_new_attack() -> void:
	_hit_emitted = false


func _on_area_entered(area: Area2D) -> void:
	_emit_hit_if_active(area)


func _on_body_entered(body: Node) -> void:
	_emit_hit_if_active(body)


func _emit_hit_if_active(target: Node) -> void:
	if _hit_emitted:
		return
	if not is_attack_active():
		return
	if target == player:
		return
	_hit_emitted = true
	attack_hit.emit(target)
