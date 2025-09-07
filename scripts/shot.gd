extends Area2D

@export var speed: float = 600.0
var velocity: Vector2

func _ready():
	$AnimatedSprite2D.play("shot")
	await $AnimatedSprite2D.animation_finished
	
	$AnimatedSprite2D.play("fly")

func _process(delta):
	position += velocity * delta

func _on_body_entered(body):
	$AnimatedSprite2D.play("impact")
	await $AnimatedSprite2D.animation_finished
	
	queue_free()
	
	
