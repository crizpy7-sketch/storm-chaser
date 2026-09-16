extends SceneTree
## Feel telemetry. Unlike tools/verify_*.gd this asserts nothing; it prints the
## numbers that decide whether the truck reads as heavy -- steering response
## times, suspension compression and settle, impact momentum cost and body
## attitude in degrees. Run before and after a tuning change and diff the output.
const MediaPack = preload("res://scripts/media.gd")
const H := 1.0 / 120.0

func _initialize() -> void: call_deferred("run")

func _game():
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"
	var game = load("res://main.tscn").instantiate()
	game.settings_path = "user://feel-probe-isolated.cfg"
	root.add_child(game)
	await process_frame
	game.save_enabled = false
	game.demo = false
	game.start_chase()
	game.set_process(false)
	game.world.set_process(false)
	return game

## Holds a constant steering input and reports how long the lateral rate takes
## to build. A heavy truck should lag; an arcade kart snaps.
## player_x is pinned so this measures the pure input -> lateral-rate transfer
## and not the road-edge shedding that takes over once the truck runs wide.
func steering_response(game, seconds: float) -> Dictionary:
	game.steer = 1.0
	game.velocity_x = 0.0
	var samples: Array[float] = []
	var steps := int(seconds / H)
	for i in range(steps):
		game._update_driving(H)
		game.player_x = 0.0
		samples.append(game.velocity_x)
	var steady: float = samples[-1]
	var t63 := -1.0
	var t95 := -1.0
	for i in range(samples.size()):
		if t63 < 0.0 and absf(samples[i]) >= absf(steady) * 0.63: t63 = i * H
		if t95 < 0.0 and absf(samples[i]) >= absf(steady) * 0.95: t95 = i * H
	return {"steady": steady, "t63": t63, "t95": t95}

## Slams the input from full left to full right and reports how long the truck
## keeps travelling the OLD way. This is the number that reads as mass.
func reversal_latency(game) -> Dictionary:
	game.steer = -1.0
	game.velocity_x = 0.0
	for i in range(int(1.2 / H)):
		game._update_driving(H)
		game.player_x = 0.0
	var entry: float = game.velocity_x
	game.steer = 1.0
	var cross := -1.0
	var recover := -1.0
	for i in range(int(1.5 / H)):
		game._update_driving(H)
		game.player_x = 0.0
		if cross < 0.0 and game.velocity_x >= 0.0: cross = i * H
		if recover < 0.0 and game.velocity_x >= absf(entry) * 0.9: recover = i * H
	return {"entry": entry, "cross_zero": cross, "full_reverse": recover}

## Drops the truck onto its suspension and traces the spring.
func landing_trace(game, impact: float) -> Dictionary:
	game.stage = 5
	game.route.enter(5)
	game.world.reset_motion()
	game.velocity_x = 0.0; game.glide_velocity = 0.0; game.route.drift = 0.0
	game.world.truck.reset()
	var speed_before: float = game.speed
	game.route._land(impact)
	game.world.truck.step(H)
	var peak := 0.0
	var settle := -1.0
	var crossings := 0
	var previous: float = game.world.truck.suspension
	var trace: Array[float] = []
	for i in range(int(3.0 / H)):
		game.world.truck.step(H)
		var s: float = game.world.truck.suspension
		peak = minf(peak, s)
		if i % 12 == 0: trace.append(snappedf(s, 0.001))
		if signf(s) != signf(previous) and absf(s) > 0.004: crossings += 1
		previous = s
		if settle < 0.0 and i > 24 and absf(s) < 0.01: settle = i * H
	return {
		"severity": snappedf(game.route.landing_severity, 0.001),
		"peak_compression_m": snappedf(peak, 0.001),
		"bottomed_out": peak <= -0.2599,
		"settle_s": snappedf(settle, 0.001),
		"zero_crossings": crossings,
		"speed_lost": snappedf(speed_before - game.speed, 0.01),
		"grip_loss_window_s": snappedf(game.route.landing / maxf(0.001, 0.85), 0.01),
		"trace_100ms": trace.slice(0, 14),
	}

## Body attitude in DEGREES -- the units a player actually perceives.
func attitude(game) -> Dictionary:
	game.world.truck.reset()
	game.powertrain.acceleration = 33.0
	for i in range(int(1.0 / H)): game.world.truck.step(H)
	var squat: float = rad_to_deg(game.world.truck.pitch)
	game.powertrain.acceleration = -118.0
	for i in range(int(1.0 / H)): game.world.truck.step(H)
	var dive: float = rad_to_deg(game.world.truck.pitch)
	game.world.truck.reset()
	game.steer = 1.0; game.glide_velocity = 1.0
	for i in range(int(1.0 / H)): game.world.truck.step(H)
	var lean: float = rad_to_deg(game.world.truck.body.rotation.z)
	return {
		"squat_deg": snappedf(squat, 0.01),
		"brake_dive_deg": snappedf(dive, 0.01),
		"cornering_lean_deg": snappedf(lean, 0.01),
	}

## What a collision actually costs the player, through the real contact path.
func impact_cost(game, kind: int, theme: int, speed: float) -> Dictionary:
	game.start_chase()
	game.set_process(false); game.world.set_process(false)
	game.world.truck.reset()
	game.speed = speed
	game.player_x = 0.0
	game.velocity_x = 0.0
	game.glide_velocity = 0.0
	game.rear_slip_velocity = 0.0
	var speed_before: float = game.speed
	var lateral_before: float = game.glide_velocity
	var health_before: float = game.health
	var piece := {"kind": kind, "lane": 0.45, "theme": theme, "z": 1.0, "checked": true, "angle": 0.0, "spin": 0.0, "drift": 0.0}
	var contact := {
		"point": game.world.truck.position + Vector3(0.6, 1.0, -1.8),
		"normal": Vector3(1, 0, 0),
		"transform": Transform3D.IDENTITY,
		"t": 0.0,
	}
	game._apply_debris_contact(piece, contact)
	var recoil_peak := 0.0
	for i in range(int(1.0 / H)):
		game.world.truck.step(H)
		recoil_peak = maxf(recoil_peak, game.world.truck.recoil.length())
	return {
		"speed_lost": snappedf(speed_before - game.speed, 0.01),
		"speed_lost_pct": snappedf((speed_before - game.speed) / maxf(1.0, speed_before) * 100.0, 0.1),
		"lateral_shove": snappedf(game.glide_velocity - lateral_before, 0.001),
		"rear_kick": snappedf(game.rear_slip_velocity, 0.001),
		"health_lost": snappedf(health_before - game.health, 0.01),
		"recoil_peak_m": snappedf(recoil_peak, 0.001),
		"hit_stop_s": snappedf(game.crashes.hit_stop, 0.001),
		"shake": snappedf(game.shake, 0.01),
	}

func run() -> void:
	var game = await _game()
	print("=== STORM CHASER FEEL TELEMETRY ===")
	game.route.enter(0)
	game.speed = 146.0
	print("STEER_RESPONSE_CRUISE ", steering_response(game, 2.0))
	game.velocity_x = 0.0
	game.speed = 240.0; game.boosting = true
	print("STEER_RESPONSE_BOOST ", steering_response(game, 2.0))
	game.boosting = false
	game.velocity_x = 0.0; game.speed = 146.0
	print("STEER_REVERSAL ", reversal_latency(game))
	game.steer = 0.0; game.velocity_x = 0.0
	print("ATTITUDE_DEG ", attitude(game))
	print("IMPACT_CRATE_SLOW ", impact_cost(game, 0, 0, 90.0))
	print("IMPACT_CRATE_FAST ", impact_cost(game, 0, 0, 240.0))
	print("IMPACT_MASONRY_FAST ", impact_cost(game, 1, 2, 240.0))
	print("LANDING_SOFT ", landing_trace(game, 8.0))
	print("LANDING_HARD ", landing_trace(game, 18.0))
	print("LANDING_EXTREME ", landing_trace(game, 26.0))
	print("=== END TELEMETRY ===")
	quit()
