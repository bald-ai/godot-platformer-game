extends Node2D

@onready var portal_a: Area2D = $PortalA
@onready var portal_a_dest: Marker2D = $PortalA/Destination
@onready var portal_b: Area2D = $PortalB
@onready var portal_b_dest: Marker2D = $PortalB/Destination

var cooldown = false

func _ready():
	portal_a.body_entered.connect(_on_portal_a_entered)
	portal_b.body_entered.connect(_on_portal_b_entered)

func _on_portal_a_entered(body):
	_teleport(body, portal_b_dest)

func _on_portal_b_entered(body):
	_teleport(body, portal_a_dest)

func _teleport(body, destination):
	if cooldown or not (body is Node2D):  # Change to CharacterBody2D if that's your player type
		return
		
	cooldown = true
	body.global_position = destination.global_position
	await get_tree().create_timer(0.1).timeout
	cooldown = false
