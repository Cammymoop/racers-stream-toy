tool
extends Node

func _ready():
	if not Engine.editor_hint:
		randomize()

func image_2x(in_img: Image) -> Image:
	var new_img = Image.new()
	new_img.create(in_img.get_width() * 2, in_img.get_height() * 2, true, Image.FORMAT_RGBA8)
	
	in_img.lock()
	new_img.lock()
	
	for x in in_img.get_width():
		for y in in_img.get_height():
			var col = in_img.get_pixel(x, y)
			new_img.set_pixel(x * 2,     y * 2,     col)
			new_img.set_pixel(x * 2 + 1, y * 2,     col)
			new_img.set_pixel(x * 2,     y * 2 + 1, col)
			new_img.set_pixel(x * 2 + 1, y * 2 + 1, col)
	
	in_img.unlock()
	new_img.unlock()
	
	return new_img

# returns two new vector2 arrays of points representing a border on both sides expanded by width
func get_path_rails(points: PoolVector2Array, width: float) -> Array:
	var left_rail = PoolVector2Array()
	var right_rail = PoolVector2Array()
	
	var first: = true
	var previous_angle: Vector2 = Vector2.ZERO
	
	var left_intersect_mode: = false
	var right_intersect_mode: = false
	
	for p_index in len(points)-1:
		var line_angle: Vector2 = (points[p_index+1] - points[p_index]).normalized()
		var corner_angle = PI
		if not first:
			corner_angle = previous_angle.rotated(PI).angle_to(line_angle)
			if abs(corner_angle - PI) < 0.001:
				corner_angle = PI
		
		var left_diff: = left_normal(line_angle) * width
		var lp1 = points[p_index] + left_diff
		var lp2 = points[p_index+1] + left_diff
		
		if corner_angle > 0 and corner_angle < PI:
			var last_a = left_rail[len(left_rail) - 2]
			var last_b = left_rail[len(left_rail) - 1]
			if lines_intersect(lp1, lp2, last_a, last_b):
				var intersect_point = get_intersect_point(lp1, lp2, last_a, last_b)
				left_rail[len(left_rail) - 1] = intersect_point
				left_rail.append(lp2)
				
				if left_intersect_mode:
					var b = left_rail[len(left_rail) - 2]
					var sane = 50
					var end = max(1, len(left_rail) - sane)
					for i in range(len(left_rail) - 4, end - 1, -1):
						if lines_intersect(lp2, b, left_rail[i], left_rail[i-1]):
							var a = get_intersect_point(lp2, b, left_rail[i], left_rail[i-1])
							left_rail.resize(i)
							left_rail.append(a)
							left_rail.append(lp2)
							left_intersect_mode = false
							break
			else:
				left_intersect_mode = true
				left_rail.append(lp1)
				left_rail.append(lp2)
		else:
			left_rail.append(lp1)
			left_rail.append(lp2)
			if left_intersect_mode:
				var c = left_rail[len(left_rail) - 3]
				var sane = 50
				var end = max(1, len(left_rail) - sane)
				for i in range(len(left_rail) - 4, end - 1, -1):
					if lines_intersect(lp2, c, left_rail[i], left_rail[i-1]):
						var a = get_intersect_point(lp2, c, left_rail[i], left_rail[i-1])
						left_rail.resize(i)
						left_rail.append(a)
						if lines_intersect(lp1, c, left_rail[i], left_rail[i-1]):
							left_rail.append(lp1)
						left_rail.append(lp2)
						left_intersect_mode = false
						break
		
		var right_diff: = right_normal(line_angle) * width
		var rp1 = points[p_index] + right_diff
		var rp2 = points[p_index+1] + right_diff
		
		if corner_angle < 0 and corner_angle > -PI:
			var last_a = right_rail[len(right_rail) - 2]
			var last_b = right_rail[len(right_rail) - 1]
			if lines_intersect(rp1, rp2, last_a, last_b):
				var intersect_point = get_intersect_point(rp1, rp2, last_a, last_b)
				right_rail[len(right_rail) - 1] = intersect_point
				right_rail.append(rp2)
				
				if right_intersect_mode:
					var b = right_rail[len(right_rail) - 2]
					var sane = 50
					var end = max(1, len(right_rail) - sane)
					for i in range(len(right_rail) - 4, end - 1, -1):
						if lines_intersect(rp2, b, right_rail[i], right_rail[i-1]):
							var a = get_intersect_point(rp2, b, right_rail[i], right_rail[i-1])
							right_rail.resize(i)
							right_rail.append(a)
							right_rail.append(rp2)
							right_intersect_mode = false
							break
			else:
				right_intersect_mode = true
				right_rail.append(rp1)
				right_rail.append(rp2)
		else:
			right_rail.append(rp1)
			right_rail.append(rp2)
			if right_intersect_mode:
				var c = right_rail[len(right_rail) - 3]
				var sane = 50
				var end = max(1, len(right_rail) - sane)
				for i in range(len(right_rail) - 4, end - 1, -1):
					if lines_intersect(rp2, c, right_rail[i], right_rail[i-1]):
						var a = get_intersect_point(rp2, c, right_rail[i], right_rail[i-1])
						right_rail.resize(i)
						right_rail.append(a)
						if lines_intersect(rp1, c, right_rail[i], right_rail[i-1]):
							right_rail.append(rp1)
						right_rail.append(rp2)
						right_intersect_mode = false
						break
				
		
		
		previous_angle = line_angle
		if first:
			first = false
	
	return [left_rail, right_rail]
	

func left_normal(angle_vec: Vector2) -> Vector2:
	return angle_vec.rotated(-PI/2)

func right_normal(angle_vec: Vector2) -> Vector2:
	return angle_vec.rotated(PI/2)

func is_point_in_segment(point, a, b) -> bool:
	if a.x == b.x:
		if a.y > point:
			return b.y <= point.y
		else:
			return b.y > point.y
	else:
		if a.x > point:
			return b.x <= point.x
		else:
			return b.x > point.x

# Returns an array of the coefficient and offset that describes the line that points a and b lie on
func line_equation(a, b) -> Array:
	var coefficient = (b.y - a.y)/(b.x - a.x)
	return [coefficient, a.y - (coefficient*a.x)]

func get_intersect_point(a1, b1, a2, b2) -> Vector2:
	if a1.x == b1.x:
		return get_intersect_point_with_vertical(a2, b2, a1, b1)
	elif a2.x == b2.x:
		return get_intersect_point_with_vertical(a1, b1, a2, b2)
	
	var a_equation = line_equation(a1, b1)
	var b_equation = line_equation(a2, b2)
	
	# algebra to get the common point of the lines that contain these line segments
	var x = (b_equation[1] - a_equation[1])/(a_equation[0] - b_equation[0])
	var y = x*a_equation[0] + a_equation[1]
	
	# We could check if the point lies on both segments, but we have 
	# the more efficient method that already checked for AN instersection
	return Vector2(x, y)

func get_intersect_point_with_vertical(a, b, va, _vb) -> Vector2:
	var line_eq = line_equation(a, b)
	return Vector2(va.x, va.x*line_eq[0] + line_eq[1])

func lines_intersect(a1: Vector2, b1: Vector2, a2: Vector2, b2: Vector2) -> bool:
	var a_a1b1 = (b1 - a1).angle()
	var a_b1a2 = (a2 - b1).angle()
	var a_b1b2 = (b2 - b1).angle()
	
	var diff1 = a_a1b1 - a_b1a2
	var diff2 = a_a1b1 - a_b1b2
	
	if diff1 == 0:
		if diff2 == 0:
			return true
	elif diff2 != 0:
		if sign(diff1) == sign(diff2):
			return true
	
	var a_a2b2 = (b2 - a2).angle()
	var a_b2a1 = (a1 - b2).angle()
	var a_b2b1 = (b1 - b2).angle()
	
	var diff3 = a_a2b2 - a_b2a1
	var diff4 = a_a2b2 - a_b2b1
	
	if diff3 == 0:
		if diff4 == 0:
			return true
	elif diff4 != 0:
		if sign(diff3) == sign(diff4):
			return true
	
	return false
	
