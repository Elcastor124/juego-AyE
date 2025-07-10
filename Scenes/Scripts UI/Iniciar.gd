extends Button

var escena_principal = "res://Scenes/main.tscn"

func _on_Iniciar_pressed():
	self.get_tree().change_scene(escena_principal)
