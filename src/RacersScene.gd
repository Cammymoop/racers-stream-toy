extends Node2D

export(PackedScene) var racer_scene = preload("res://src/Racer.gd")

var racers_amount = 0
var queued_racers = []
var race_active = false

onready var manual_racer_dialog = find_node("ManualRacersDialog")
onready var leaderboard = find_node("Leaderboard")

func add_racer(racer_name, color) -> void:
	pass
	var racer = racer_scene.instance()
	racer.tag = racer_name
	racer.track_node = $ProceduralTrack.get_path()
	$Racers.add_child(racer)
	racer.set_color(color)
	
	var positions_avail = $StartingZone.get_child_count()
	
	racer.rotation = 0
	racer.global_position = $StartingZone.get_child(racers_amount % positions_avail).global_position
	var back_place = floor(racers_amount / positions_avail)
	racer.global_position.x -= back_place * 30
	
	racer.connect("i_finished", self, "a_racer_finished")
	
	racers_amount += 1

func a_racer_finished(racer) -> void:
	leaderboard.add_racer(racer)
	leaderboard.visible = true

func _ready():
	$RaceCam.start()
	
	var temp_racer = racer_scene.instance()
	manual_racer_dialog.find_node("ColorSelect").set_items(temp_racer.valid_colors)
	
	manual_racer_dialog.popup_centered()

func make_racers() -> void:
	queued_racers.shuffle()
	
	for racer_info in queued_racers:
		add_racer(racer_info["name"], racer_info["color"])
	
func _process(_delta):
	if Input.is_action_pressed("start"):
		race_active = true
		var racers = get_tree().get_nodes_in_group("Racers")
		for r in racers:
			r.start_race()
		
		set_process(false)


func _on_ManualRacersDialog_confirmed():
	queued_racers = manual_racer_dialog.racer_values
	
	make_racers()
