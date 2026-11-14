extends CharacterBody2D

# Set these BEFORE add_child()
var direction := Vector2.RIGHT
var speed := 700.0
var bounces := 2
var from_player := true
var shooter: Node = null

var sprite: Sprite2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2 | 4   # walls, player, enemies
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if from_player:
		sprite = _make_sprite("laserBlue01.png", Color(0.4, 0.8, 1.0))
	else:
		sprite = _make_sprite("laserRed01.png", Color(1.0, 0.3, 0.3))
	add_child(sprite)
	sprite.rotation = direction.angle() + PI / 2.0   # laser art points up
	Art.add_circle(self, 6.0)
	if shooter:
		add_collision_exception_with(shooter)

func _make_sprite(file: String, color: Color) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Art.tex(file, "laser", color, 10, 44)
	return s

func _physics_process(delta: float) -> void:
	var c := move_and_collide(direction * speed * delta)
	if not c:
		return
	var col = c.get_collider()
	if col.is_in_group("enemy"):
		if from_player:
			col.hit(direction)
		queue_free()
	elif col.is_in_group("player"):
		if not from_player:
			col.take_damage(direction, 500.0)
		queue_free()
	elif bounces > 0:
		direction = direction.bounce(c.get_normal())
		sprite.rotation = direction.angle() + PI / 2.0
		bounces -= 1
	else:
		queue_free()
