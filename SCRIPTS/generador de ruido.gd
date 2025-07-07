extends Node2D

export(String) var image_path = "res://IMAGES/depositphotos_5783793-stock-photo-vine-leaf-removebg-preview.png"
export(float) var noise_ratio   # 10% de ruido
export(float) var min_value
export(float) var max_value

var real_noise_percentage = 0.0

func _ready():
	randomize()
	noise_ratio = randf() * (max_value - min_value) + min_value
	var img = Image.new()
	var err = img.load(image_path)
	if err != OK:
		print("Error al cargar la imagen.")
		return

	var width = img.get_width()
	var height = img.get_height()
	var total_pixels = 0
	var noisy_pixels = 0

	img.lock()
	for y in range(height):
		for x in range(width):
			var color = img.get_pixel(x, y)
			if color.a > 0.01:
				total_pixels += 1
				if randf() < noise_ratio:
					var noise_color = Color(1, 1, 1) if randi() % 2 == 0 else Color(0, 0, 0)
					img.set_pixel(x, y, noise_color)
					noisy_pixels += 1
	img.unlock()

	var tex = ImageTexture.new()
	tex.create_from_image(img)

	var sprite = Sprite.new()
	sprite.texture = tex
	add_child(sprite)

	# Calcular porcentaje de ruido
	if total_pixels > 0:
		real_noise_percentage = float(noisy_pixels) * 100.0 / total_pixels
	else:
		real_noise_percentage = 0.0

	crear_ui()
func crear_ui():
	var label = Label.new()
	label.text = "¿Cuánto ruido hay en la imagen? (porcentaje)"
	label.set_position(Vector2(-150, -250))
	add_child(label)

	var input = LineEdit.new()
	input.name = "NoiseInput"
	input.set_position(Vector2(-200, 227))
	add_child(input)

	var boton = Button.new()
	boton.text = "Enviar"
	boton.set_position(Vector2(-100, 227))
	boton.connect("pressed", self, "_on_boton_pressed")
	add_child(boton)
	
func _on_boton_pressed():
	var input = get_node("NoiseInput")
	var texto = input.text.strip_edges()
	var valor = texto.to_float()

	var diferencia = abs(valor - real_noise_percentage)

	if diferencia <= 5.0:
		print("¡Muy bien! Acierto cercano. Ruido real: %.2f%%" % real_noise_percentage)
	else:
		print("Fallaste. Ruido real: %.2f%%. Tu estimación: %.2f%%" % [real_noise_percentage, valor])

	
