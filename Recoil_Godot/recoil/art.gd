class_name Art
extends RefCounted
# Loads textures/sounds from res://art/ by filename.
# If the file is missing, a simple placeholder shape is used so the game still runs.

static func tex(file: String, kind: String, color: Color, w: int, h: int) -> Texture2D:
	var path := "res://art/" + file
	if ResourceLoader.exists(path):
		return load(path)
	return _placeholder(kind, color, w, h)

static func _placeholder(kind: String, color: Color, w: int, h: int) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var nx := (x + 0.5) / w * 2.0 - 1.0
			var ny := (y + 0.5) / h * 2.0 - 1.0
			var inside := false
			match kind:
				"ship_up":
					inside = absf(nx) <= (ny + 1.0) / 2.0
				"ship_down":
					inside = absf(nx) <= (1.0 - ny) / 2.0
				"circle":
					inside = nx * nx + ny * ny <= 1.0
				"laser":
					inside = absf(nx) <= 0.5
			if inside:
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)

static func add_circle(body: Node, radius: float) -> void:
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	cs.shape = c
	body.add_child(cs)

static func play(parent: Node, file: String, volume_db := 0.0) -> void:
	var path := "res://art/" + file
	if not ResourceLoader.exists(path):
		return
	var p := AudioStreamPlayer.new()
	p.stream = load(path)
	p.volume_db = volume_db
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
