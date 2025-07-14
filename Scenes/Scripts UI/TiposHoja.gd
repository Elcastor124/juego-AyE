extends OptionButton

var option_button = self # Cambia por la ruta a tu nodo

func _ready():
	option_button.add_item("Mixto", 0)
	option_button.add_item("Tomate", 1)
	option_button.add_item("Melon", 2)
	option_button.add_item("Calabacin", 3)
	option_button.add_item("Viña", 4)
	for i in range(option_button.get_item_count()):
		if option_button.get_item_id(i) == Global.tipohoja:
			option_button.select(i)
			break




func _on_OptionButton_item_selected(index):
	Global.tipohoja = option_button.get_item_id(index)

