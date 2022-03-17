tool
extends Node2D

export var update_collision: = false setget set_update_collision

var track_path: Path2D

func set_update_collision(val) -> void:
	if Engine.editor_hint and val:
		make_line(true)

func _ready():
	track_path = $TrackPath
	if Engine.editor_hint:
		track_path.curve.connect("changed", self, "path_updated")
	else:
		track_path.curve.get_baked_length()

func path_updated() -> void:
	make_line()

func make_line(do_collisions: bool = false) -> void:
	var baked_points = track_path.curve.get_baked_points()
	$PathRender.points = baked_points
	$PathRenderGlow.points = baked_points
	
	var rails = Utility.get_path_rails(baked_points, 30)
	$RailLeftPreview.points = rails[0]
	$RailRightPreview.points = rails[1]
	
	var final_point_i = track_path.curve.get_point_count() - 1
	var final_point = track_path.curve.get_point_position(final_point_i)
	var control_point = track_path.curve.get_point_in(final_point_i)
	print(final_point, control_point)
	
	if control_point == Vector2.ZERO:
		control_point = track_path.curve.get_point_position(final_point_i - 1)
	else:
		control_point = final_point + control_point
	
	var ending_angle = (final_point - control_point).angle()
	$FinishLine.position = final_point
	$FinishLine.rotation = ending_angle
	
	if not do_collisions:
		return
	
	clear_collisions()
	
	for rail in rails:
		for i in range(1, len(rail)):
			var node = CollisionShape2D.new()
			var shape = SegmentShape2D.new()
			shape.a = rail[i-1]
			shape.b = rail[i]
			node.shape = shape
			$CollisionRails.add_child(node)
			node.owner = get_tree().get_edited_scene_root()

func clear_collisions():
	for c_shape in $CollisionRails.get_children():
		c_shape.queue_free()

func get_baked_points():
	var baked_local = track_path.curve.get_baked_points()
	var baked_global = PoolVector2Array()
	for point in baked_local:
		baked_global.append(transform.xform(point))
	return baked_global

func get_closest_point(to_pos: Vector2, lookahead: int = 1) -> Vector2:
	to_pos = transform.affine_inverse().xform(to_pos)
	var curve: Curve2D = track_path.curve
	var point_pos = curve.get_closest_point(to_pos)
	if lookahead == 0:
		return transform.xform(point_pos)
	
	var point_index = -1
	var baked = curve.get_baked_points()
	for p_index in len(baked):
		var l = (baked[p_index] - point_pos).length_squared()
		if l < 5:
			point_index = p_index
	if point_index == -1:
		print_debug("could not find closest point's index")
		return transform.xform(point_pos)
	
	var lookahead_index = min(len(baked)-1, point_index+lookahead)
	return transform.xform(baked[lookahead_index])


func _on_FinishDetector_body_entered(body: PhysicsBody2D):
	if body.has_method("finish"):
		body.finish()
