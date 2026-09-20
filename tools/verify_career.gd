extends SceneTree
## The career: what a run banks, what a badge is earned by, what a part costs,
## and what survives a save.
##
## Two of these would be expensive to get wrong and have a specific shape in
## this codebase, so they are checked against the real save path rather than a
## mock: money that vanishes on the next save, and money that can be farmed.
## The rest is the economy -- prices, badges, and the single flow where an
## unearned part is returned to stock.
const MediaPack = preload("res://scripts/media.gd")
const CareerStore = preload("res://scripts/career_store.gd")
const CareerStoreLocal = preload("res://scripts/career_store_local.gd")
const Loadout = preload("res://scripts/loadout.gd")
const CFG := "user://career-test-isolated.cfg"

var checks := 0
var failures := 0
var game

## A career kept in memory and nowhere else. It exists to prove the seam: the
## owner may one day put the career on a VPS, and the only thing that should
## need writing is a class like this one.
class MemoryStore extends "res://scripts/career_store.gd":
	var stored := {}
	var writes := 0
	func read() -> Dictionary:
		return stored.duplicate(true)
	func write(career: Dictionary) -> void:
		stored = sanitize(career)
		writes += 1

func _initialize() -> void: call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1
	print("PASS: " if value else "FAIL: ", label)

func settle() -> void:
	for i in range(3): await process_frame

func wipe() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CFG))

## A save written by a version before the career existed.
func write_legacy_save(best: int, loadout: Dictionary) -> void:
	var config := ConfigFile.new()
	config.set_value("records", "best", best)
	config.set_value("records", "footage", [1, 2])
	config.set_value("settings", "muted", true)
	config.set_value("garage", "loadout", loadout)
	config.save(CFG)

func run() -> void:
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"

	# --- the store, on its own ---------------------------------------------------
	var blank := CareerStore.blank()
	check(blank.keys().size() == CareerStore.KEYS.size() and CareerStore.KEYS.all(func(k): return blank.has(k)),
		"a blank career carries exactly the six keys the store persists")
	check(blank.banked == 0 and blank.earned == 0 and blank.owned.is_empty() and blank.badges.is_empty() and blank.last_run == "" and blank.last_amount == 0,
		"a blank career has earned nothing and owns nothing")

	var dirty := CareerStore.sanitize({"banked": -500, "earned": 2.0, "owned": "wheels:bronze_beadlock", "badges": ["first_light", "first_light", 7, ""], "last_run": 91, "last_amount": -3})
	check(dirty.banked == 0 and dirty.last_amount == 0, "a hand-edited negative balance floors at zero instead of going into the game")
	check(dirty.owned.is_empty(), "an owned list that is not a list loads as owning nothing")
	check(dirty.badges == ["first_light"], "duplicate, empty and non-string badge ids are dropped")
	check(dirty.last_run == "", "a non-string run id loads as no run")
	check(CareerStore.sanitize({"banked": 900, "earned": 100}).earned == 900,
		"lifetime earnings can never load as less than the balance currently spendable")
	check(CareerStore.sanitize("not a career") == CareerStore.blank(), "a career that is not a dictionary loads blank")
	check(CareerStore.sanitize({"banked": INF, "earned": NAN}).banked == 0, "an infinite or not-a-number balance loads as zero")

	var base := CareerStore.new()
	check(base.read().is_empty(), "the bare interface reports no stored career")
	base.write({"banked": 10})
	check(base.read().is_empty(), "the bare interface stores nothing and does not raise")

	# --- the local store, against a real file -------------------------------------
	wipe()
	var store := CareerStoreLocal.new(CFG)
	check(store.read().is_empty(), "a career that has never been stored reads as absent, not as zero")
	write_legacy_save(4200, {"wheels": "stealth_black"})
	check(store.read().is_empty(), "a save from before the wallet reads as absent so it can be seeded")
	var saved := {"banked": 128450, "earned": 421900, "owned": ["wheels:bronze_beadlock"], "badges": ["first_light"], "last_run": "1758000000-8814231", "last_amount": 47300}
	store.write(saved)
	check(store.read() == saved, "every one of the six keys survives a write and a read")
	var kept := ConfigFile.new()
	kept.load(CFG)
	check(int(kept.get_value("records", "best", 0)) == 4200 and bool(kept.get_value("settings", "muted", false)),
		"writing the career preserves the rest of the settings file")
	wipe()

	# --- the game, banking runs ---------------------------------------------------
	game = load("res://main.tscn").instantiate()
	game.settings_path = CFG
	root.add_child(game)
	await settle()
	game.save_enabled = false
	check(game.career == CareerStore.blank(), "a first launch starts with an empty career")

	game.start_chase()
	game.set_process(false); game.world.set_process(false)
	var run_a: String = game.run_id
	game.health = 70.0; game.score = 40000.0; game.probes = 2
	game.stage = 2; game.stage_seen = 2; game.elapsed = 2 * game.STAGE_LENGTH + 5.0
	game.save_checkpoint()
	game.finish(false, "Test run.")
	check(game.career.banked == 40000 and game.career.earned == 40000 and game.banked_this_run == 40000,
		"a run that ends badly still banks its DATA")
	check(game.best == 40000 and game.high_scores.size() == 1, "banking leaves the scoreboard and the personal best alone")

	# The exploit, driven the way a player would find it: bank, crash, resume the
	# same run from its flag -- which restores score -- and finish again.
	check(game.can_retry_checkpoint(), "the run left a snapshot to resume from")
	game.retry_checkpoint()
	await settle()
	check(game.run_id == run_a, "resuming a checkpoint keeps the run's identity")
	game.set_process(false); game.world.set_process(false)
	game.health = 55.0
	game.mode = game.Mode.RUNNING
	game.finish(false, "Same run again.")
	check(game.career.banked == 40000 and game.banked_this_run == 0,
		"finishing the same run twice banks it once")

	game.mode = game.Mode.RUNNING
	game.score = 52000.0
	game.finish(false, "Same run, further along.")
	check(game.career.banked == 52000 and game.banked_this_run == 12000,
		"a resumed run that beats itself banks only the difference")
	check(game.career.earned == 52000, "lifetime earnings follow the same rule as the balance")

	game.mode = game.Mode.RUNNING
	game.score = 100.0
	game.finish(false, "A worse ending.")
	check(game.career.banked == 52000 and game.banked_this_run == 0, "the balance never goes down by finishing")

	game.start_chase()
	game.set_process(false); game.world.set_process(false)
	check(game.run_id != run_a, "a fresh chase is a new run")
	game.health = 100.0; game.score = 9000.0
	game.finish(true, "Won.")
	check(game.career.banked == 52000 + int(game.score) and game.career.earned == game.career.banked,
		"a won run banks its finish bonus along with the rest")

	# --- surviving a save ----------------------------------------------------------
	wipe()
	game.save_enabled = true
	game.career.owned = ["wheels:bronze_beadlock", "trim:lift_kit"]
	game.career.badges = ["first_light"]
	var expected: Dictionary = game.career.duplicate(true)
	game.save_settings()
	game.career = CareerStore.blank()
	game._load_settings()
	check(game.career == expected, "the career survives save_settings, which builds a fresh file every time")
	game.toggle_option("mateo_voice")
	game._load_settings()
	check(game.career == expected, "an unrelated settings change does not wipe the career")

	# --- a save from before the wallet ---------------------------------------------
	wipe()
	write_legacy_save(37500, {"accent": "rescue_red", "wheels": "polished_alloy", "setup": "rally"})
	game._load_settings()
	check(game.career.banked == 37500 and game.career.earned == 37500,
		"an older save opens the wallet with its best run as the balance")
	check(game.career.owned.size() == 3 and "accent:rescue_red" in game.career.owned and "wheels:polished_alloy" in game.career.owned and "setup:rally" in game.career.owned,
		"the parts the player is already driving are owned, not locked")
	check(game.loadout.setup == "rally" and game.career.badges.is_empty(),
		"a legacy RALLY setup remains equipped without inventing its badge")
	game.save_settings()
	game._load_settings()
	check(game.career.banked == 37500, "the seeded career is written once and then read back, not re-seeded")
	check(game.loadout.setup == "rally", "the migrated RALLY setup stays equipped after save and reload")
	for setup_id in ["armored", "turbo"]:
		wipe()
		write_legacy_save(37500, {"setup": setup_id})
		game._load_settings()
		check(game.loadout.setup == setup_id and game.career.badges.is_empty(),
			"a legacy %s setup remains equipped without its badge" % setup_id.to_upper())
		game.save_settings()
		game._load_settings()
		check(game.loadout.setup == setup_id,
			"the migrated %s setup survives save and reload" % setup_id.to_upper())

	wipe()
	write_legacy_save(1200, Loadout.default_loadout())
	game._load_settings()
	check(game.career.owned.is_empty() and game.career.banked == 1200, "an older save on the stock truck owns nothing and banks its best")

	wipe()
	var spent := ConfigFile.new()
	spent.set_value("records", "best", 900000)
	spent.set_value("career", "banked", 0)
	spent.set_value("career", "earned", 900000)
	spent.set_value("career", "owned", ["wheels:stealth_black"])
	spent.set_value("career", "badges", [])
	spent.set_value("career", "last_run", "")
	spent.set_value("career", "last_amount", 0)
	spent.save(CFG)
	game._load_settings()
	check(game.career.banked == 0 and game.career.earned == 900000 and game.career.owned == ["wheels:stealth_black"],
		"a career that has been spent down is not re-seeded from the personal best")

	# --- the seam -------------------------------------------------------------------
	wipe()
	var memory := MemoryStore.new()
	game.career_store = memory
	game.career = CareerStore.blank()
	game.career.banked = 1234
	game.save_settings()
	check(memory.writes > 0 and memory.stored.banked == 1234, "a different store implementation receives the career with no game change")
	var leaked := ConfigFile.new()
	check(leaked.load(CFG) == OK and not leaked.has_section("career"),
		"the rest of the settings still save, and the career is not also left in the file")
	game.career = CareerStore.blank()
	game._load_settings()
	check(game.career.banked == 1234, "and it reads back from that store")
	game.career_store = CareerStoreLocal.new(CFG)
	game.save_enabled = false
	wipe()

	# --- what the catalog asks for ---------------------------------------------------
	check(Loadout.SLOTS.all(func(slot): return Loadout.price(slot, "stock") == 0 and Loadout.gate(slot, "stock").is_empty()),
		"the approved stock part is free in every slot, so a career can always drive")
	check(Loadout.COSMETIC_SLOTS.all(func(slot): return Loadout.options(slot).slice(1).all(func(o): return Loadout.price(slot, str(o.id)) > 0 and Loadout.gate(slot, str(o.id)).is_empty())),
		"every cosmetic beyond the approved one carries a price and no badge")
	check(Loadout.options("setup").slice(1).all(func(o): return Loadout.price("setup", str(o.id)) == 0 and not Loadout.gate("setup", str(o.id)).is_empty()),
		"every chase setup is badge-gated and none of them is for sale")
	var gates_exist := true
	var catalog_total := 0
	var price_band := true
	for slot in Loadout.SLOTS:
		for entry in Loadout.options(slot):
			var gate: String = Loadout.gate(slot, str(entry.id))
			if not gate.is_empty(): gates_exist = gates_exist and Loadout.BADGE_TITLES.has(gate)
			var cost: int = Loadout.price(slot, str(entry.id))
			catalog_total += cost
			if cost > 0: price_band = price_band and cost >= 12000 and cost <= 50000
	check(gates_exist, "every badge a part is gated behind is a badge that exists")
	check(price_band, "no single part costs less than 12,000 or more than 50,000 DATA")
	# A finished run banks 80,000-140,000 for a child, so the whole catalog is
	# three or four runs' work rather than a grind.
	check(catalog_total == 456000, "the catalog totals 456,000 DATA, three or four runs")
	check(Loadout.priced_parts().size() == 16, "sixteen parts are for sale")

	# --- locking, which sanitize() and cycle() deliberately know nothing about --------
	var locked_look := {"accent": "desert_bronze", "wheels": "stealth_black", "roof": "light_bar", "armor": "winch", "trim": "rally", "setup": "turbo"}
	check(Loadout.sanitize(locked_look) == locked_look, "a saved loadout of locked parts is not silently reset on load")
	var browsed := Loadout.default_loadout()
	for i in range(3): browsed = Loadout.cycle(browsed, "wheels", 1)
	check(browsed.wheels == "stealth_black", "a locked part can still be cycled to and worn in the preview")
	check(Loadout.owned_only(locked_look, [], []) == Loadout.default_loadout(), "nothing unearned survives owned_only")
	check(Loadout.owned_only(locked_look, ["wheels:stealth_black"], ["probe_master"]).wheels == "stealth_black", "a part that was bought survives it")
	check(Loadout.owned_only(locked_look, ["wheels:stealth_black"], ["probe_master"]).setup == "turbo", "and a setup whose badge was earned survives it")
	check(Loadout.owned_only(locked_look, ["wheels:stealth_black"], []).setup == "stock", "a setup without its badge does not, however the wallet looks")
	check(not Loadout.unlocked("setup", "rally", [], []) and Loadout.unlocked("trim", "rally", ["trim:rally"], []),
		"the same word in two slots is two different parts")

	# --- buying ------------------------------------------------------------------------
	wipe()
	game.career = CareerStore.blank()
	game.career.banked = 60000
	game.career.earned = 60000
	check(game.buy_part("wheels", "stealth_black"), "a part inside the balance is bought")
	check(game.career.banked == 36000 and "wheels:stealth_black" in game.career.owned, "buying costs exactly the marked price")
	check(not game.buy_part("wheels", "stealth_black"), "buying the same part twice is refused")
	check(game.career.banked == 36000 and game.career.owned.count("wheels:stealth_black") == 1, "and it neither charges again nor owns it twice")
	check(game.career.earned == 60000, "spending never reduces the lifetime total the badges are judged on")
	check(not game.buy_part("trim", "desert_runner"), "a part beyond the balance is refused")
	check(game.career.banked == 36000, "a refused purchase leaves the balance exactly where it was")
	game.career.banked = 900000
	check(not game.buy_part("setup", "turbo") and "setup:turbo" not in game.career.owned,
		"a badge-gated setup cannot be bought with any amount of DATA")
	check(not game.buy_part("wheels", "stock") and not game.buy_part("nonsense", "stealth_black"),
		"stock parts and unknown slots are not for sale")
	var balance_floor := true
	game.career.banked = 0
	for slot in Loadout.SLOTS:
		for entry in Loadout.options(slot):
			game.buy_part(slot, str(entry.id))
			balance_floor = balance_floor and game.career.banked >= 0
	check(balance_floor and game.career.banked == 0, "buying everything on an empty wallet never drives the balance negative")

	# --- enforcement, which happens in exactly one flow --------------------------------
	game.career = CareerStore.blank()
	game.career.owned = ["wheels:stealth_black"]
	game.set_loadout(locked_look)
	check(game.loadout == locked_look, "the garage can put every locked part on the truck")
	game.mode = game.Mode.GARAGE
	game.leave_garage(false)
	check(game.loadout.wheels == "stealth_black" and game.loadout.accent == "stock" and game.loadout.roof == "stock" and game.loadout.armor == "stock" and game.loadout.trim == "stock" and game.loadout.setup == "stock",
		"leaving the garage keeps what was earned and returns the rest to stock")
	game.save_enabled = true
	game.set_loadout(locked_look)
	game.save_settings()
	game._load_settings()
	check(game.loadout.wheels == "stealth_black" and Loadout.is_stock_look(game.loadout) == false and game.loadout.setup == "stock" and game.loadout.accent == "stock",
		"a session that ended inside the garage cannot smuggle a locked part into the next launch")
	game.save_enabled = false
	wipe()

	# --- badges ------------------------------------------------------------------------
	game.career = CareerStore.blank()
	game.start_chase()
	game.set_process(false); game.world.set_process(false)
	check(game.career.badges.is_empty(), "a new career has earned no badges")
	game._award_earned_badges()
	check("first_light" not in game.career.badges, "the first checkpoint has not been reached at the start of a run")
	game.probes = 9
	game.route.landings = 12; game.route.hard_landings = 3
	game.combo = 4
	game._award_earned_badges()
	check(game.career.badges.is_empty(), "nine probes, nine clean landings and a four-dodge combo earn nothing")
	game.probes = 10; game.route.landings = 13; game.combo = 5; game.stage = 1
	game._award_earned_badges()
	check("probe_master" in game.career.badges and "big_air" in game.career.badges and "dodge_ace" in game.career.badges and "first_light" in game.career.badges,
		"ten probes, ten clean landings, a five-dodge combo and a checkpoint each earn their badge")
	var before_count: int = game.career.badges.size()
	game._award_earned_badges()
	check(game.career.badges.size() == before_count, "a badge already earned is not awarded twice")
	for film in [1, 2, 3, 4, 5, 6, 7]: game.unlock_footage(film)
	game._award_earned_badges()
	check("storm_veteran" in game.career.badges, "all seven films earn STORM VETERAN")
	check("vortex_recorded" not in game.career.badges and "one_take" not in game.career.badges, "the two finishing badges wait for a finish")

	game.career = CareerStore.blank()
	game.start_chase()
	game.set_process(false); game.world.set_process(false)
	game.checkpoint_retry = true
	game.health = 50.0
	game.finish(true, "Won after a retry.")
	check("vortex_recorded" in game.career.badges and "one_take" not in game.career.badges, "a win after a retry records the vortex but is not a one-take")
	game.start_chase()
	game.set_process(false); game.world.set_process(false)
	game.health = 50.0
	game.finish(true, "Won outright.")
	check("one_take" in game.career.badges, "a win with no retry earns ONE TAKE")

	# The normal stage transition resets route counters before the checkpoint
	# film ends. Eligibility must be captured while the completed route remains.
	for clean_landings in [9, 10]:
		game.career = CareerStore.blank()
		game.start_chase()
		game.set_process(false); game.world.set_process(false)
		game.route.enter(5)
		game.route.landings = clean_landings + 2
		game.route.hard_landings = 2
		game.stage = 6; game.stage_seen = 5
		game.elapsed = 6.0 * game.STAGE_LENGTH; game.mode = game.Mode.UPGRADE
		game.choose_upgrade(0)
		check(("big_air" in game.career.badges) == (clean_landings >= 10),
			"%d clean landings are judged before the upgrade resets the route" % clean_landings)
		check(game.route.level == 6 and game.route.landings == 0,
			"the next stage starts with fresh landing counters")
		game.checkpoints.complete()
		check(Loadout.unlocked("setup", "rally", game.career.owned, game.career.badges) == (clean_landings >= 10),
			"RALLY availability after the checkpoint preserves the ten-clean-landing threshold")

	# IRON HULL is the one badge with a counter of its own, and it is asked at
	# the checkpoint because that is the only place that knows a level ended.
	game.career = CareerStore.blank()
	game.start_chase()
	game.set_process(false); game.world.set_process(false)
	game.stage = 3; game.elapsed = 3.0 * game.STAGE_LENGTH; game.mode = game.Mode.UPGRADE
	game.choose_upgrade(1)
	game.hits = 0; game.stage_entry_hits = 0
	game.checkpoints.complete()
	check("iron_hull" in game.career.badges, "a whole level with no hits earns IRON HULL")
	game.career.badges.clear()
	game.stage = 4; game.elapsed = 4.0 * game.STAGE_LENGTH; game.mode = game.Mode.UPGRADE
	game.choose_upgrade(1)
	game.hits = 3; game.stage_entry_hits = 0
	game.checkpoints.complete()
	check("iron_hull" not in game.career.badges, "a level with hits does not")
	check(game.stage_entry_hits == 3, "and the mark moves to the level starting now")
	game.save_checkpoint()
	check(int(game.checkpoint.get("stage_entry_hits", -1)) == 3, "the mark is carried in the snapshot")
	game.hits = 9
	game.retry_checkpoint()
	await settle()
	game.set_process(false); game.world.set_process(false)
	check(game.stage_entry_hits == 3, "a resumed run keeps the mark, so it cannot claim a level it half drove")
	var older: Dictionary = game.checkpoint.duplicate(true)
	older.erase("stage_entry_hits")
	game.checkpoint = older
	game.retry_checkpoint()
	await settle()
	game.set_process(false); game.world.set_process(false)
	check(game.stage_entry_hits == int(game.hits), "a snapshot from before the mark counts the level from the resume point")

	# --- reading the number out loud -------------------------------------------------
	check(game.hud.data_amount(0) == "0" and game.hud.data_amount(999) == "999", "small amounts are printed plainly")
	check(game.hud.data_amount(1000) == "1,000" and game.hud.data_amount(128450) == "128,450" and game.hud.data_amount(1421900) == "1,421,900",
		"a wallet balance is grouped so a child can say it out loud")

	print("CAREER_TESTS ", checks, " checks; ", failures, " failures")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
