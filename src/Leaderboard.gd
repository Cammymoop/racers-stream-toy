extends PanelContainer

var lb_item = preload("res://LeaderboardItem.tscn")

func add_racer(the_racer) -> void:
	var new_item = lb_item.instance()
	$MarginContainer/VBoxContainer.add_child(new_item)
	new_item.set_racer_name(the_racer.tag)
	new_item.set_windshield_from_racer(the_racer)
