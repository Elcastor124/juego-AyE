extends OptionButton

var option_button = self # Cambia por la ruta a tu nodo

func _ready():
	option_button.add_item("Mixto", 4)
	option_button.add_item("Infección leve", 1)
	option_button.add_item("Infección media", 2)
	option_button.add_item("Infección grave", 3)




func _on_OptionButton_item_selected(index):
	Global.modo = option_button.get_item_id(index)
	print(Global.modo)
