extends Node3D

enum Pose{FILMING, TRACKING, LOOK_BACK, DUCK}
const ART: = preload("res://assets/art/mateo-storm-camera.png")
const BODY_HEIGHT: = 2.4
const CELLS: = [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]
var game: Node2D
var body: MeshInstance3D
var fabric: ShaderMaterial
var pose: = Pose.FILMING
var previous_pose: = Pose.FILMING
var blend: = 1.0
var sway: = 0.0
var sway_velocity: = 0.0
var reaction_time: = 0.0
var reaction_pose: = Pose.FILMING
var last_hits: = 0
var last_near_misses: = 0
var last_lens_hits: = 0
var last_probes: = 0
var last_elapsed: = 0.0
var cinematic_time: = -1.0
var intro_spoken := false
var last_cow_sequence := -1
## What has been said this run, so a line the player has not heard yet wins a
## tie against one they have.
var said := {}

## Every line Mateo has recorded, with the moment it belongs to. A new line
## needs an entry here and its .wav next to the others -- mateo_takes() already
## finds the takes on its own. "info" is written for a reader deciding which
## line fits: it is what the advisor is shown, and it is never displayed.
const LINES := [
	{"id": "mateo_cow", "caption": "A flying cow?!", "cue": "cow", "rank": 3,
		"info": "Something absurd just flew past -- livestock in the air. The single most remarkable thing that can happen; say it while it is still on screen."},
	{"id": "mateo_dodge", "caption": "I got that!", "cue": "near_miss", "rank": 2,
		"info": "The driver just threaded past debris without being hit. Praise for a close call, best said while they are still on a run of them."},
	{"id": "mateo_recording", "caption": "Keep it steady. I'm recording!", "cue": "intro", "rank": 1,
		"info": "The opening of a chase, before anything has happened. Sets up that he is filming. Says nothing about how the driving is going, so it is a poor fit once the run is eventful."},
]

func _ready() -> void :
	name = "MateoStormCamera"
	position = Vector3(0.32, 0.55, 2.69)
	fabric = ShaderMaterial.new()
	fabric.shader = preload("res://shaders/mateo_camera.gdshader")
	fabric.set_shader_parameter("pose_atlas", ART)
	var surface: = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	for row in range(20):
		var a: = row / 20.0
		var b: = (row + 1) / 20.0
		for uv in [Vector2(0, a), Vector2(1, a), Vector2(0, b), Vector2(1, a), Vector2(1, b), Vector2(0, b)]:
			surface.set_uv(uv)
			surface.set_normal(Vector3.BACK)
			surface.add_vertex(Vector3((uv.x - 0.5) * BODY_HEIGHT, (1.0 - uv.y) * BODY_HEIGHT, 0))
	body = MeshInstance3D.new()
	body.name = "Animated filming character"
	body.mesh = surface.commit()
	body.material_override = fabric
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(body)
	reset_pose()

func reset_pose() -> void :
	cinematic_time = -1.0
	intro_spoken = false; last_cow_sequence = -1
	pose = Pose.FILMING
	previous_pose = pose
	blend = 1.0
	sway = 0.0
	sway_velocity = 0.0
	reaction_time = 0.0
	reaction_pose = Pose.FILMING
	last_hits = game.hits
	last_near_misses = game.near_misses
	last_lens_hits = game.lens_hits
	last_probes = game.probes
	last_elapsed = game.elapsed
	said.clear()
	_apply_pose()

func _process(dt: float) -> void :
	if game.elapsed < last_elapsed: reset_pose()
	last_elapsed = game.elapsed
	if game.mode != game.Mode.RUNNING: return
	step(minf(dt, 0.05))

func step(dt: float) -> void :
	reaction_time = maxf(0.0, reaction_time - dt)
	if game.hits > last_hits or game.lens_hits > last_lens_hits:
		reaction_pose = Pose.DUCK
		reaction_time = 0.95
	elif game.near_misses > last_near_misses or game.probes > last_probes:
		reaction_pose = Pose.LOOK_BACK
		reaction_time = 1.0
	var cues: Dictionary = {
		"near_miss": game.near_misses > last_near_misses,
		"intro": not intro_spoken and game.elapsed > 3.0,
		"cow": _cow_overhead(),
	}
	_speak(cues)
	last_hits = game.hits
	last_near_misses = game.near_misses
	last_lens_hits = game.lens_hits
	last_probes = game.probes
	var desired: = Pose.FILMING

	for piece in game.sky_debris:
		var u: float = piece.age / piece.duration
		if piece.kind == 0 and u >= 0.48 and u <= 0.94:
			desired = Pose.DUCK
			break
		if u >= 0.12 and u < 0.95: desired = Pose.TRACKING
	if reaction_time > 0.0 and (desired != Pose.DUCK or reaction_pose == Pose.DUCK):
		desired = reaction_pose

	if not game.route.grounded or game.route.landing > 0.4: desired = Pose.DUCK
	if desired == Pose.FILMING and fposmod(game.elapsed, 10.5) > 8.9:
		desired = Pose.LOOK_BACK
	if desired != pose:
		previous_pose = pose
		pose = desired
		blend = 0.0
	blend = minf(1.0, blend + dt / 0.13)
	var target: float = - game.rear_slip * 0.21 - game.velocity_x * 0.035
	if game.calm_fx: target *= 0.35
	sway_velocity += (target - sway) * 32.0 * dt
	sway_velocity *= exp( - dt * 7.5)
	sway = clampf(sway + sway_velocity * dt, -0.28, 0.28)
	_apply_pose()

## True while a cow is overhead and this sequence has not been remarked on.
func _cow_overhead() -> bool:
	if last_cow_sequence == game.sky_sequence: return false
	for piece in game.sky_debris:
		if piece.kind == 1 and piece.age / piece.duration > 0.25: return true
	return false

## Says one line, if any line fits.
##
## Mateo has a single voice and a thirteen-second cooldown, so when two things
## happen at once one of them is lost. This used to be settled by the order the
## checks happened to be written in: a near miss 0.2 s before a flying cow meant
## the cow went unremarked, which is exactly backwards for a ten-year-old.
##
## Now every eligible line is gathered first and one is chosen. The game's own
## choice -- the highest-ranked cue, breaking ties toward a line not yet heard
## this run -- is what is used, and is what runs with no storm link, offline, or
## in any check. An advisor may re-rank those same candidates and nothing else.
func _speak(cues: Dictionary) -> void:
	if game.mode != game.Mode.RUNNING or game.mateo_cooldown > 0.0: return
	var candidates: Array = LINES.filter(func(line): return bool(cues.get(str(line.cue), false)))
	if candidates.is_empty(): return
	var best: int = 0
	for i in range(1, candidates.size()):
		var a: Dictionary = candidates[i]
		var b: Dictionary = candidates[best]
		var a_fresh: bool = not said.has(str(a.id))
		var b_fresh: bool = not said.has(str(b.id))
		if a_fresh != b_fresh:
			if a_fresh: best = i
		elif int(a.rank) > int(b.rank): best = i
	# HARMLESS: the worst outcome here is a slightly less apt line, once every
	# thirteen seconds. When two lines are both good the probabilities spread
	# and confidence falls, and that is the moment the question was worth asking.
	var picked: int = game.advisor.choose("mateo_line", "Mateo is the co-driver filming this storm chase and can say one thing right now. Which of his recorded lines best fits this moment for the child driving?", candidates, _moment(cues), best, game.Advisor.HARMLESS)
	if picked < 0 or picked >= candidates.size(): picked = best
	var line: Dictionary = candidates[picked]
	if not game.say_mateo(str(line.id), str(line.caption)): return
	said[str(line.id)] = true
	if str(line.cue) == "intro": intro_spoken = true
	if str(line.cue) == "cow": last_cow_sequence = game.sky_sequence

## The moment, as the advisor sees it. Numbers the game already keeps, and no
## identity of any kind: nothing here says who is playing.
func _moment(cues: Dictionary) -> Dictionary:
	return {
		"hull": int(game.health),
		"speed_mph": int(game.speed),
		"level": game.stage + 1,
		"hits_taken": game.hits,
		"near_misses": game.near_misses,
		"dodge_combo": game.combo,
		"probes_sent": game.probes,
		"seconds_in": int(game.elapsed),
		"airborne": not game.route.grounded,
		"just_dodged": bool(cues.get("near_miss", false)),
		"flying_cow_overhead": bool(cues.get("cow", false)),
		"chase_just_started": bool(cues.get("intro", false)),
	}

func _apply_pose() -> void :
	if not is_instance_valid(fabric): return
	var t: float = game.elapsed if cinematic_time < 0 else cinematic_time
	var motion: = 0.35 if game.calm_fx else 1.0
	var breathing: = sin(t * 3.6) * 0.018
	var vibration: float = sin(t * 19.0) * 0.014 * game.speed / 240.0 * motion
	fabric.set_shader_parameter("pose_from", CELLS[previous_pose])
	fabric.set_shader_parameter("pose_to", CELLS[pose])
	fabric.set_shader_parameter("pose_blend", smoothstep(0.0, 1.0, blend))
	fabric.set_shader_parameter("lean", sway + sin(t * 2.7) * 0.026 * motion)
	fabric.set_shader_parameter("breath", breathing + vibration)
	fabric.set_shader_parameter("camera_sweep", sin(t * 1.7) * 0.025 * motion)
	fabric.set_shader_parameter("film_clock", t)
	fabric.set_shader_parameter("storm_flash", 0.0 if game.calm_fx else game.lightning)

func cinematic_pose(t: float, duck: bool) -> void :
	cinematic_time = t
	var desired: = Pose.DUCK if duck else Pose.TRACKING
	if desired != pose:
		previous_pose = pose;pose = desired;blend = 0.0
	blend = minf(1.0, blend + 0.1)
	sway = sin(t * 2.1) * 0.06
	_apply_pose()

## Keeps the flat filming artwork from turning edge-on in side, orbit and finale
## views: it yaws toward the camera around its own seat, within a limit.
func face_camera(camera: Camera3D) -> void:
	var seat := get_parent() as Node3D
	if seat == null or camera == null or not is_inside_tree(): return
	var offset: Vector3 = seat.global_transform.affine_inverse() * camera.global_position - position
	rotation.y = clampf(atan2(offset.x, offset.z), -1.25, 1.25)

## Calm filming pose for the garage preview, without a pose crossfade.
func garage_pose(t: float) -> void:
	cinematic_time = t
	pose = Pose.FILMING
	previous_pose = Pose.FILMING
	blend = 1.0
	sway = sin(t * 1.3) * 0.03
	_apply_pose()

func pose_label() -> String:
	return ["FILMING", "TRACKING", "LOOK BACK", "BRACING"][pose]
