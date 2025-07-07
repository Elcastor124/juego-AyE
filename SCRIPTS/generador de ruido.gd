extends Node2D

export(String) var image_path = "res://imagen_original.png"
export(float) var noise_ratio = 0.1  # 10% de ruido

func _ready():
	var img = Image.new()
	var err = img.load(image_path)
	if err != OK:
		print("Error al cargar la imagen.")
		return

	var width = img.get_width()
	var height = img.get_height()
	var total_pixels = width * height
	var noisy_pixels = 0

	img.lock()

	for y in range(height):
		for x in range(width):
			if randf() < noise_ratio:
				var color = Color(1, 1, 1) if randf() < 0.5 else Color(0, 0, 0)
				img.set_pixel(x, y, color)
				noisy_pixels += 1

	img.unlock()

	var tex = ImageTexture.new()
	tex.create_from_image(img)

	var sprite = Sprite.new()
	sprite.texture = tex
	add_child(sprite)

	var porcentaje = (noisy_pixels * 100.0) / total_pixels
	print("Porcentaje de píxeles con ruido: %.2f%%" % porcentaje)
