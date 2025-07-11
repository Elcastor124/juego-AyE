extends Node
var textousuario
var textocontrasena
var Usuario
var modo
var minorpercentage = 0
var tipohoja= 0
var color= 0
export(Array, Color) var infection_colors_marron = [
	Color(0.45, 0.3, 0.1),    # Marrón medio cálido
	Color(0.4, 0.1, 0.1),     # Marrón oscuro rojizo
	Color(0.2, 0.2, 0.2),     # Marrón muy oscuro casi gris
	Color(0.55, 0.35, 0.15),  # Marrón claro dorado
	Color(0.6, 0.4, 0.2),     # Marrón anaranjado claro
	Color(0.3, 0.2, 0.1),     # Marrón oscuro terroso
	Color(0.5, 0.25, 0.1),    # Marrón rojizo oscuro
	Color(0.35, 0.25, 0.15),  # Marrón neutro
	Color(0.25, 0.15, 0.05),  # Marrón muy oscuro con toques amarillos
	Color(0.7, 0.5, 0.3),     # Marrón claro cálido
	Color(0.4, 0.3, 0.2),     # Marrón medio con gris
	Color(0.5, 0.4, 0.3),     # Marrón suave con matiz grisáceo
	Color(0.65, 0.45, 0.15),  # Marrón amarillento dorado
	Color(0.8, 0.35, 0.1),    # Marrón rojo anaranjado intenso
	Color(0.5, 0.15, 0.1),    # Marrón rojizo oscuro profundo
	Color(0.55, 0.25, 0.05),  # Marrón con fuerte matiz amarillo
	Color(0.3, 0.15, 0.1),    # Marrón oscuro con toques rojos
	Color(0.6, 0.3, 0.2)      # Marrón cálido con matiz rojo
]

export(Array, Color) var infection_colors_amarillo = [
	Color(0.7, 0.6, 0.1),    # Amarillo mostaza oscuro
	Color(0.8, 0.7, 0.2),    # Amarillo dorado
	Color(0.9, 0.85, 0.4),   # Amarillo claro suave
	Color(1.0, 0.9, 0.2),    # Amarillo brillante
	Color(0.95, 0.9, 0.5),   # Amarillo pálido con toque cálido
	Color(0.85, 0.75, 0.3),  # Amarillo medio anaranjado
	Color(0.6, 0.55, 0.1),   # Amarillo mostaza oscuro profundo
	Color(0.9, 0.8, 0.25),   # Amarillo limón suave
	Color(1.0, 1.0, 0.4),    # Amarillo muy claro pastel
	Color(0.75, 0.7, 0.15),  # Amarillo terroso
	Color(0.8, 0.75, 0.4),   # Amarillo dorado claro
	Color(0.95, 0.85, 1.0),  # Amarillo cálido medio
	Color(1.0, 0.8, 0.0),    # Amarillo intenso fuerte
	Color(0.85, 0.7, 0.05),  # Amarillo ocre oscuro
	Color(1.0, 1.0, 0.0),    # Amarillo puro muy brillante
	Color(0.9, 0.75, 0.2)    # Amarillo ámbar medio
]

export(Array, Color) var infection_colors_blanco = [
	Color(1, 1, 1),           # Blanco puro
	Color(0.95, 0.95, 0.95), # Blanco muy suave
	Color(0.85, 0.85, 0.85), # Gris claro
	Color(0.7, 0.7, 0.7),    # Gris medio claro
	Color(0.6, 0.6, 0.65),   # Gris azulado claro
	Color(0.9, 0.9, 0.85),   # Blanco crema
	Color(0.8, 0.75, 0.7),   # Blanco con tintes beige
	Color(0.95, 0.9, 0.95),  # Blanco lavanda
	Color(0.7, 0.75, 0.8),   # Gris azulado medio
	Color(0.85, 0.85, 0.9),  # Gris claro con matiz azul
	Color(0.65, 0.7, 0.75),  # Gris azulado oscuro claro
	Color(0.55, 0.55, 0.6)   # Gris oscuro suave para contraste
]
