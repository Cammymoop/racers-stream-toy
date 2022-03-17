extends Node2D

export var spin_speed = PI/1.5

func _process(delta):
	rotation += delta * spin_speed

func set_windshield_tex(new_tex: Texture) -> void:
	$Sprite2.texture = new_tex
