extends HBoxContainer

func set_racer_name(racer_name: String) -> void:
	$Label.text = racer_name

func set_windshield_from_racer(racer) -> void:
	var windshield_tex = racer.get_windshield_tex()
	$Icon/Spinny.set_windshield_tex(windshield_tex)
