extends Node2D

const ENEMY = preload("res://enemy.tscn")
const ASTEROID = preload("res://asteroid.tscn")
const PLAYER = preload("res://player.tscn")
const MAX_ENEMIES := 12

static var best := 0   # survives scene reloads

var score := 0
var wait := 2.0
var game_over := false
var game_over_time := 0
var shake_amt := 0.0

var player
var camera: Camera2D
var spawn_timer: Timer
var score_label: Label
var go_label: Label
@onready var size := get_viewport_rect().size

func _ready() -> void:
	randomize()
	_build_background()

	camera = Camera2D.new()
	camera.position = size / 2.0
	add_child(camera)

	# invisible walls around the screen
	_make_wall(Vector2(size.x / 2.0, -25), Vector2(size.x + 100, 50))
	_make_wall(Vector2(size.x / 2.0, size.y + 25), Vector2(size.x + 100, 50))
	_make_wall(Vector2(-25, size.y / 2.0), Vector2(50, size.y + 100))
	_make_wall(Vector2(size.x + 25, size.y / 2.0), Vector2(50, size.y + 100))

	# asteroids to bounce enemies into
	for i in 4:
		var a = ASTEROID.instantiate()
		var p := _random_point()
		while p.distance_to(size / 2.0) < 200.0:
			p = _random_point()
		a.position = p
		add_child(a)

	player = PLAYER.instantiate()
	player.name = "Player"
	player.position = size / 2.0
	add_child(player)

	_build_hud()

	spawn_timer = Timer.new()
	spawn_timer.wait_time = wait
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_spawn_enemy)
	add_child(spawn_timer)

func _process(delta: float) -> void:
	score_label.text = "SCORE %d     HP %d" % [score, maxi(player.hp, 0)]
	if shake_amt > 0.1:
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amt
		shake_amt = lerpf(shake_amt, 0.0, 10.0 * delta)
	else:
		camera.offset = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if not game_over or Time.get_ticks_msec() - game_over_time < 600:
		return
	var restart := false
	if event is InputEventMouseButton and event.pressed:
		restart = true
	if event is InputEventKey and event.pressed and (event.keycode == KEY_R or event.keycode == KEY_SPACE):
		restart = true
	if restart:
		get_tree().reload_current_scene()

# ---------- setup helpers ----------
func _build_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.07, 0.17)
	bg.size = size
	layer.add_child(bg)
	if ResourceLoader.exists("res://art/darkPurple.png"):
		var tr := TextureRect.new()
		tr.texture = load("res://art/darkPurple.png")
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_TILE
		tr.size = size
		layer.add_child(tr)

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	score_label = Label.new()
	score_label.position = Vector2(20, 14)
	_style(score_label, 28)
	hud.add_child(score_label)

	go_label = Label.new()
	go_label.size = Vector2(size.x, 320)
	go_label.position = Vector2(0, size.y / 2.0 - 140.0)
	go_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_label.visible = false
	_style(go_label, 40)
	hud.add_child(go_label)

func _style(l: Label, font_size: int) -> void:
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	if ResourceLoader.exists("res://art/kenvector_future.ttf"):
		l.add_theme_font_override("font", load("res://art/kenvector_future.ttf"))

func _random_point() -> Vector2:
	return Vector2(randf_range(80, size.x - 80), randf_range(80, size.y - 80))

func _make_wall(pos: Vector2, wall_size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = wall_size
	shape.shape = rect
	body.add_child(shape)
	body.position = pos
	add_child(body)

# ---------- gameplay ----------
func _spawn_enemy() -> void:
	if game_over:
		return
	if get_tree().get_nodes_in_group("enemy").size() >= MAX_ENEMIES:
		return
	var e = ENEMY.instantiate()
	var p := _random_point()
	while p.distance_to(player.global_position) < 300.0:
		p = _random_point()
	e.position = p
	add_child(e)
	wait = maxf(0.6, wait * 0.97)   # gets harder over time
	spawn_timer.wait_time = wait

func add_score(n: int) -> void:
	score += n

func end_game() -> void:
	if game_over:
		return
	game_over = true
	game_over_time = Time.get_ticks_msec()
	best = maxi(best, score)
	spawn_timer.stop()
	go_label.text = "GAME OVER\nScore: %d\nBest: %d\n\nClick or press R to restart" % [score, best]
	go_label.visible = true
	burst(player.global_position, Color(1.0, 0.5, 0.3), 40)
	shake(25.0)
	Art.play(self, "sfx_lose.ogg")

# ---------- juice ----------
func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount)

func burst(pos: Vector2, color: Color, count := 18) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.amount = count
	p.lifetime = 0.6
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 260.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = color
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)

func popup(pos: Vector2, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos - Vector2(40, 30)
	_style(l, 24)
	l.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	add_child(l)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 50.0, 0.6)
	t.tween_property(l, "modulate:a", 0.0, 0.6)
	t.chain().tween_callback(l.queue_free)
