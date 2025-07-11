extends Button

var escena_principal = "res://Scenes/Menu_principal.tscn"


func _on_Button_pressed():
	self.get_tree().change_scene(escena_principal)
