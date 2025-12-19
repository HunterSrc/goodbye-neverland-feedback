extends Area2D

func is_on_beat_attack() -> bool:
	return get_parent().is_on_beat()

func is_attack_active() -> bool:
	return not $CollisionShape2D.disabled
