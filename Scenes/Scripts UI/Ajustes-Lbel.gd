extends Label

func _process(delta):
	if Global.minorpercentage == null:
		Global.minorpercentage = 0
	self.text = "El margen de porcentaje de error es de " + str(Global.minorpercentage) +"%"
	self.ALIGN_CENTER
