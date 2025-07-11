extends Button

var escena_ajustes = "res://Scenes/Ajustes.tscn"

func _on_Button_pressed():
	var timer = Timer.new()
	timer.wait_time = 0.55
	timer.one_shot = true
	timer.connect("timeout", self, "_cambiar_escena")
	add_child(timer)
	timer.start()


func _cambiar_escena():
	get_tree().change_scene(escena_ajustes)
