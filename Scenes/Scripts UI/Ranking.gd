extends Node

var MAX_RANKING_HEIGHT = 500  
var LABEL_WIDTH = 512
var LABEL_MARGIN = 6
var my_theme = preload("res://VAmosadejarloFino.tres")
var input_background

func _ready():
	input_background = StyleBoxFlat.new()
	input_background.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	input_background.border_color = Color(1, 1, 1, 0.2)
	input_background.corner_radius_top_left = 12
	input_background.corner_radius_top_right = 12
	input_background.corner_radius_bottom_left = 12
	input_background.corner_radius_bottom_right = 12

	input_background.content_margin_left = 20
	input_background.content_margin_top = 20
	input_background.content_margin_right = 20
	input_background.content_margin_bottom = 20

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

	var arr = []
	for nombre in puntuaciones.keys():
		arr.append({"nombre": nombre, "score": puntuaciones[nombre]})
	
	ordenar_ranking(arr)

	var ranking_panel = get_node_or_null("RankingPanel")
	if ranking_panel == null:
		ranking_panel = Panel.new()
		ranking_panel.name = "RankingPanel"
		ranking_panel.rect_min_size = Vector2(LABEL_WIDTH + 60, MAX_RANKING_HEIGHT)
		ranking_panel.add_stylebox_override("panel", input_background)
		ranking_panel.theme = my_theme
		var size = ranking_panel.rect_min_size
		ranking_panel.rect_position = Vector2(500, 300) - size / 2
		add_child(ranking_panel)
	else:
		for child in ranking_panel.get_children():
			child.queue_free()

	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1
	vbox.anchor_bottom = 1
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	ranking_panel.add_child(vbox)

	var title_label = Label.new()
	title_label.text = "Ranking de Jugadores"
	title_label.align = Label.ALIGN_CENTER
	title_label.valign = Label.VALIGN_CENTER
	title_label.theme = my_theme
	title_label.rect_min_size = Vector2(LABEL_WIDTH, 40)
	title_label.add_color_override("font_color", Color(1, 1, 1))
	title_label.add_font_override("font", load("res://FuenteGrande.tres"))
	vbox.add_child(title_label)

	var scroll = ScrollContainer.new()
	scroll.rect_min_size = Vector2(LABEL_WIDTH + 10, MAX_RANKING_HEIGHT - 60)
	scroll.scroll_vertical_enabled = true
	scroll.theme = my_theme
	vbox.add_child(scroll)

	var container = VBoxContainer.new()
	container.name = "RankingContainer"
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.theme = my_theme
	scroll.add_child(container)

	var used_height = 0
	for i in range(arr.size()):
		var entry = arr[i]
		var label = Label.new()
		label.text = "%d.  %s   -   %d pts" % [i + 1, entry["nombre"], entry["score"]]
		label.add_color_override("font_color", Color(0.95, 0.95, 0.95))
		label.add_font_override("font", load("res://FuentePeque.tres"))
		label.rect_min_size = Vector2(LABEL_WIDTH, 28)
		container.add_child(label)

		if i < arr.size() - 1:
			var spacer = Control.new()
			spacer.rect_min_size = Vector2(0, LABEL_MARGIN)
			container.add_child(spacer)

		label.force_update_transform()
		var est_height = label.get_combined_minimum_size().y + LABEL_MARGIN
		used_height += est_height

		if used_height > MAX_RANKING_HEIGHT - 60:
			container.remove_child(label)
			label.queue_free()
			break

func ordenar_ranking(arr):
	arr.sort_custom(self, "_sort_scores_desc")

func _sort_scores_desc(a, b):
	return b["score"] - a["score"]
