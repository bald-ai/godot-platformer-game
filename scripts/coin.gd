extends Area2D

@onready var game_manager: Node = %GameManager
@onready var pickup_sound: AudioStreamPlayer2D = $PickupSound
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _on_body_entered(body: Node2D) -> void:
	game_manager.add_point()
	pickup_sound.play()
	
	# disable visibility of sprite
	animated_sprite.visible = false
	
	# disable collision of coin
	collision_shape.set_deferred("disabled", true)
	
	await pickup_sound.finished
	queue_free()
