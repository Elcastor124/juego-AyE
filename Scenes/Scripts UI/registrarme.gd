extends Button

var json_path = "res://usuarios.json"  # Cambia la ruta si es necesario

var err


func _on_registrarme_pressed():
	var file = File.new()
	var usuarios = {}

	if file.file_exists(json_path):
		var err = file.open(json_path, File.READ)
		if err != OK:
			print("Error al abrir archivo JSON para lectura")
			return

		var json_text = file.get_as_text()
		file.close()

		# Si el archivo está vacío, inicializa usuarios vacío sin parsear
		if json_text.strip_edges() == "":
			usuarios = {}
		else:
			var json_result = JSON.parse(json_text)
			if json_result.error == OK:
				usuarios = json_result.result
			else:
				print("Error al parsear JSON: ", json_result.error_string)
				return
	else:
		# Si no existe el archivo, inicializamos usuarios vacío
		usuarios = {}

	var nuevo_usuario = Global.textousuario.strip_edges()
	var nueva_contrasena = Global.textocontrasena.strip_edges()

	if nuevo_usuario == "":
		print("El usuario no puede estar vacío")
		return
	if nueva_contrasena == "":
		print("La contraseña no puede estar vacía")
		return
	if usuarios.has(nuevo_usuario):
		print("Usuario ya existe")
		return

	usuarios[nuevo_usuario] = nueva_contrasena

	var json_string = JSON.print(usuarios, "\t")

	err = file.open(json_path, File.WRITE)
	if err != OK:
		print("Error al abrir archivo JSON para escritura")
		return

	file.store_string(json_string)
	file.close()

	print("Usuario registrado correctamente:", nuevo_usuario)
