extends AcceptDialog

onready var name_input = find_node("NameEdit")
onready var color_input = find_node("ColorSelect")
onready var racers_list: ItemList = find_node("RacersList")

var racer_values = []

func _ready():
	get_close_button().visible = false
	
	try_loading_last_racers()

func _on_AddButton_pressed():
	var racer_name = name_input.text
	var racer_color = color_input.selected_value
	var racer_dict = {"name": racer_name, "color": racer_color}
	add_racer_to_list(racer_dict)
	#racers_list.add_item(racer_display_name(racer_name, racer_color))
	racer_values.append(racer_dict)

func add_racer_to_list(a_racer_dict: Dictionary) -> void:
	var icon = load("res://assets/img/racer1_glass_" + a_racer_dict["color"] + ".png") as Texture
	if icon:
		var scaled_img = Utility.image_2x(icon.get_data())
		var scaled_tex = ImageTexture.new()
		scaled_tex.create_from_image(scaled_img)
		racers_list.add_item(a_racer_dict["name"], scaled_tex)
	else:
		racers_list.add_item(racer_display_name(a_racer_dict["name"], a_racer_dict["color"]))
	

func racer_display_name(racer_name: String, racer_color: String) -> String:
	return racer_name + " - " + racer_color[0].to_upper() + racer_color.substr(1)

func try_loading_last_racers() -> void:
	var f = File.new()
	
	if not f.file_exists("user://last_racers.json"):
		return
	if f.open("user://last_racers.json", File.READ) != OK:
		print_debug("cant open")
		return
	
	var parsed_racers = JSON.parse(f.get_as_text())
	if parsed_racers.error != OK:
		print_debug("failed parse")
		return
	
	racer_values = parsed_racers.result
	
	racers_list.clear()
	for a_racer in racer_values:
		add_racer_to_list(a_racer)
	
	f.close()

func _on_ManualRacersDialog_confirmed() -> void:
	var json_racers = JSON.print(racer_values)
	var f = File.new()
	
	if f.open("user://last_racers.json", File.WRITE) == OK:
		f.store_string(json_racers)
		f.close()


func _on_RemoveButton_pressed():
	var selected_indexes = racers_list.get_selected_items()
	if len(selected_indexes) < 1:
		return
	
	selected_indexes.invert()
	for selected_index in selected_indexes:
		racer_values.remove(selected_index)
		racers_list.remove_item(selected_index)
