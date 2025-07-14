extends OptionButton

var option_button = self # Cambia por la ruta a tu nodo

func _ready():
	option_button.add_item("Marrón", 1)
	option_button.add_item("Blanco", 2)
	option_button.add_item("Amarillo", 3)
	
	# Selecciona el item según Global.color
	for i in range(option_button.get_item_count()):
		if option_button.get_item_id(i) == Global.color:
			option_button.select(i)
			break



func _on_OptionButton_item_selected(index):
	Global.color = option_button.get_item_id(index)
	print(Global.color)
