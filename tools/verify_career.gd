extends SceneTree
## The career wallet: what a run banks, what survives a save, and what a save
## from before the wallet existed turns into.
##
## The wallet is deliberately read-only in this version -- nothing spends it
## yet -- so these checks are about the two things that would be expensive to
## get wrong later: money that vanishes on the next save, and money that can be
## farmed. Both have a specific shape in this codebase, and both are checked
## against the real save path rather than a mock.
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
	game.save_settings()
	game._load_settings()
	check(game.career.banked == 37500, "the seeded career is written once and then read back, not re-seeded")

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

	# --- reading the number out loud -------------------------------------------------
	check(game.hud.data_amount(0) == "0" and game.hud.data_amount(999) == "999", "small amounts are printed plainly")
	check(game.hud.data_amount(1000) == "1,000" and game.hud.data_amount(128450) == "128,450" and game.hud.data_amount(1421900) == "1,421,900",
		"a wallet balance is grouped so a child can say it out loud")

	print("CAREER_TESTS ", checks, " checks; ", failures, " failures")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
