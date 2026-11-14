extends CharacterBody2D

const BULLET = preload("res://bullet.tscn")

var hp := 3
var dead := false
var knock := Vector2.ZERO
var speed := randf_range(60.0, 90.0)
var shoot_timer := randf_range(1.5, 3.0)
var slam_cd := 0.0
var sprite: Sprite2D
var player: Node = null

func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 4   # enemies layer
	collision_mask = 1    # walls/asteroids only
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var t := Art.tex("enemyBlack1.png", "ship_down", Color(0.7, 0.45, 1.0), 80, 70)
	sprite = Sprite2D.new()
	sprite.texture = t
	add_child(sprite)
	Art.add_circle(self, minf(t.get_size().x, t.get_size().y) * 0.4)
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or player.dead or dead:
		return
	var to_player: Vector2 = player.global_position - global_position
	sprite.rotation = to_player.angle() - PI / 2.0   # enemy art points down

	knock = knock.move_toward(Vector2.ZERO, 700.0 * delta)
	velocity = to_player.normalized() * speed + knock
	move_and_slide()

	slam_cd -= delta
	if slam_cd <= 0.0 and knock.length() > 200.0 and get_slide_collision_count() > 0:
		# slammed into a wall or asteroid -> bonus damage
		var c := get_last_slide_collision()
		knock = knock.bounce(c.get_normal()) * 0.6
		slam_cd = 0.2
		hp -= 2
		var main = get_tree().current_scene
		main.popup(global_position, "SLAM!")
		main.shake(8.0)
		main.burst(global_position, Color(1.0, 0.9, 0.4), 10)
		Art.play(main, "sfx_zap.ogg", -6.0)
		check_dead(true)
		if dead:
			return

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = randf_range(2.0, 3.5)
		shoot(to_player.normalized())

	if to_player.length() < 55.0:
		player.take_damage(to_player.normalized(), 400.0)
		knock = -to_player.normalized() * 300.0

func shoot(dir: Vector2) -> void:
	var b = BULLET.instantiate()
	b.direction = dir
	b.speed = 350.0
	b.bounces = 1
	b.shooter = self
	b.from_player = false
	b.global_position = global_position + dir * 45.0
	get_parent().add_child(b)
	Art.play(get_tree().current_scene, "sfx_laser2.ogg", -12.0)

func hit(dir: Vector2) -> void:
	hp -= 1
	knock = dir * 500.0
	sprite.modulate = Color(3, 3, 3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.15)
	var main = get_tree().current_scene
	main.shake(4.0)
	main.burst(global_position, Color(0.7, 0.45, 1.0), 8)
	check_dead(false)

func check_dead(slam: bool) -> void:
	if hp <= 0 and not dead:
		dead = true
		var main = get_tree().current_scene
		main.add_score(150 if slam else 100)
		main.burst(global_position, Color(1.0, 0.6, 0.2), 24)
		Art.play(main, "sfx_zap.ogg", -2.0)
		queue_free()
