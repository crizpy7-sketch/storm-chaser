extends Control

const LENGTH := 11.5
const FILM_PATH := "res://assets/cinematics/finale/final_transmission.ogv"
const FILM_LENGTH := 18.0
const DISPLAY := preload("res://assets/fonts/display.ttf")
const MONO := preload("res://assets/fonts/telemetry.ttf")
const Media := preload("res://scripts/media.gd")
var game
var active := false
var finished := false
var age := 0.0
var entry_truck := Vector3.ZERO
var entry_camera := Vector3.ZERO
var center := Vector3.ZERO
var transmitted := false
var lifted := false
var end_sound := false
var movies_enabled := true
var film_playing := false
var movie_used := false
var player: VideoStreamPlayer
var film_layer: Control
var paused_audio: Dictionary = {}
var playback_position := 0.0
var stalled_for := 0.0
var playback_failed := false
var skip_button: Button

func _ready() -> void:
	z_index=115;size=Vector2(1280,720);mouse_filter=Control.MOUSE_FILTER_IGNORE
	var pause_button:=Button.new()
	pause_button.text="II";pause_button.position=Vector2(1200,8);pause_button.size=Vector2(44,32)
	pause_button.focus_mode=Control.FOCUS_NONE;pause_button.pressed.connect(game.pause_chase)
	add_child(pause_button)
	skip_button = Button.new()
	skip_button.text = "SKIP FILM  /  A"
	skip_button.position = Vector2(1080, 668)
	skip_button.size = Vector2(166, 36)
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.add_theme_font_override("font", DISPLAY)
	skip_button.add_theme_font_size_override("font_size", 14)
	skip_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	skip_button.pressed.connect(complete)
	add_child(skip_button)
	reset()

func reset() -> void:
	_stop_movie()
	active=false;finished=false;age=0;transmitted=false;lifted=false;end_sound=false
	movie_used=false;playback_failed=false;stalled_for=0;playback_position=0
	if is_instance_valid(game.world): game.world.environment.fog_density=0.0027
	hide()

func begin() -> void:
	if active or game.mode!=game.Mode.RUNNING:return
	active=true;finished=false;age=0;transmitted=false;lifted=false;end_sound=false
	entry_truck=game.world.truck.position
	entry_camera=game.world.camera.position
	center=game.route.tornado_point()
	game.mode=game.Mode.VORTEX
	game._clear_touch();game.dodges.cancel_pending()
	game.debris.clear();game.sky_debris.clear();game.puddles.clear();game.effects.clear()
	game.skid_trails.clear();game.lens_marks.clear();game.lens_projectiles.clear()
	game.world.water_fx.reset();game.world.spray.clear()
	game.shake=0;game.flash=0;game.lens_kick=0
	game.unlock_footage(game.FINALE_FOOTAGE)
	_start_movie()
	game.hud.rebuild()
	show()

func _start_movie() -> bool:
	if not movies_enabled: return false
	var stream := Media.video(FILM_PATH)
	if stream == null: return false
	film_layer = Control.new()
	film_layer.z_index = -1
	film_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(film_layer)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.size = size
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	film_layer.add_child(black)
	player = VideoStreamPlayer.new()
	player.stream = stream
	player.expand = true
	# Preserve the approved 910 x 512 edit, its color and its original soundtrack.
	var scale_factor := minf(size.x / 910.0, size.y / 512.0)
	player.size = Vector2(910, 512) * scale_factor
	player.position = (size - player.size) * 0.5
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	film_layer.add_child(player)
	player.finished.connect(complete)
	for child in game.get_children():
		if child is AudioStreamPlayer:
			paused_audio[child] = child.stream_paused
			child.stream_paused = true
	film_playing = true
	movie_used = true
	playback_position = 0.0
	stalled_for = 0.0
	player.play()
	return true

func _stop_movie() -> void:
	film_playing = false
	if is_instance_valid(player):
		if player.finished.is_connected(complete): player.finished.disconnect(complete)
		player.stop()
		player.stream = null
	player = null
	if is_instance_valid(film_layer):
		film_layer.hide()
		film_layer.queue_free()
	film_layer = null
	for audio in paused_audio:
		if is_instance_valid(audio): audio.stream_paused = paused_audio[audio]
	paused_audio.clear()

func set_paused(value: bool) -> void:
	if is_instance_valid(player): player.paused = value
	visible = active and not value

func _fallback_to_scene() -> void:
	_stop_movie()
	movie_used = false
	playback_failed = true
	age = 0.0
	lifted = false
	end_sound = false
	apply_view()

func _transmit() -> void:
	if transmitted: return
	transmitted = true
	game.score += 2000
	if not film_playing: game.play_sound("probe")

func step(dt: float) -> void:
	if not active or game.mode!=game.Mode.VORTEX:return
	age+=dt
	if age>0.8: _transmit()
	if film_playing:
		if not is_instance_valid(player):
			_fallback_to_scene()
			return
		var position_now := player.stream_position
		stalled_for = 0.0 if position_now > playback_position + 0.01 else stalled_for + dt
		playback_position = position_now
		if (age > 0.75 and not player.is_playing()) or stalled_for > 4.0 or age > FILM_LENGTH + 6.0:
			_fallback_to_scene()
		queue_redraw()
		return
	if age>3.0 and not lifted:
		lifted=true;game.play_sound("heavy_pass");game.play_sound("thunder");game.haptic(140,0.85)
	if age>8.7 and not end_sound:
		end_sound=true;game.play_sound("heavy_pass")
	game.world.truck.step(dt*0.55)
	apply_view();queue_redraw()
	if age>=LENGTH:complete()

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		game.pause_chase()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_SPACE, KEY_ENTER]: complete()
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X]: complete()
	get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	_stop_movie()

func update_storm() -> void:
	var visible_storm: bool=game.stage==7 and game.route.active
	game.world.tornado.show()
	if not visible_storm:
		game.world.tornado.rotation=Vector3.ZERO
		return
	var storm_center: Vector3=game.route.tornado_point()
	game.world.tornado.position=storm_center+Vector3(0,70,0)
	var facing: Vector3=game.world.camera.position-storm_center
	game.world.tornado.rotation.y=atan2(facing.x,facing.z)
	game.world.storm_material.set_shader_parameter("clock",(game.elapsed+age)*1.65)
	# Wind carries the same large debris around the physical funnel.
	for i in range(game.world.orbit_nodes.size()):
		var u:=i/42.0
		var a: float=(game.elapsed+age)*(1.2+u)+i*2.4
		var radius:=9.0+pow(u,1.5)*40.0
		game.world.orbit_nodes[i].position=storm_center+Vector3(sin(a)*radius,3+u*113,cos(a)*radius)
		game.world.orbit_nodes[i].rotation=Vector3(a,a*.7,a*.3)

func apply_view() -> void:
	if not active and not finished:return
	visible=active and game.mode==game.Mode.VORTEX
	if movie_used: return
	var w=game.world
	var pull:=smoothstep(1.0,9.8,age)
	var angle:=-PI*.5+smoothstep(2.0,10.3,age)*TAU*1.15
	var radial:=Vector3(sin(angle),0,cos(angle))
	var radius:=lerpf(game.route.ORBIT_RADIUS,4.0,pull)
	var height:=pow(smoothstep(2.4,10.5,age),1.35)*62.0
	var pos:=center+radial*radius+Vector3.UP*height
	w.truck.position=entry_truck.lerp(pos,smoothstep(0.0,2.0,age))
	var cam: Vector3=w.truck.position+radial*12.5+Vector3(0,3.8,0)
	w.camera.position=entry_camera.lerp(cam,smoothstep(0.0,2.5,age))
	var facing: Vector3=w.camera.position-w.truck.position
	w.truck.rotation=Vector3(sin(age*2.1)*0.035,atan2(facing.x,facing.z),0)
	w.camera.fov=lerpf(66.0,73.0,smoothstep(2,8,age))
	var focus: Vector3=w.truck.position+Vector3.UP*3.0-radial*8.0
	w.camera.look_at(focus,Vector3.UP)
	update_storm()
	if not game.calm_fx:
		w.camera.position+=Vector3(sin(age*43),cos(age*39),0)*smoothstep(2,8,age)*0.045
	w.sky.rotation.y=w.camera.rotation.y
	w.sky.position=w.camera.position+Vector3(0,474,-600).rotated(Vector3.UP,w.camera.rotation.y)
	if game.mode!=game.Mode.PAUSED: w.mateo.cinematic_pose(game.elapsed+age,age>2.9)
	w.truck.finish.set_shader_parameter("clock",game.elapsed+age)
	w.environment.fog_density=0.0027+smoothstep(7.2,10.8,age)*0.011
	for n in w.hazard_nodes:n.hide()
	for n in w.puddle_nodes:n.hide()
	for n in w.sky_nodes:n.hide()

func complete() -> void:
	if not active or game.mode != game.Mode.VORTEX:return
	_transmit()
	_stop_movie()
	active=false;finished=true;hide()
	game.world.environment.fog_density=0.0027
	var surveyed: bool=game.probes>=3
	game.finish(surveyed,"Eight levels conquered. Mateo's final transmission made it through the storm." if surveyed else "You reached the vortex. Complete the survey with three probes; transmit whenever the charge is ready.")
	if surveyed: game.result_title="INTO THE VORTEX"
	game.hud.rebuild()

func _draw() -> void:
	if not active:return
	if film_playing:
		# Keep the approved edit unobstructed after a short control hint.
		skip_button.modulate.a = 1.0 if age < 2.5 else 0.35
		if age < 2.5:
			draw_string(MONO,Vector2(34,30),"FINAL TRANSMISSION  /  SPACE OR A TO SKIP  /  START TO PAUSE",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("ecf0e9"))
		return
	skip_button.modulate.a = 1.0
	draw_rect(Rect2(0,0,1280,48),Color(.01,.025,.03,.94))
	draw_rect(Rect2(0,626,1280,94),Color(.01,.025,.03,.94))
	draw_string(MONO,Vector2(34,30),"MATEO / FINAL RECORDING",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f4bc63"))
	draw_circle(Vector2(1178,24),4,Color(1,.27,.14,.65+.25*sin(age*5)))
	var title: String="LAP COMPLETE" if age<2.4 else ("HOLD ON, MATEO" if age<6.6 else "INTO THE VORTEX")
	var caption: String="FINAL DATA TRANSMITTED  /  +2000" if age<3 else ("THE WIND IS LIFTING THE TRUCK" if age<7 else "SIGNAL FADING  /  CAMERA STILL ROLLING")
	draw_string(DISPLAY,Vector2(34,668),title,HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("ecf0e9"))
	draw_string(MONO,Vector2(35,698),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("84dfb9"))
	var fade:=smoothstep(9.7,LENGTH,age)
	if fade>0:draw_rect(Rect2(0,48,1280,578),Color(.035,.055,.058,fade))
