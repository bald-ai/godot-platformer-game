extends Area2D

@onready var timer: Timer = $Timer

func _on_body_entered(body: Node2D) -> void:
	# If this killzone belongs to an EnemyBullet and the player is parrying, destroy the bullet and ignore damage
	if body.is_in_group("Player") and body.has_method("is_parrying_active") and body.is_parrying_active():
		var p := get_parent()
		if p and p.is_in_group("EnemyBullet"):
			p.queue_free()
			return
	print("You died!")
	Engine.time_scale = 0.5
	var shape := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null:
		shape = body.find_child("CollisionShape2D", true, false) as CollisionShape2D
	if shape == null:
		shape = body.find_child("CollisionShape2D2", true, false) as CollisionShape2D
	if shape:
		shape.queue_free()
	else:
		print("Killzone: Collision shape not found on ", body.name)
	# Use a SceneTreeTimer and connect directly to SceneTree so reload happens even if this node is freed
	get_tree().create_timer(0.6).timeout.connect(get_tree().reload_current_scene)


func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
