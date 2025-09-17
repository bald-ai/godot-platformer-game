extends Node

var score = 0
@onready var score_label: Label = $ScoreLabel

func _ready() -> void:
	Engine.time_scale = 0.85


func add_point():
	score += 1
	score_label.text = "You collected " + str(score) + " coins."
