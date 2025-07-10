extends Button

var escena_principal = "res://Scenes/Menu_principal.tscn"
var json_path = "res://usuarios.json"  # Cambia esta ruta si es necesario

func _on_Volver_pressed():
	var error_label = get_tree().get_current_scene().get_node_or_null("Objetos").get_node_or_null("Label")
	if error_label:
		error_label.text = ""  # Limpiar mensaje al iniciar

	var file = File.new()
	if file.file_exists(json_path):
		var err = file.open(json_path, File.READ)
		if err != OK:
			print("Error al abrir el archivo JSON")
			if error_label:
				error_label.text = "Error al leer datos"
			return

		var json_text = file.get_as_text()
		file.close()

		var json_result = JSON.parse(json_text)
		if json_result.error != OK:
			print("Error al parsear JSON: ", json_result.error_string)
			if error_label:
				error_label.text = "Error en formato de datos"
			return

		var usuarios = json_result.result

		var usuario = Global.textousuario.strip_edges()
		var contrasena = Global.textocontrasena.strip_edges()

		if usuario == "":
			if error_label:
				error_label.text = "Usuario no puede estar vacío"
			return

		if contrasena == "":
			if error_label:
				error_label.text = "contrasena no puede estar vacía"
			return

		if usuarios.has(usuario):
			if usuarios[usuario] == contrasena:
				Global.Usuario = usuario
				print("Acceso concedido a ", usuario)
				self.get_tree().change_scene(escena_principal)
			else:
				if error_label:
					error_label.text = "contrasena inválida"
		else:
			if error_label:
				error_label.text = "Usuario inválido"
	else:
		print("Archivo JSON no encontrado en: ", json_path)
		if error_label:
			error_label.text = "Datos de usuarios no encontrados"
