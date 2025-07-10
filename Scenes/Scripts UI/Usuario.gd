extends TextEdit

func _on_Usuario_text_changed():
	Global.textousuario = self.text

