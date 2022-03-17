tool
extends Node2D

export var gen_new_track: = false setget do_gen_new_track

export var min_sections: int = 140
export var max_sections: int = 140

export var lights_every: int = 8

var track_radius = 47.5

var ts_straight = preload("res://TrackSections/StraightTS.tscn")
var ts_right = preload("res://TrackSections/RightTurnTS.tscn")
var ts_left = preload("res://TrackSections/LeftTurnTS.tscn")

var finish_line = preload("res://TrackSections/FinishLine.tscn")

var a_light = preload("res://Decorations/TrackLight.tscn")

export var track_points: PoolVector2Array

export var point_rotations: Array

func _ready():
	var finish = $TrackNodes/FinishLine/FinishDetector
	if finish:
		finish.connect("body_entered", self, "finish_entered")

func do_gen_new_track(val) -> void:
	if Engine.editor_hint and val:
		make_track()

func clear_all_track_nodes() -> void:
	for c in $TrackNodes.get_children():
		c.queue_free()

func make_track() -> void:
	var track_pos = Vector2.ZERO
	var track_rotation = 0
	track_points = PoolVector2Array()
	
	var track_nodes = $TrackNodes
	
	var section_counter = 1
	var static_amount = 0
	var static_section = "straight"
	
	var scene_root = get_tree().get_edited_scene_root()
	
	clear_all_track_nodes()
	
	var section_count = floor(min_sections + rand_range(0, max_sections - min_sections))
	
	for _i in range(section_count):
		track_points.append(track_pos)
		point_rotations.append(track_rotation)
		# Make some light at regular intervals
		if section_counter % lights_every == 0:
			var l = a_light.instance()
			track_nodes.add_child(l)
			l.global_position = track_pos
			l.rotation = track_rotation + (0.0 if randf() >= 0.5 else PI)
			# make it real
			l.owner = scene_root
			
		var new_section: StaticBody2D
		
		var r = randf()
		if static_amount < 1:
			if r >= 0.5:
				new_section = ts_straight.instance()
				static_section = ts_straight
			elif r >= 0.25:
				new_section = ts_right.instance()
				static_section = ts_right
			else:
				new_section = ts_left.instance()
				static_section = ts_left
			
			if randf() >= 0.1:
				static_amount = 1 + rand_range(0, 11)
		else:
			static_amount -= 1
			new_section = static_section.instance()
		
		track_nodes.add_child(new_section)
		
		# make it real
		new_section.owner = scene_root
		new_section.global_position = track_pos
		new_section.rotation = track_rotation
		
		var new_pos: = new_section.get_node("EndPoint") as Position2D
		track_pos = new_pos.global_position
		track_rotation += new_pos.rotation
		
		section_counter += 1
	
	var finish = finish_line.instance()
	track_nodes.add_child(finish)
	finish.owner = scene_root
	finish.global_position = track_pos
	finish.rotation = track_rotation

func get_point_offseted_by(point_index, amount) -> Vector2:
	if point_index >= min(len(track_points), len(point_rotations)):
		print_debug("Missing point " + str(point_index))
		return Vector2.ZERO
	var adjusted_amount = amount * track_radius * 0.9
	
	var amount_vec = (Vector2.UP * adjusted_amount).rotated(point_rotations[point_index])
	return track_points[point_index] + amount_vec

func get_baked_points() -> PoolVector2Array:
	return track_points

func finish_entered(body: PhysicsBody2D):
	if body.has_method("finish"):
		body.finish()
