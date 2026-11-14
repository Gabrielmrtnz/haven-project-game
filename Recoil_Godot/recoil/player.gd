extends CharacterBody2D

const BULLET = preload("res://bullet.tscn")

var recoil := 450.0     # how hard each shot pushes you back
var thrust := 600.0
var friction := 1.0     # low = floaty space feel
var cooldown := 0.0
var hp := 5
var invuln := 0.0
var dead := false
var sprite: Sprite2D

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2   # player layer
	collision_mask = 1    # collides with walls/asteroids
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var t := Art.tex("playerShip1_red.png", "ship_up", Color(1.0, 0.35, 0.3), 80, 70)
	sprite = Sprite2D.new()
	sprite.texture = t
	add_child(sprite)
	Art.add_circle(self, minf(t.get_size().x, t.get_size().y) * 0.4)

func _physics_process(delta: float) -> void:
	if dead:
		return
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A): input.x -= 1.0
	if Input.is_key_pressed(KEY_D): input.x += 1.0
	if Input.is_key_pressed(KEY_W): input.y -= 1.0
	if Input.is_key_pressed(KEY_S): input.y += 1.0
	input = input.limit_length(1.0)

	velocity += input * thrust * delta
	velocity *= 1.0 - friction * delta
	velocity = velocity.limit_length(1000.0)

	var aim := (get_global_mouse_position() - global_position).normalized()
	sprite.rotation = aim.angle() + PI / 2.0   # ship art points up

	cooldown -= delta
	invuln -= delta
	sprite.modulate.a = 0.4 if invuln > 0.0 else 1.0

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and cooldown <= 0.0:
		shoot(aim)

	var c := move_and_collide(velocity * delta)
	if c:
		velocity = velocity.bounce(c.get_normal()) * 0.7

func shoot(aim: Vector2) -> void:
	cooldown = 0.25
	var b = BULLET.instantiate()
	b.direction = aim
	b.shooter = self
	b.from_player = true
	b.global_position = global_position + aim * 45.0
	get_parent().add_child(b)
	velocity -= aim * recoil   # THE KNOCKBACK
	# squash & stretch
	sprite.scale = Vector2(0.85, 1.2)
	create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.12)
	get_tree().current_scene.shake(3.0)
	Art.play(get_tree().current_scene, "sfx_laser1.ogg", -8.0)

func take_damage(dir: Vector2, force := 400.0) -> void:
	if invuln > 0.0 or dead:
		return
	invuln = 0.8
	hp -= 1
	velocity = dir * force
	var main = get_tree().current_scene
	main.shake(12.0)
	main.burst(global_position, Color(1.0, 0.8, 0.3), 12)
	Art.play(main, "sfx_shieldDown.ogg", -4.0)
	if hp <= 0:
		dead = true
		visible = false
		main.end_game()
