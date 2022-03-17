extends Camera2D

var active = false

var target: Node2D = null

var check_divisor: = 15
var frame_count: = 0

func start() -> void:
	active = true
	current = true

func _process(_delta):
	frame_count += 1
	if frame_count % check_divisor == 0:
		check_for_leader()
	
	if target:
		global_position = target.global_position

func check_for_leader():
	var racers = get_tree().get_nodes_in_group("Racers")
	
	var max_track_index = 0
	var tie_breaker = 0
	
	for r in racers:
		if r.finished:
			continue
		
		if r.current_track_index > max_track_index:
			max_track_index = r.current_track_index
			tie_breaker = r.current_tie_breaker
			target = r
		elif r.current_track_index == max_track_index:
			if r.current_tie_breaker < tie_breaker:
				tie_breaker = r.current_tie_breaker
				target = r
				
