extends HSlider

func _ready():
	call_deferred("_inicializar_slider")

func _inicializar_slider():
	self.value = Global.minorpercentage

func _on_HSlider_value_changed(value):
	Global.minorpercentage = value
