extends Button

var escena_usuario = "res://Scenes/Usuario.tscn"




func _on_Iniciar_Sesin_pressed():
	self.get_tree().change_scene(escena_usuario)
