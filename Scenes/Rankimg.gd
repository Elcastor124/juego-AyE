extends Sprite



func _on_Button2_pressed():
	var tween = Tween.new()
	add_child(tween)  # ¡Muy importante! Hay que agregar el Tween al árbol
	tween.interpolate_property(
		self, "rotation_degrees", 0.0, 720.0, 0.5,  # duración de 1 segundo
		Tween.TRANS_EXPO, Tween.EASE_IN_OUT
	)
	tween.start()
