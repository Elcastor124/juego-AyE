extends OptionButton

var option_button = self # Cambia por la ruta a tu nodo

func _ready():
	option_button.add_item("Mixto", 0)  # Desactiva la opción
	option_button.add_item("Infección leve", 1)
	option_button.add_item("Infección media", 2)
	option_button.add_item("Infección grave", 3)




func _on_OptionButton_item_selected(index):
	Global.modo = index
