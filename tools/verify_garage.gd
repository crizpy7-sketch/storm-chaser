extends SceneTree
## Mateo Garage: catalog, stock integrity, cosmetic isolation from handling,
## setup trade-offs, saves, input flow, scoreboard and campaign completion.
var game
var checks := 0
var failures := 0
const MediaPack = preload("res://scripts/media.gd")
const Loadout = preload("res://scripts/loadout.gd")
const FACTOR_KEYS := ["damage", "dirt_grip", "water_grip", "landing", "boost_drain", "boost_recharge", "accel"]
# +1 when a larger factor helps the driver, -1 when it hurts.
const BENEFIT := {"damage": -1, "dirt_grip": 1, "water_grip": 1, "landing": 1, "boost_drain": -1, "boost_recharge": 1, "accel": 1}

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ", label)

func key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e

func pad(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	e.pressed = true
	return e

## This suite is about the catalog, the parts and the handling, not about the
## economy, so it drives a career that has earned everything. What has to be
## earned, and what happens when it has not been, is checked in verify_career.
## _load_settings() reads the career back from the file, so this is called again
## after any reload that later checks depend on.
func own_everything() -> void:
	game.career.owned = Loadout.priced_parts()
	game.career.badges = Loadout.BADGE_TITLES.keys()

func quiet(level: int) -> void:
	game.start_chase()
	game.set_process(false); game.world.set_process(false)
	game.stage = level; game.stage_seen = level; game.elapsed = level * game.STAGE_LENGTH + 0.5
	game.route.enter(level); game.speed = game.CRUISE_SPEEDS[level]; game.powertrain.reset(game.speed)
	game.world.reset_motion()

func calm_timers() -> void:
	game.spawn_timer = 99; game.pickup_timer = 99; game.puddle_timer = 99
	game.sky_timer = 99; game.lens_timer = 99; game.thunder_timer = 99; game.invulnerable = 99

## Deterministic handling fingerprint with scripted steering and boost.
func drive(level: int, seconds: float) -> Array:
	quiet(level)
	var t := 0.0
	var dt := 1.0 / 60.0
	while t < seconds:
		calm_timers()
		Input.action_release("left"); Input.action_release("right"); Input.action_release("boost")
		var axis := sin(t * 1.7) * 0.9
		if axis > 0.05: Input.action_press("right", axis)
		elif axis < -0.05: Input.action_press("left", -axis)
		if fmod(t, 4.0) > 2.5: Input.action_press("boost")
		game._simulate(dt)
		game.world.truck.step(dt)
		t += dt
	Input.action_release("left"); Input.action_release("right"); Input.action_release("boost")
	return [game.player_x, game.route.progress, game.speed, game.health, game.truck_yaw, game.route.launches, game.route.landings, game.boost, game.rear_slip]

func geometry(node: Node, result: Dictionary) -> void:
	if node.has_meta("garage_part") or node.name == "MateoStormCamera": return
	if node is MeshInstance3D:
		result[str(node.get_path())] = hash(node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	for child in node.get_children(): geometry(child, result)

func triangles(node: Node) -> int:
	if node.has_meta("garage_part") or node.name == "MateoStormCamera": return 0
	var count := 0
	if node is MeshInstance3D:
		var a: Array = node.mesh.surface_get_arrays(0)
		count += (a[Mesh.ARRAY_INDEX].size() if a[Mesh.ARRAY_INDEX] != null else a[Mesh.ARRAY_VERTEX].size()) / 3
	for child in node.get_children(): count += triangles(child)
	return count

func campaign(setup: String) -> bool:
	game.set_loadout({"accent": "storm_white", "wheels": "bronze_beadlock", "roof": "weather_mast", "armor": "bull_bar", "trim": "lift_kit", "setup": setup})
	game.demo = true; game.auto_dodges = false; game.finale.movies_enabled = false
	game.rng.seed = 72611
	game.start_chase()
	game.set_process(false); game.world.set_process(false); game.checkpoints.set_process(false)
	var stages: Array[int] = []
	for frame in range(48000):
		if game.mode == game.Mode.UPGRADE:
			stages.append(game.stage)
			game.choose_upgrade(0 if game.health < 80 else 1)
			game.checkpoints.complete()
		if game.mode == game.Mode.RUNNING:
			if game.charge >= 100: game.deploy_probe()
			game._simulate(1.0 / 60.0)
		if game.mode == game.Mode.VORTEX: game.finale.step(1.0 / 60.0)
		if game.mode in [game.Mode.RESULTS, game.Mode.CRASH]: break
	print("CAMPAIGN setup=", setup, " stages=", stages, " result=", game.result_title, " health=", game.health, " score=", int(game.score))
	game.demo = false
	return stages == [1, 2, 3, 4, 5, 6, 7] and game.mode == game.Mode.RESULTS and game.result_title == "INTO THE VORTEX"

func run() -> void:
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"
	var cfg := "user://garage-tests.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(cfg))
	game = load("res://main.tscn").instantiate()
	game.settings_path = cfg
	root.add_child(game)
	await process_frame
	game.save_enabled = false
	own_everything()
	var rig = game.world.truck
	var kit = rig.kit

	# --- Catalog ----------------------------------------------------------------
	check(Loadout.SLOTS.all(func(slot): return Loadout.options(slot)[0].id == "stock" and Loadout.options(slot).size() >= 4), "every garage slot offers the approved stock part first plus alternatives")
	check(game.loadout == Loadout.default_loadout(), "a fresh save starts with the complete stock loadout")
	var junk := Loadout.sanitize({"accent": "neon_pink", "wheels": 7, "roof": "doppler_dome", "future_slot": "x"})
	check(junk.accent == "stock" and junk.wheels == "stock" and junk.roof == "doppler_dome" and not junk.has("future_slot") and Loadout.sanitize("broken") == Loadout.default_loadout(), "unknown or damaged loadout values fall back to stock")
	var wrapped := Loadout.cycle(Loadout.default_loadout(), "wheels", -1)
	check(wrapped.wheels == Loadout.options("wheels").back().id and Loadout.cycle(wrapped, "wheels", 1).wheels == "stock", "option cycling wraps in both directions")
	check(FACTOR_KEYS.all(func(k): return Loadout.factor(Loadout.default_loadout(), k) == 1.0), "stock chase setup leaves every handling factor at exactly 1.0")
	var tradeoffs := true
	for entry in Loadout.options("setup"):
		if entry.id == "stock": continue
		var gains := 0
		var costs := 0
		for k in FACTOR_KEYS:
			var f := float(entry.get(k, 1.0))
			if f == 1.0: continue
			if (f > 1.0) == (BENEFIT[k] > 0): gains += 1
			else: costs += 1
		tradeoffs = tradeoffs and gains > 0 and costs > 0
	check(tradeoffs, "every alternative chase setup has both a benefit and a cost")

	# --- Stock integrity ----------------------------------------------------------
	check(not kit.has_visible_parts() and rig.body.get_node("RadarDish").visible and is_zero_approx(kit.ride_height), "stock loadout shows only the approved truck")
	var approved: Dictionary = {}
	geometry(rig.model, approved)
	var accent_before: Array = kit.accent_targets.map(func(m): return [m.albedo_color, m.metallic, m.roughness])
	var rim_before: Array = kit.rim_targets.map(func(m): return [m.albedo_color, m.metallic, m.roughness])
	var every_part_ok := true
	for slot in Loadout.COSMETIC_SLOTS:
		for entry in Loadout.options(slot):
			var next := Loadout.default_loadout()
			next[slot] = entry.id
			game.set_loadout(next)
			var visible_keys: Array = kit.parts.keys().filter(func(k): return kit.parts[k].visible)
			match slot:
				"roof", "armor", "trim":
					var expected: Array = [] if entry.id == "stock" else [slot + ":" + entry.id]
					every_part_ok = every_part_ok and visible_keys == expected
				_:
					every_part_ok = every_part_ok and visible_keys.is_empty()
			if slot == "roof": every_part_ok = every_part_ok and rig.body.get_node("RadarDish").visible == (entry.id != "doppler_dome")
			if slot == "trim": every_part_ok = every_part_ok and is_equal_approx(kit.ride_height, float(entry.lift)) and is_equal_approx(rig.body.position.y, rig.suspension + float(entry.lift))
			if slot == "accent" and entry.id != "stock": every_part_ok = every_part_ok and kit.accent_targets.all(func(m): return m.albedo_color == entry.color)
			if slot == "wheels" and entry.id != "stock": every_part_ok = every_part_ok and kit.rim_targets.all(func(m): return m.albedo_color == entry.rim)
	check(every_part_ok, "each cosmetic option shows exactly its own part, finish and ride height")
	game.set_loadout(Loadout.default_loadout())
	check(not kit.has_visible_parts() and kit.accent_targets.map(func(m): return [m.albedo_color, m.metallic, m.roughness]) == accent_before and kit.rim_targets.map(func(m): return [m.albedo_color, m.metallic, m.roughness]) == rim_before and rig.body.get_node("RadarDish").visible, "returning to stock restores every original finish and hides all added parts")
	var after: Dictionary = {}
	geometry(rig.model, after)
	check(after == approved and triangles(rig.model) == 67656, "garage parts never alter the approved 67,656-triangle truck mesh")

	# --- Cosmetics are visual only ------------------------------------------------
	var isolated := true
	for level in [3, 5, 6]:
		game.set_loadout(Loadout.default_loadout())
		var stock_trace := drive(level, 12.0)
		game.set_loadout({"accent": "desert_bronze", "wheels": "stealth_black", "roof": "doppler_dome", "armor": "winch", "trim": "lift_kit", "setup": "stock"})
		var custom_trace := drive(level, 12.0)
		isolated = isolated and stock_trace == custom_trace
	check(isolated, "cosmetic parts produce identical handling, jumps, hull and boost")
	game.set_loadout(Loadout.default_loadout())

	# --- Chase setup trade-offs ---------------------------------------------------
	quiet(1)
	game._spawn_item(0, 0.0); game.debris.back().z = 0.9
	var d: Dictionary = game.debris.back()
	var contact := {"normal": Vector3.BACK, "point": game.world.truck.position + Vector3(0, 1, -2.9), "transform": Transform3D.IDENTITY}
	game.invulnerable = 0; game.speed = 150; game._apply_debris_contact(d, contact)
	var stock_loss: float = 100.0 - game.health
	game.set_loadout(Loadout.cycle(Loadout.default_loadout(), "setup", 2))
	quiet(1)
	game._spawn_item(0, 0.0); d = game.debris.back()
	game.invulnerable = 0; game.speed = 150; game._apply_debris_contact(d, contact)
	check(game.loadout.setup == "armored" and absf((100.0 - game.health) - stock_loss * 0.8) < 0.001, "armored setup takes 20% less collision damage")
	game.set_loadout(Loadout.default_loadout())
	quiet(5); game.route.step(1.0 / 60.0)
	var stock_traction: float = game.route.traction
	game.set_loadout({"setup": "rally"})
	quiet(5); game.route.step(1.0 / 60.0)
	check(game.route.traction > stock_traction * 1.14 and game.route.traction <= 1.0, "rally setup adds dirt grip")
	game.route.landing = 1.0; game.route.step(0.5)
	var rally_landing: float = game.route.landing
	game.set_loadout(Loadout.default_loadout())
	quiet(5); game.route.landing = 1.0; game.route.step(0.5)
	check(rally_landing < game.route.landing, "rally setup recovers from landings sooner")
	var boost_used := {}
	for setup in ["stock", "turbo"]:
		game.set_loadout({"setup": setup})
		quiet(0)
		for i in range(60):
			calm_timers(); Input.action_press("boost"); game._simulate(1.0 / 60.0)
		Input.action_release("boost")
		boost_used[setup] = 100.0 - game.boost
	check(boost_used.turbo < boost_used.stock * 0.8, "turbo setup drains the boost tank more slowly")
	var gains := {}
	for setup in ["stock", "armored"]:
		game.set_loadout({"setup": setup})
		quiet(0); game.speed = 60.0; game.powertrain.reset(60.0)
		for i in range(120):
			calm_timers(); game._simulate(1.0 / 60.0)
		gains[setup] = game.speed - 60.0
	check(game.powertrain.accel_factor == 0.92 and gains.armored < gains.stock, "armored setup accelerates more slowly")
	var kicks := {}
	for setup in ["stock", "turbo"]:
		game.set_loadout({"setup": setup})
		quiet(0); game.speed = 200.0
		game._spawn_puddle(0.0); game.puddles.back().kick = 1.0
		game._hit_puddle(game.puddles.back())
		kicks[setup] = absf(game.glide_velocity)
	check(kicks.turbo > kicks.stock, "turbo setup slides further on water")
	game.set_loadout(Loadout.default_loadout())

	# --- Saves ----------------------------------------------------------------------
	game.save_enabled = true
	own_everything()
	var custom := {"accent": "glacier_teal", "wheels": "polished_alloy", "roof": "light_bar", "armor": "ram_plate", "trim": "rally", "setup": "rally"}
	game.set_loadout(custom)
	game.loadout = Loadout.default_loadout()
	game._load_settings()
	check(game.loadout == custom, "garage loadout survives save and reload")
	var edited := ConfigFile.new()
	edited.load(cfg)
	edited.set_value("garage", "loadout", {"accent": "chrome_unicorn", "wheels": "stealth_black", "setup": 3})
	edited.save(cfg)
	game._load_settings()
	check(game.loadout.accent == "stock" and game.loadout.wheels == "stealth_black" and game.loadout.setup == "stock", "edited loadout saves are sanitized on load")
	var old_save := ConfigFile.new()
	old_save.set_value("records", "best", 4200)
	old_save.set_value("settings", "muted", false)
	old_save.save(cfg)
	game._load_settings()
	check(game.loadout == Loadout.default_loadout() and game.best == 4200, "older saves without a garage section load with the stock loadout")
	game.save_enabled = false
	own_everything()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(cfg))

	# --- Garage flow and input -------------------------------------------------------
	game.set_loadout(Loadout.default_loadout())
	game.checkpoint.clear()
	quiet(2)
	game.mode = game.Mode.RUNNING
	game.open_garage()
	check(game.mode == game.Mode.RUNNING and not game.garage.active, "the garage cannot open during a chase")
	game.return_to_menu()
	game.debris.clear(); game._spawn_item(1, 0.2); game.health = 12.0
	game.open_garage()
	game.hud._process(0.0); game.world._process(0.0)
	check(game.mode == game.Mode.GARAGE and game.garage.active and game.garage.visible and not game.hud.visible and game.world.space.visible, "garage opens from base over the live 3D truck")
	check(game.debris.is_empty() and game.health == 100.0 and game.speed == 0.0 and game.world.truck.damage_level == 0.0, "garage preview shows a clean, repaired, parked truck")
	var cam: Camera3D = game.world.camera
	var on_screen := cam.unproject_position(game.world.truck.position + Vector3.UP)
	check(not cam.is_position_behind(game.world.truck.position) and on_screen.x > 60 and on_screen.x < 800, "preview camera frames the truck beside the garage panel")
	game.garage.selected = 0
	game._unhandled_input(key(KEY_DOWN))
	check(game.garage.selected == 1, "keyboard Down selects the next garage row")
	game._unhandled_input(key(KEY_RIGHT))
	check(game.loadout.wheels == Loadout.options("wheels")[1].id, "keyboard Right changes the selected part")
	game._unhandled_input(key(KEY_LEFT))
	check(game.loadout.wheels == "stock", "keyboard Left steps back to the approved part")
	game._unhandled_input(pad(JOY_BUTTON_DPAD_DOWN)); game._unhandled_input(pad(JOY_BUTTON_DPAD_RIGHT))
	check(game.garage.selected == 2 and game.loadout.roof == Loadout.options("roof")[1].id, "controller D-pad selects and changes parts")
	game.set_loadout({"accent": "rescue_red", "roof": "doppler_dome", "setup": "turbo"})
	game._unhandled_input(key(KEY_R))
	check(Loadout.is_stock_look(game.loadout) and game.loadout.setup == "turbo", "R restores the stock look without touching the chase setup")
	game._unhandled_input(pad(JOY_BUTTON_B))
	check(game.mode == game.Mode.MENU and not game.garage.active and not game.garage.visible, "controller B returns to base")
	game.open_garage()
	game._unhandled_input(key(KEY_ESCAPE))
	check(game.mode == game.Mode.MENU, "Escape returns to base without starting a chase")
	game.open_garage()
	game._unhandled_input(key(KEY_ENTER))
	check(game.mode == game.Mode.RUNNING and game.elapsed == 0.0 and not game.checkpoint_retry and game.loadout.setup == "turbo", "Enter starts a new chase with the chosen loadout")
	game.set_process(false)
	game.stage = 3; game.elapsed = 3.0 * game.STAGE_LENGTH; game.mode = game.Mode.UPGRADE
	game.choose_upgrade(1); game.checkpoints.complete()
	check(game.checkpoint.get("setup", "") == "turbo" and game.valid_checkpoint(game.checkpoint), "checkpoint snapshot records the chase setup and stays valid")
	game.return_to_menu()
	game.open_garage()
	check(game.garage.controls.any(func(c): return c is Button and c.text.begins_with("RESUME")), "garage offers to resume a saved checkpoint")
	game._unhandled_input(pad(JOY_BUTTON_A))
	check(game.mode == game.Mode.RUNNING and game.checkpoint_retry and game.stage == 3, "controller A resumes the checkpoint from the garage")
	game.finish(false, "Test run.")
	check(str(game.high_scores.front().get("setup", "")) == "turbo", "scoreboard row records the chase setup")
	game.return_to_menu()
	game.dodges.show_gallery()
	check(game.dodges.get_children().any(func(c): return c is Label and "TURBO SETUP" in c.text and "INTERCEPTOR" in c.text), "footage gallery shows the current loadout")
	game.dodges.close_gallery()

	# --- Mateo stays attached and readable ----------------------------------------------
	quiet(0)
	game.world._update_view(0.0)
	var chase_yaw: float = game.world.mateo.rotation.y
	game.world.camera.global_position = game.world.truck.global_position + Vector3(-9.0, 2.0, 0.0)
	game.world.mateo.face_camera(game.world.camera)
	var side_yaw: float = game.world.mateo.rotation.y
	check(absf(chase_yaw) < 0.2 and absf(side_yaw) > 1.0 and absf(side_yaw) <= 1.25 and game.world.mateo.get_parent() == game.world.truck.body, "Mateo keeps the chase-camera look and turns toward side views while seated")

	# --- Every setup can finish the campaign -------------------------------------------
	var all_setups := true
	for setup in ["stock", "rally", "armored", "turbo"]:
		all_setups = campaign(setup) and all_setups
	check(all_setups, "the automated driver completes the campaign with every chase setup and a custom look")

	print("GARAGE_TESTS ", checks, " checks; ", failures, " failures")
	game.queue_free(); await process_frame
	quit(0 if failures == 0 else 1)
