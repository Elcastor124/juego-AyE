extends Node2D

export(Array, String) var image_paths = [
	"res://IMAGES/calabacin.png",
	"res://IMAGES/depositphotos_5783793-stock-photo-vine-leaf-removebg-preview.png",
	"res://IMAGES/melon.png",
	"res://IMAGES/tomate-removebg-preview.png"
]

export(float) var min_value = 0.1
export(float) var max_value = 0.5
export(float) var noise_scale = 20.0
export(float) var threshold = 0.09
export(Array, Color) var infection_colors = [
	Color(0.45, 0.3, 0.1),
	Color(0.7, 0.6, 0.1),
	Color(0.2, 0.2, 0.2),
	Color(0.4, 0.1, 0.1),
	Color(0.1, 0.3, 0.1)
]

var real_noise_percentage = 0.0
var seeds = 1234

func _ready():
	randomize()
	seeds = randi()
	var target_noise_ratio = randf() * (max_value - min_value) + min_value
	var selected_image_path = image_paths[randi() % image_paths.size()]

	var img = Image.new()
	if img.load(selected_image_path) != OK:
		print("Error al cargar la imagen: ", selected_image_path)
		return

	var noise = OpenSimplexNoise.new()
	noise.seed = seeds
	noise.octaves = 4
	noise.period = 10.0
	noise.persistence = 0.5

	var width = img.get_width()
	var height = img.get_height()

	# Recopilar píxeles válidos
	var valid_pixels = []
	img.lock()
	for y in range(height):
		for x in range(width):
			if img.get_pixel(x, y).a > 0.01:
				valid_pixels.append(Vector2(x, y))
	img.unlock()

	var total_pixels = valid_pixels.size()
	if total_pixels == 0:
		print("No hay píxeles válidos en la imagen.")
		return

	valid_pixels.shuffle()

	# Inicializar infección
	var seeds_count = int(total_pixels * 0.01)
	# En Godot 3.x no hay slice, hacemos esto para obtener la sublista:
	var initial_infected = valid_pixels.duplicate()
	initial_infected.resize(seeds_count)

	var infected_set = {}  # simula un Set con diccionario
	var infected_pixels = []
	var queue = initial_infected.duplicate()


	var directions = [Vector2(-1,0), Vector2(1,0), Vector2(0,-1), Vector2(0,1)]
	var max_queue_size = 10000  # evitar crecimiento descontrolado

	img.lock()
	while infected_pixels.size() < int(total_pixels * target_noise_ratio) and queue.size() > 0:
		var current = queue.pop_front()

		if infected_set.has(current):
			continue # ya procesado

		infected_set[current] = true

		var x = int(current.x)
		var y = int(current.y)

		var col = infection_colors[randi() % infection_colors.size()]
		img.set_pixel(x, y, col)
		infected_pixels.append(current)

		for offset in directions:
			var neighbor = current + offset
			if infected_set.has(neighbor):
				continue
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= width or neighbor.y >= height:
				continue
			if img.get_pixel(neighbor.x, neighbor.y).a <= 0.01:
				continue

			var n = noise.get_noise_2d(neighbor.x / noise_scale, neighbor.y / noise_scale)
			if n > threshold and randf() < 0.7:
				queue.append(neighbor)

		if queue.size() > max_queue_size:
			break
	img.unlock()

	# Cálculo del porcentaje
	real_noise_percentage = float(infected_pixels.size()) * 100.0 / float(total_pixels)

	# Mostrar resultado
	var tex = ImageTexture.new()
	tex.create_from_image(img)

	var sprite = Sprite.new()
	sprite.texture = tex
	add_child(sprite)

	crear_ui()


func crear_ui():
	var label = Label.new()
	label.text = "¿Cuánto ruido hay en la imagen? (porcentaje)"
	label.rect_position = Vector2(-150, -250)
	add_child(label)

	var input = LineEdit.new()
	input.name = "NoiseInput"
	input.rect_position = Vector2(-200, 227)
	add_child(input)

	var boton = Button.new()
	boton.text = "Enviar"
	boton.rect_position = Vector2(-100, 227)
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
