extends Node2D

# Sistema particelle per break di NoiseBlock
# Crea particelle più grandi che si disperdono in tutte le direzioni

@export var particle_count: int = 12
@export var particle_speed_min: float = 80.0
@export var particle_speed_max: float = 200.0
@export var particle_lifetime: float = 0.5
@export var particle_color: Color = Color(0.75, 0.75, 0.85, 1.0)  # Colore del NoiseBlock

var particles: Array[Polygon2D] = []


func _ready() -> void:
	# Crea le particelle
	for i in range(particle_count):
		var particle = Polygon2D.new()
		var size = randf_range(6, 10)
		particle.polygon = PackedVector2Array([Vector2(-size/2, -size/2), Vector2(size/2, -size/2), Vector2(size/2, size/2), Vector2(-size/2, size/2)])
		particle.color = particle_color
		particle.visible = false
		add_child(particle)
		particles.append(particle)


func emit(from_pos: Vector2) -> void:
	# Emetti particelle dal punto di break
	for i in range(particles.size()):
		var particle = particles[i]
		particle.global_position = from_pos
		particle.visible = true
		particle.modulate.a = 1.0
		particle.scale = Vector2(1.0, 1.0)
		
		# Direzione casuale
		var angle = (TAU / particle_count) * i + randf_range(-0.3, 0.3)
		var direction = Vector2(cos(angle), sin(angle))
		var speed = randf_range(particle_speed_min, particle_speed_max)
		
		# Anima la particella
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Movimento
		var target_pos = from_pos + direction * speed * particle_lifetime
		tween.tween_property(particle, "global_position", target_pos, particle_lifetime)
		
		# Fade out
		tween.tween_property(particle, "modulate:a", 0.0, particle_lifetime)
		
		# Rotazione casuale
		var rotation_amount = randf_range(-PI, PI)
		tween.tween_property(particle, "rotation", rotation_amount, particle_lifetime)
		
		# Scale down
		tween.tween_property(particle, "scale", Vector2(0.3, 0.3), particle_lifetime)
		
		# Nascondi dopo l'animazione (non await, usa callback)
		tween.tween_callback(func(): particle.visible = false; particle.scale = Vector2(1.0, 1.0); particle.rotation = 0.0).set_delay(particle_lifetime)

