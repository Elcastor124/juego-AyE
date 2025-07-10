extends Node2D

export(Array, String) var image_paths = [
	"res://IMAGES/calabacin.png",
	"res://IMAGES/viña.png",
	"res://IMAGES/melon.png",
	"res://IMAGES/tomate.png"
]

export(float) var min_value = 0.1
export(float) var max_value = 0.5
export(float) var noise_scale = 20.0
export(float) var threshold = 0.09
export(float) var minorpercentageindex = 1.0  # Ajusta la penalización

var input_background = null
var print_label = null
var Name_label = null
var arr = null

export(Array, Color) var infection_colors = [
	Color(0.45, 0.3, 0.1),
	Color(0.7, 0.6, 0.1),
	Color(0.2, 0.2, 0.2),
	Color(0.4, 0.1, 0.1),
	Color(0.1, 0.3, 0.1)
]

var real_noise_percentage = 0.0
var score = 0
var seeds = 1234
var current_sprite = null

func _ready():
	crear_ui()
	generar_hoja_con_ruido()

func generar_hoja_con_ruido():
	if current_sprite:
		remove_child(current_sprite)
	current_sprite = null

	seeds = randi()

	var target_noise_ratio = 0.0
	var threshold = 0.0

	match Global.modo:
		1:
			# 0-25%
			target_noise_ratio = randf() * 0.25
			# map target_noise_ratio (0.0-0.25) a threshold entre 0.9 (mínimo ruido) y 0.7 (más ruido)
			threshold = lerp(0.9, 0.7, target_noise_ratio / 0.25)
		2:
			# 25-50%
			target_noise_ratio = 0.25 + randf() * 0.25
			# map target_noise_ratio (0.25-0.5) a threshold entre 0.6 (menos ruido) y 0.3 (más ruido)
			threshold = lerp(0.6, 0.3, (target_noise_ratio - 0.25) / 0.25)
		3:
			# 50-100%
			target_noise_ratio = 0.5 + randf() * 0.5
			# map target_noise_ratio (0.5-1.0) a threshold entre 0.2 (menos ruido) y -0.3 (más ruido)
			threshold = lerp(0.2, -0.3, (target_noise_ratio - 0.5) / 0.5)
		_:
			target_noise_ratio = randf()
			threshold = 0.3

	print("Modo:", Global.modo, " Ruido objetivo:", target_noise_ratio, " Threshold:", threshold)


	var selected_image_path = image_paths[randi() % image_paths.size()]
	var image_filename = selected_image_path.get_file()
	if Name_label:
		Name_label.text = "Hoja: " + image_filename

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
	var seeds_count = int(total_pixels * 0.01)
	var initial_infected = valid_pixels.duplicate()
	initial_infected.resize(seeds_count)

	var infected_set = {}
	var infected_pixels = []
	var queue = initial_infected.duplicate()

	var directions = [Vector2(-1,0), Vector2(1,0), Vector2(0,-1), Vector2(0,1)]
	var max_queue_size = 10000

	img.lock()
	while infected_pixels.size() < int(total_pixels * target_noise_ratio) and queue.size() > 0:
		var current = queue.pop_front()

		if infected_set.has(current):
			continue

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

	real_noise_percentage = float(infected_pixels.size()) * 100.0 / float(total_pixels)

	var tex = ImageTexture.new()
	tex.create_from_image(img)

	var sprite = Sprite.new()
	sprite.texture = tex
	add_child(sprite)
	current_sprite = sprite



func crear_ui():
	# Estilo de fondo para inputs y labels
	input_background = StyleBoxFlat.new()
	input_background.bg_color = Color(0.2, 0.2, 0.2, 1)
	input_background.border_color = Color(0.4, 0.4, 0.4)
	input_background.border_width_left = 2
	input_background.border_width_top = 2
	input_background.border_width_right = 2
	input_background.border_width_bottom = 2

	var font_size = 14
	var padding = font_size / 2
	input_background.content_margin_left = padding
	input_background.content_margin_right = padding
	input_background.content_margin_top = 0
	input_background.content_margin_bottom = 0

	# Label de pregunta
	var label = Label.new()
	label.text = "¿Cuánto ruido hay en la imagen? (porcentaje)"
	label.rect_position = Vector2(-150, -270)
	label.rect_min_size = Vector2(300, 30)
	label.add_stylebox_override("normal", input_background)
	label.add_color_override("font_color", Color(1, 1, 1))
	label.align = Label.ALIGN_CENTER
	label.valign = Label.VALIGN_CENTER
	add_child(label)

	# Input porcentaje
	var input = LineEdit.new()
	input.name = "NoiseInput"
	input.rect_position = Vector2(-75, 230)
	input.rect_min_size = Vector2(150, 30)
	add_child(input)

	# Botón enviar
	var boton = Button.new()
	boton.text = "Enviar"
	boton.rect_position = Vector2(85, 230)
	boton.rect_min_size = Vector2(80, 30)
	boton.connect("pressed", self, "_on_boton_pressed")
	add_child(boton)

	# Label puntuación
	var score_label = Label.new()
	score_label.name = "ScoreLabel"
	if Global.Usuario == null:
		score_label.text = "Puntuación: 0"
	else:
		var path = "res://scores.json"
		var puntuaciones = {}
		var file = File.new()

		if file.file_exists(path):
			var err = file.open(path, File.READ)
			if err == OK:
				var contenido = file.get_as_text()
				file.close()

				if contenido.strip_edges() != "":
					var json_result = JSON.parse(contenido)
					if json_result.error == OK:
						puntuaciones = json_result.result
					else:
						print("Error al parsear JSON:", json_result.error_string)
						puntuaciones = {}
				else:
					puntuaciones = {}

				var user_score = 0
				if puntuaciones.has(Global.Usuario):
					user_score = puntuaciones[Global.Usuario]

				score_label.text = "Puntuación: %d" % user_score
			else:
				print("Error al abrir archivo para lectura:", err)
				score_label.text = "Puntuación: 0"
		else:
			score_label.text = "Puntuación: 0"


	score_label.rect_position = Vector2(300, -270)
	score_label.rect_min_size = Vector2(150, 30)
	score_label.add_stylebox_override("normal", input_background)
	score_label.add_color_override("font_color", Color(1, 1, 1))
	score_label.align = Label.ALIGN_CENTER
	score_label.valign = Label.VALIGN_CENTER
	add_child(score_label)

	# Label para mensajes
	print_label = Label.new()
	print_label.name = "print_label"
	print_label.text = ""
	print_label.rect_position = Vector2(300, -220)
	print_label.rect_min_size = Vector2(150, 100)
	print_label.add_stylebox_override("normal", input_background)
	print_label.add_color_override("font_color", Color(1, 1, 1))
	print_label.align = Label.ALIGN_CENTER
	print_label.valign = Label.VALIGN_TOP
	print_label.autowrap = true
	add_child(print_label)

	# Input nombre usuario
	var user_input = LineEdit.new()
	user_input.name = "UserNameInput"
	user_input.placeholder_text = "Nombre de usuario"

	if Global.Usuario != null:
		user_input.text = Global.Usuario  # Aquí asignas el texto visible
	user_input.rect_position = Vector2(-470, -270)
	user_input.rect_min_size = Vector2(250, 30)
	add_child(user_input)

	# Botón guardar puntuación
	var save_button = Button.new()
	save_button.text = "Guardar puntuación"
	save_button.rect_position = Vector2(-310 , -270)
	save_button.rect_min_size = Vector2(140, 30)
	save_button.connect("pressed", self, "_on_save_pressed")
	add_child(save_button)
	
	
	#label Nombre hoja 
	# Label nombre de hoja
	Name_label = Label.new()
	Name_label.name = "NameLabel"
	Name_label.text = "Hoja: "
	Name_label.rect_position = Vector2(-100, 200)  # Posición debajo del sprite
	Name_label.rect_min_size = Vector2(300, 30)
	Name_label.align = Label.ALIGN_CENTER
	Name_label.valign = Label.VALIGN_CENTER
	Name_label.add_color_override("font_color", Color(1, 1, 1))
	Name_label.add_stylebox_override("normal", input_background)
	add_child(Name_label)

	

	mostrar_ranking()


func actualizar_print_label(texto: String) -> void:
	var print_label = get_node("print_label")
	print_label.text = texto
	# Ajustar tamaño mínimo vertical para que el texto quepa
	var min_size = print_label.get_minimum_size()
	print_label.rect_min_size.y = min_size.y + 10


func _on_boton_pressed():
	var input = get_node("NoiseInput")
	var texto = input.text.strip_edges()
	var valor = texto.to_float()

	var diferencia = abs(valor - real_noise_percentage)
	var puntuacion = clamp(10.0 - (diferencia * minorpercentageindex), 0, 10)

	score += int(puntuacion)

	var score_label = get_node("ScoreLabel")
	score_label.text = "Puntuación: %d" % score

	if diferencia <= 5.0:
		actualizar_print_label("¡Muy bien! Ruido real: %.2f%% - Acierto cercano." % real_noise_percentage)
	else:
		actualizar_print_label("Fallaste. Ruido real: %.2f%%. Tu estimación: %.2f%%" % [real_noise_percentage, valor])

	input.text = ""  # Limpiar input
	generar_hoja_con_ruido()


func _on_save_pressed():
	var user_input = get_node("UserNameInput")
	var nombre = user_input.text.strip_edges()

	if nombre == "":
		print("Introduce un nombre de usuario.")
		return

	var path = "res://scores.json"
	var puntuaciones = {}

	var file = File.new()
	if file.file_exists(path):
		file.open(path, File.READ)
		var contenido = file.get_as_text()
		file.close()
		if contenido != "":
			puntuaciones = parse_json(contenido)

	puntuaciones[nombre] = score

	file.open(path, File.WRITE)
	file.store_string(to_json(puntuaciones))
	file.close()

	print("Puntuación guardada para ", nombre, ": ", score)
	arr.sort_custom(self, "_sort_scores_desc")
	mostrar_ranking()


func mostrar_ranking():
	var path = "res://scores.json"
	var file = File.new()
	var puntuaciones = {}

	if file.file_exists(path):
		file.open(path, File.READ)
		var contenido = file.get_as_text()
		file.close()
		if contenido != "":
			puntuaciones = parse_json(contenido)

	arr = []
	for nombre in puntuaciones.keys():
		arr.append({"nombre": nombre, "score": puntuaciones[nombre]})
	
	ordenar_ranking(arr)  # Ordena antes de mostrar

	var ranking_panel = get_node_or_null("RankingPanel")
	if ranking_panel == null:
		ranking_panel = Panel.new()
		ranking_panel.name = "RankingPanel"
		ranking_panel.rect_position = Vector2(-470, -220)
		ranking_panel.rect_min_size = Vector2(150, 100)
		ranking_panel.add_stylebox_override("panel", input_background)
		add_child(ranking_panel)
	else:
		for child in ranking_panel.get_children():
			child.queue_free()

	var title_label = Label.new()
	title_label.text = "Ranking"
	title_label.align = Label.ALIGN_CENTER
	title_label.add_color_override("font_color", Color(1, 1, 1))
	title_label.rect_position = Vector2(0, 10)
	title_label.rect_min_size = Vector2(150, 30)
	ranking_panel.add_child(title_label)

	var ranking_container = VBoxContainer.new()
	ranking_container.name = "RankingContainer"
	ranking_container.anchor_right = 1.0
	ranking_container.anchor_bottom = 1.0
	ranking_container.margin_left = 10
	ranking_container.margin_top = 40
	ranking_container.margin_right = -10
	ranking_container.margin_bottom = -10
	ranking_panel.add_child(ranking_container)

	for entry in arr:
		var label = Label.new()
		label.text = "%s : %d" % [entry["nombre"], entry["score"]]
		label.add_color_override("font_color", Color(1, 1, 1))
		label.align = Label.ALIGN_CENTER
		ranking_container.add_child(label)

	var height = ranking_container.get_combined_minimum_size().y + title_label.rect_min_size.y + 30
	ranking_panel.rect_min_size = Vector2(150, height)

func ordenar_ranking(arr):
	for i in range(arr.size()):
		for j in range(i + 1, arr.size()):
			if arr[j]["score"] > arr[i]["score"]:
				var temp = arr[i]
				arr[i] = arr[j]
				arr[j] = temp




func _sort_scores_desc(a, b):
	return b.score - a.score
