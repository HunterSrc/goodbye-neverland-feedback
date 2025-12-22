extends Node2D

# Sistema particelle semplice per hit su NoiseBlock
# Crea particelle che si disperdono dal punto di impatto

@export var particle_count: int = 8
@export var particle_speed: float = 120.0
@export var particle_lifetime: float = 0.3
@export var particle_color: Color = Color(1.0, 1.0, 0.8, 1.0)  # Giallo chiaro

var particles: Array[Polygon2D] = []


func _ready() -> void:
	# Crea le particelle
	for i in range(particle_count):
		var particle = Polygon2D.new()
		particle.polygon = PackedVector2Array([Vector2(-2, -2), Vector2(2, -2), Vector2(2, 2), Vector2(-2, 2)])
		particle.color = particle_color
		particle.visible = false
		add_child(particle)
		particles.append(particle)


func emit(from_pos: Vector2) -> void:
	# Emetti particelle dal punto di impatto
	for i in range(particles.size()):
		var particle = particles[i]
		particle.global_position = from_pos
		particle.visible = true
		particle.modulate.a = 1.0
		
		# Direzione casuale
		var angle = (TAU / particle_count) * i + randf_range(-0.2, 0.2)
		var direction = Vector2(cos(angle), sin(angle))
		
		# Anima la particella
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Movimento
		var target_pos = from_pos + direction * particle_speed * particle_lifetime
		tween.tween_property(particle, "global_position", target_pos, particle_lifetime)
		
		# Fade out
		tween.tween_property(particle, "modulate:a", 0.0, particle_lifetime)
		
		# Scale down
		tween.tween_property(particle, "scale", Vector2(0.5, 0.5), particle_lifetime)
		
		# Nascondi dopo l'animazione (non await, usa callback)
		tween.tween_callback(func(): particle.visible = false; particle.scale = Vector2(1.0, 1.0)).set_delay(particle_lifetime)
