extends StaticBody2D

func _ready() -> void:
	collision_layer = 1   # walls layer
	collision_mask = 0
	var t := Art.tex("meteorBrown_big1.png", "circle", Color(0.55, 0.4, 0.3), 90, 90)
	var s := Sprite2D.new()
	s.texture = t
	s.rotation = randf() * TAU
	add_child(s)
	Art.add_circle(self, minf(t.get_size().x, t.get_size().y) * 0.45)
