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
export(float) var threshold 
export(float) var minorpercentageindex = 0.1  # Ajusta la penalización        
export(String) var path_json := "res://scores.json"  # Ruta del JSON
var aciertos_por_rango = { "0-25": 0, "25-50": 0, "50-100": 0 }
var intentos_por_rango = { "0-25": 0, "25-50": 0, "50-100": 0 }
var esperando_password = false
var input
var input_background = null
var print_label = null
var Name_label = null
var arr = null
var haterminado
var total_valid_pixels = 0
var my_theme = preload("res://VAmosadejarloFino.tres")
var MAX_RANKING_HEIGHT = 400  
var LABEL_WIDTH  = 140
var LABEL_MARGIN  = 0

var infection_colors = []

var real_noise_percentage = 0.0
var score = 0
var seeds 
var current_sprite = null

func _ready():
	randomize()
	crear_ui()
	centesimas = int((OS.get_ticks_usec() * OS.get_ticks_msec() / 10) % 100)  # Centésimas de segundo (0 a 99)
	seeds = randi() ^ centesimas
	match Global.color:
		1:
			infection_colors = Global.infection_colors_marron
		2:
			 infection_colors = Global.infection_colors_blanco
		3:
			infection_colors = Global.infection_colors_amarillo
		_:
			infection_colors = Global.infection_colors_marron
	
	generar_hoja_con_ruido()
	if Global.minorpercentage == null:
		Global.minorpercentage = minorpercentageindex
	minorpercentageindex = Global.minorpercentage / 100




var is_generating = false
var infected_set = {}
var infected_pixels = []
var queue = []
var img = null
var noise = null
var width = 0
var height = 0
var directions = [Vector2(-1,0), Vector2(1,0), Vector2(0,-1), Vector2(0,1)]
var target_noise_ratio = 0.0
var max_queue_size = 10000
var tex = null
var current_index = 0
var batch_size = 600  # cuantos píxeles se procesan antes de refrescar la imagen visible
var password_input
var centesimas

func _physics_process(delta):
	centesimas = int((OS.get_ticks_msec() / 10) % 100)  # Centésimas de segundo (0 a 99)
	seeds = randi() ^ centesimas


func generar_hoja_con_ruido():
	haterminado = false
	if is_generating:
		return # Ya se está generando algo

	# Ajustar target_noise_ratio y threshold según modo
	if Global.modo == 1:
		target_noise_ratio = 0.15 + randf() * 0.10  # 15% - 25%
		threshold = lerp(0.072, 0.078, target_noise_ratio / 0.25)
	elif Global.modo == 2:
		target_noise_ratio = 0.25 + randf() * 0.25  # 0.25 - 0.5
		threshold = lerp(0.06, 0.025, (target_noise_ratio - 0.25) / 0.25)
	elif Global.modo == 3:
		target_noise_ratio = 0.65 + randf() * 0.5  # 0.5 - 1.0
		threshold = lerp(0.045, -0.99, (target_noise_ratio - 0.45) / 0.45)
	else:
		target_noise_ratio = randf()  # 0.0 - 1.0
		threshold = lerp(0.072, -0.99, clamp((target_noise_ratio - 0.5) / 0.5, 0.0, 1.0))

		print("Modo:", Global.modo, " Ruido objetivo:", target_noise_ratio, " Threshold:", threshold)
		
	var selected_image_path 
	match Global.tipohoja:
		1:
			selected_image_path = "res://IMAGES/tomate.png"
		2:
			selected_image_path = "res://IMAGES/melon.png"
		3:
			selected_image_path = "res://IMAGES/calabacin.png"
		4:
			selected_image_path ="res://IMAGES/viña.png"
		_:
			selected_image_path = image_paths[randi() % image_paths.size()]
	var image_filename = selected_image_path.get_file()
	if Name_label:
		Name_label.text = "Hoja: " + image_filename.get_basename()

	img = Image.new()
	if img.load(selected_image_path) != OK:
		print("Error al cargar la imagen: ", selected_image_path)
		return

	noise = OpenSimplexNoise.new()
	noise.seed = seeds - randf()
	noise.octaves = 4
	noise.period = 10.0
	noise.persistence = 0.5

	width = img.get_width()
	height = img.get_height()

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

	infected_set.clear()
	infected_pixels.clear()
	queue = initial_infected.duplicate()
	current_index = 0
	is_generating = true




	tex = ImageTexture.new()
	tex.create_from_image(img)
	
	var sprite = Sprite.new()
	sprite.texture = tex
	add_child(sprite)
	current_sprite = sprite
	total_valid_pixels = valid_pixels.size()
	
	# Llamar al método que procesa la infección en pasos pequeños
	yield(get_tree().create_timer(0.01), "timeout")
	_process_infection_step()

func _process_infection_step():
	if not is_generating:
		return
	
	img.lock()
	var processed = 0
	while infected_pixels.size() < int(total_valid_pixels * target_noise_ratio) and queue.size() > 0 and processed < batch_size:
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

		processed += 1

	img.unlock()

	real_noise_percentage = float(infected_pixels.size()) * 100.0 / float(total_valid_pixels)



	# Actualizar la textura para que se vea el progreso
	tex.set_data(img)
	current_sprite.texture = tex

	if infected_pixels.size() >= int(total_valid_pixels * target_noise_ratio) or queue.size() == 0:
		is_generating = false
		print("Generación terminada. Ruido real: %.2f%%" % real_noise_percentage)
		haterminado = true
	else:
		# Continuar en el siguiente frame o después de un pequeño delay
		yield(get_tree().create_timer(0.01), "timeout")
		_process_infection_step()


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
	label.theme = my_theme
	add_child(label)

	# Input porcentaje
	input = LineEdit.new()
	input.name = "NoiseInput"
	input.rect_position = Vector2(-75, 230)
	input.rect_min_size = Vector2(150, 30)
	input.theme = my_theme
	input.grab_click_focus()
	add_child(input)

	# Botón enviar
	var boton = Button.new()
	boton.text = "Enviar"
	boton.rect_position = Vector2(85, 230)
	boton.rect_min_size = Vector2(80, 30)
	boton.connect("pressed", self, "_on_boton_pressed")
	boton.theme = my_theme
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
	score_label.rect_min_size = Vector2(200, 30)
	score_label.add_stylebox_override("normal", input_background)
	score_label.add_color_override("font_color", Color(1, 1, 1))
	score_label.align = Label.ALIGN_CENTER
	score_label.valign = Label.VALIGN_CENTER
	score_label.theme = my_theme
	add_child(score_label)

	# Label para mensajes
	print_label = Label.new()
	print_label.name = "print_label"
	print_label.text = ""
	print_label.rect_position = Vector2(300, -220)
	print_label.rect_min_size = Vector2(200, 100)
	print_label.add_stylebox_override("normal", input_background)
	print_label.add_color_override("font_color", Color(1, 1, 1))
	print_label.align = Label.ALIGN_LEFT
	print_label.valign = Label.VALIGN_TOP
	print_label.autowrap = true
	print_label.theme = my_theme
	add_child(print_label)

	# Input nombre usuario
	var user_input = LineEdit.new()
	user_input.name = "UserNameInput"
	user_input.placeholder_text = "Nombre de usuario"

	if Global.Usuario != null:
		user_input.text = Global.Usuario  # Aquí asignas el texto visible
	user_input.rect_position = Vector2(-470, -270)
	user_input.rect_min_size = Vector2(250, 30)
	user_input.theme = my_theme
	add_child(user_input)

	# Botón guardar puntuación
	var save_button = Button.new()
	save_button.text = "Guardar puntuación"
	save_button.rect_position = Vector2(-310 , -270)
	save_button.rect_min_size = Vector2(140, 30)
	save_button.connect("pressed", self, "_on_save_pressed")
	save_button.theme = my_theme
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
	Name_label.theme = my_theme
	add_child(Name_label)
	input.grab_focus()
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
	var valor
	if not texto.is_valid_float():
		actualizar_print_label("Introduzca un número válido (por ejemplo: 23.5)")
		return
	else:
		valor = texto.to_float()


	if haterminado and not input.text == "" and valor >= 0.0 and valor <= 100.0:
		

		var diferencia = abs(valor - real_noise_percentage)
		var puntuacion = clamp(10.0 - (diferencia * minorpercentageindex), 0, 10)

		score += int(puntuacion)

		var score_label = get_node("ScoreLabel")
		score_label.text = "Puntuación: %d" % score

		match Global.modo:
			4:
				# Clasificar según real_noise_percentage
				var rango = ""
				if real_noise_percentage <= 25.0:
					rango = "0-25"
				elif real_noise_percentage <= 50.0:
					rango = "25-50"
				else:
					rango = "50-100"

				intentos_por_rango[rango] += 1

				if diferencia <= 5.0:
					aciertos_por_rango[rango] += 1
					actualizar_print_label("Modo 0: Ruido real: %.2f%% en rango %s.\n¡Muy bien! Acierto cercano.\nPuntuación en rango: %d/%d" % [real_noise_percentage, rango, aciertos_por_rango[rango], intentos_por_rango[rango]])
				else:
					actualizar_print_label("Modo 0: Ruido real: %.2f%% en rango %s.\nFallaste. Tu estimación: %.2f%%\nPuntuación en rango: %d/%d" % [real_noise_percentage, rango, valor, aciertos_por_rango[rango], intentos_por_rango[rango]])

				# Mensaje extra para acierto o fallo
				if diferencia <= 5.0:
					actualizar_print_label("¡Muy bien! Ruido real: %.2f%% - Acierto cercano." % real_noise_percentage)
				else:
					actualizar_print_label("Fallaste. Ruido real: %.2f%%. Tu estimación: %.2f%%" % [real_noise_percentage, valor])

			_:
				var rango = ""
				if real_noise_percentage <= 25.0:
					rango = "0-25"
				elif real_noise_percentage <= 50.0:
					rango = "25-50"
				else:
					rango = "50-100"

				intentos_por_rango[rango] += 1

				if diferencia <= 5.0:
					aciertos_por_rango[rango] += 1
					actualizar_print_label("Modo 0: Ruido real: %.2f%% en rango %s.\n¡Muy bien! Acierto cercano." % [real_noise_percentage, rango])
				else:
					actualizar_print_label("Modo 0: Ruido real: %.2f%% en rango %s.\nFallaste. Tu estimación: %.2f%%" % [real_noise_percentage, rango, valor])

				var resumen = "\n--- Puntuación total por rangos ---\n"
				for r in ["0-25", "25-50", "50-100"]:
					var intentos = intentos_por_rango.get(r, 0)
					var aciertos = aciertos_por_rango.get(r, 0)

					# Solo mostrar el ruido real para el rango actual
					if r == rango:
						resumen += "Ruido real: %.2f%%\n" % real_noise_percentage

					resumen += "Rango %s: %d/%d aciertos\n" % [r, aciertos, intentos]


				actualizar_print_label(resumen) 
				input.grab_focus()

		
		# Resetear la imagen anterior
		if current_sprite:
			remove_child(current_sprite)
			current_sprite.queue_free()
			current_sprite = null

		# Resetear variables relacionadas con la generación
		infected_set.clear()
		infected_pixels.clear()
		queue.clear()
		img = null
		tex = null
		input.text = ""  # Limpiar input
		generar_hoja_con_ruido()
	elif !haterminado:
		actualizar_print_label("Por favor espere a que la generación termine")
	elif input.text == "":
		actualizar_print_label("Introduzca un porcentaje")
	elif valor < 0.0 or valor > 100.0:
		actualizar_print_label("Introduzca un número entre 0 y 100")
		return



func _on_save_pressed():
	var user_input = get_node("UserNameInput")
	var password_input = get_parent().get_node("password")
	var nombre = user_input.text.strip_edges()
	var contrasena = password_input.text.strip_edges()
	var usuarios_path = "res://usuarios.json"
	var scores_path = "res://scores.json"
	var puntuaciones = {}
	var usuarios = {}

	if nombre == "":
		print("Introduce un nombre de usuario.")
		return

	var file = File.new()

	# Cargar usuarios existentes
	if file.file_exists(usuarios_path):
		file.open(usuarios_path, File.READ)
		var contenido = file.get_as_text()
		file.close()
		if contenido != "":
			usuarios = parse_json(contenido)

	# Validar usuario
	if usuarios.has(nombre):
		if contrasena == "":
			password_input.visible = true
			print("Introduce tu contraseña para guardar la puntuación.")
			return
		elif usuarios[nombre] != contrasena:
			print("Contraseña incorrecta.")
			return
	else:
		# Usuario nuevo
		if contrasena == "":
			password_input.visible = true
			print("Introduce una contraseña para registrar el usuario.")
			return
		else:
			usuarios[nombre] = contrasena
			file.open(usuarios_path, File.WRITE)
			file.store_string(to_json(usuarios))
			file.close()
			print("Usuario registrado.")

	# Cargar puntuaciones existentes
	if file.file_exists(scores_path):
		file.open(scores_path, File.READ)
		var contenido = file.get_as_text()
		file.close()
		if contenido != "":
			puntuaciones = parse_json(contenido)

	# Guardar si la puntuación es mayor o si no existía
	if puntuaciones.has(nombre):
		if score > puntuaciones[nombre]:
			puntuaciones[nombre] = score
	else:
		puntuaciones[nombre] = score

	# Guardar puntuaciones
	file.open(scores_path, File.WRITE)
	file.store_string(to_json(puntuaciones))
	file.close()

	print("Puntuación guardada para ", nombre, ": ", score)

	password_input.visible = false # Ocultar campo de contraseña después de guardar
	contrasena = null
	password_input.text = ""
	password_input.grab_focus()

	mostrar_ranking() # Esta función debe estar definida en tu script
	input.grab_focus()




func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.scancode == KEY_ENTER or event.scancode == KEY_KP_ENTER:
			_on_boton_pressed()

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

	var arr = []
	for nombre in puntuaciones.keys():
		arr.append({"nombre": nombre, "score": puntuaciones[nombre]})
	
	ordenar_ranking(arr)

	# Panel contenedor
	var ranking_panel = get_node_or_null("RankingPanel")
	if ranking_panel == null:
		ranking_panel = Panel.new()
		ranking_panel.name = "RankingPanel"
		ranking_panel.rect_position = Vector2(-470, -220)
		ranking_panel.rect_min_size = Vector2(LABEL_WIDTH + 10, MAX_RANKING_HEIGHT)
		ranking_panel.add_stylebox_override("panel", input_background)
		add_child(ranking_panel)
	else:
		for child in ranking_panel.get_children():
			child.queue_free()

	# Título
	var title_label = Label.new()
	title_label.text = "Ranking"
	title_label.align = Label.ALIGN_CENTER
	title_label.add_color_override("font_color", Color(1, 1, 1))
	title_label.rect_min_size = Vector2(LABEL_WIDTH, 30)
	title_label.theme = my_theme
	ranking_panel.add_child(title_label)

	# ScrollContainer
	var scroll = ScrollContainer.new()
	scroll.rect_min_size = Vector2(LABEL_WIDTH + 10, MAX_RANKING_HEIGHT - 40)
	scroll.margin_top = 40
	scroll.scroll_vertical_enabled = false  # Desactivamos scroll: corte manual
	ranking_panel.add_child(scroll)

	# VBox para etiquetas
	var container = VBoxContainer.new()
	container.name = "RankingContainer"
	container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	scroll.add_child(container)

	# Mostrar hasta que se alcance la altura máxima
	var used_height := 0
	for entry in arr:
		var label = Label.new()
		label.text = "%s : %d" % [entry["nombre"], entry["score"]]
		label.add_color_override("font_color", Color(1, 1, 1))
		label.autowrap = true
		label.rect_min_size = Vector2(LABEL_WIDTH, 0)
		label.theme = my_theme
		container.add_child(label)
		
		# Estimar altura (antes del render)
		label.force_update_transform()
		var est_height = label.get_combined_minimum_size().y + LABEL_MARGIN
		used_height += est_height

		# Si se pasa, eliminar y salir
		if used_height > MAX_RANKING_HEIGHT - 40:
			container.remove_child(label)
			label.queue_free()
			break
func ordenar_ranking(arr):
	for i in range(arr.size()):
		for j in range(i + 1, arr.size()):
			if arr[j]["score"] > arr[i]["score"]:
				var temp = arr[i]
				arr[i] = arr[j]
				arr[j] = temp

func _sort_scores_desc(a, b):
	return b.score - a.score
