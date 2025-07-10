extends OptionButton

var option_button = self # Cambia por la ruta a tu nodo

func _ready():
	option_button.add_item("Selecciona un modo")
	option_button.set_item_disabled(0, true)  # Desactiva la opción
	option_button.add_item("Infección leve", 1)
	option_button.add_item("Infección media", 2)
	option_button.add_item("Infección grave", 3)
