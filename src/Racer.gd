extends RigidBody2D

signal i_finished

export var tag: String

export var initial_thrust: float = 65.0
export var driving_thrust: float = 65.0

export (NodePath) var track_node
onready var the_track: Node2D = get_node(track_node)

var baked_points: PoolVector2Array
var fix_mode: = false

var thrust: float = 0
var driving: = false
var finished: = false
var showing_thrust: = false

var current_track_index: = 0
var current_tie_breaker: float = 0

onready var current_track_orthagonal_target = rand_range(-0.5, 0.5)

var valid_colors = [
	"black", "blue", "green", "mint", "pink", "potato", "pumpkin", "purple", "red", "white", "yellow",
]

func _ready():
	showing_thrust = false
	$Burner.visible = false
	$SmokeParticles.emitting = false
	
	if tag:
		find_node("Label").text = tag
	
	var thrust_adjust = rand_range(0.99, 1.01)
	initial_thrust = initial_thrust * thrust_adjust
	driving_thrust = driving_thrust / thrust_adjust
	
	if linear_damp == -1:
		linear_damp = ProjectSettings.get_setting("physics/2d/default_linear_damp") * rand_range(0.95, 1.05)
	if angular_damp == -1:
		angular_damp = ProjectSettings.get_setting("physics/2d/default_angular_damp") * rand_range(0.95, 1.05)
	
	physics_material_override.bounce += rand_range(0, 0.05)
	
	set_thrust(initial_thrust)
	
	if the_track:
		baked_points = the_track.get_baked_points()
	
	var rand_color = randi() % len(valid_colors)
	
	set_color(valid_colors[rand_color])

func set_color(color_name: String) -> void:
	if not color_name in valid_colors:
		color_name = "white"
	
	var windshield_tex: Texture = load("res://assets/img/racer1_glass_" + color_name + ".png")
	$SpriteWindshield.texture = windshield_tex
	var img = windshield_tex.get_data()
	
	img.lock()
	var bright_color = img.get_pixel(5, 6)
	img.unlock()
	
	$Burner.self_modulate = bright_color
	$Burner/BurnerLight.color = bright_color
	

func get_windshield_tex() -> Texture:
	return $SpriteWindshield.texture

func start_race() -> void:
	driving = true

func set_thrust(thrust_amount) -> void:
	thrust = thrust_amount

func show_thrust() -> void:
	if showing_thrust:
		return
	showing_thrust = true
	$Burner.visible = true
	$SmokeParticles.emitting = true
func hide_thrust() -> void:
	if not showing_thrust:
		return
	showing_thrust = false
	$Burner.visible = false
	$SmokeParticles.emitting = false

func _physics_process(_delta):
	if not driving:
		applied_torque = 0
		applied_force = Vector2.ZERO
		hide_thrust()
		return
	
	if thrust > 0:
		applied_force = Vector2.RIGHT.rotated(rotation) * thrust
	else:
		applied_force = Vector2.ZERO
	
	var fast = linear_velocity.length() > 100
	
	if fast:
		set_thrust(driving_thrust)
	
	var target_point = find_closest_track_point(8 if fast else 4)
	var points = PoolVector2Array()
	points.append(Vector2.ZERO)
	points.append(transform.xform_inv(target_point))
	
	$ShowTarget.points = points
	
	var target_dir = target_point - global_position
	var current_facing = Vector2.RIGHT.rotated(rotation)
	var current_heading = Vector2.RIGHT.rotated(linear_velocity.angle())
	var angle_diff = current_facing.angle_to(target_dir)
	var velocity_diff = current_heading.angle_to(target_dir)
	
	var overshoot_angle = clamp(velocity_diff, -(3 * (PI/4)), 3 * (PI/2))
	if linear_velocity.length_squared() < 1000:
		overshoot_angle = 0
	points[1] = points[1].rotated(overshoot_angle)
	$ShowTarget2.points = points
	var velocity_target_diff = angle_diff + overshoot_angle
	applied_torque = 240 * sign(velocity_target_diff)
	
	var abs_ang = abs(velocity_target_diff)
	if (fix_mode and abs_ang > PI/6) or abs_ang > PI/4:
		fix_mode = true
		applied_force = Vector2.ZERO
		applied_torque *= 3
	elif fix_mode:
		set_thrust(initial_thrust)
		fix_mode = false
	
	if applied_force.length_squared() > 0:
		show_thrust()
	else:
		hide_thrust()

func find_closest_track_point(lookahead: int = 1) -> Vector2:
	
	var min_dist: float = -1
	var found_index = -1
	for p_i in len(baked_points):
		var dist = (global_position - baked_points[p_i]).length_squared()
		if min_dist < 0 or dist < min_dist:
			min_dist = dist
			found_index = p_i
	
	current_track_index = found_index
	var next = min(len(baked_points) - 1, found_index + 1)
	current_tie_breaker = (baked_points[next] - global_position).length_squared()
	
	var lookahead_index = min(len(baked_points) - 1, found_index + lookahead)
	
	return the_track.get_point_offseted_by(lookahead_index, current_track_orthagonal_target)
	#return baked_points[lookahead_index]

func finish() -> void:
	finished = true
	driving = false
	emit_signal("i_finished", self)
	
