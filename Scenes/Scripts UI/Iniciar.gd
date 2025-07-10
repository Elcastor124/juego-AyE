extends Button

var escena_principal = "res://Scenes/main.tscn"

func _ready():
	text = "Iniciar"

func _on_Iniciar_pressed():
	text = "Cargando..."
	
	# Usamos un timer para dar tiempo a que el texto se actualice antes de cambiar escena
	var timer = Timer.new()
	timer.wait_time = 1
	timer.one_shot = true
	timer.connect("timeout", self, "_cambiar_escena")
	add_child(timer)
	timer.start()

func _cambiar_escena():
	get_tree().change_scene(escena_principal)
