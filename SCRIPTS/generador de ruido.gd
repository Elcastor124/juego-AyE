extends Node2D

# Parámetros editables desde el editor
export(String) var image_path = "res://IMAGES/depositphotos_5783793-stock-photo-vine-leaf-removebg-preview.png"
export(float) var min_value := 0.1
export(float) var max_value := 0.5
export(float) var noise_scale := 20.0
export(float) var threshold := 0.09
export(Array, Color) var infection_colors := [Color(0.2, 0.1, 0.0), Color(0.5, 0.3, 0.0), Color(0.3, 0.2, 0.0)] # Editables

var real_noise_percentage := 0.0
var seeds := 0

func _ready():
	randomize()
	seeds = randi()
	var target_noise_ratio = randf() * (max_value - min_value) + min_value

	var img = Image.new()
	var err = img.load(image_path)
	if err != OK:
		print("Error al cargar la imagen.")
		return

	var noise = OpenSimplexNoise.new()
	noise.seed = seeds
	noise.octaves = 4
	noise.period = 10.0
	noise.persistence = 0.5

	var width = img.get_width()
	var height = img.get_height()

	# Contar píxeles válidos
	var total_pixels := 0
	var valid_pixels := []
	img.lock()
	for y in range(height):
		for x in range(width):
			if img.get_pixel(x, y).a > 0.01:
				valid_pixels.append(Vector2(x, y))
				total_pixels += 1
	img.unlock()

	valid_pixels.shuffle()

	# Crear mapa de infección inicial (semillas)
	var infection_map := {}
	var seeds_count := int(total_pixels * 0.01)  # 1% como focos iniciales
	var initial_infected := valid_pixels.slice(0, seeds_count)

	for pos in initial_infected:
		infection_map[pos] = true

	# Expandir infección
	var infected_pixels := []
	var infected_set := {}
	var queue := initial_infected.duplicate()

	img.lock()
	while infected_pixels.size() < int(total_pixels * target_noise_ratio) and queue.size() > 0:
		var current = queue.pop_front()
		var x = int(current.x)
		var y = int(current.y)

		# Evitar repeticiones
		if infected_set.has(current):
			continue
		infected_set[current] = true

		# Aplicar color aleatorio de la lista editable
		var color = infection_colors[randi() % infection_colors.size()]
		img.set_pixel(x, y, color)
		infected_pixels.append(current)

		# Probabilidad de infectar vecinos (más alta cerca de los focos)
		for offset in [Vector2(-1,0), Vector2(1,0), Vector2(0,-1), Vector2(0,1)]:
			var neighbor = current + offset
			if neighbor in infected_set:
				continue
			if neighbor.x >= 0 and neighbor.y >= 0 and neighbor.x < width and neighbor.y < height:
				if img.get_pixel(neighbor.x, neighbor.y).a > 0.01:
					var n = noise.get_noise_2d(neighbor.x / noise_scale, neighbor.y / noise_scale)
					if n > threshold:
						if randf() < 0.7:  # probabilidad alta de infectar al vecino
							queue.append(neighbor)
	img.unlock()

	# Resultado
	real_noise_percentage = float(infected_pixels.size()) * 100.0 / total_pixels

	# Mostrar imagen
	var tex = ImageTexture.new()
	tex.create_from_image(img)

	var sprite = Sprite.new()
	sprite.texture = tex
	add_child(sprite)

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
