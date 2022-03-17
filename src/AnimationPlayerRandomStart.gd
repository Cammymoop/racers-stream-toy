extends AnimationPlayer

export var start_range: float = 0.5

func _ready():
	var playing = current_animation
	stop()
	yield(get_tree().create_timer(rand_range(0, start_range)), "timeout")
	play(playing)
	
