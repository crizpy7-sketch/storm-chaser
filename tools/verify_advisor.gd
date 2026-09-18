extends SceneTree
## The decision seam, and Mateo deciding what to say.
##
## The point of these checks is that the game is never at the mercy of the
## advisor. Every path that could go wrong -- no key, no network, an error, a
## shrug, a garbled body, an answer naming something that was never offered --
## has to come out as the game's own decision, unchanged. A check suite that
## reached a network would be worthless, so one of these asserts that this one
## cannot.
const MediaPack = preload("res://scripts/media.gd")
const Advisor = preload("res://scripts/advisor.gd")
const AdvisorJev = preload("res://scripts/advisor_jev.gd")

var checks := 0
var failures := 0
var game

## Stands in for a service that is certain about everything, so the wiring can
## be checked without a network.
class StubAdvisor extends "res://scripts/advisor.gd":
	var forced := -1
	var seen_options: Array = []
	var seen_state := {}
	var seen_topic := ""
	var seen_floor := -1.0
	func choose(topic: String, _question: String, options: Array, state: Dictionary, fallback: int, floor: float = HARMLESS) -> int:
		seen_topic = topic
		seen_options = options.duplicate(true)
		seen_state = state.duplicate(true)
		seen_floor = floor
		return forced if forced >= 0 else fallback

func _initialize() -> void: call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1
	print("PASS: " if value else "FAIL: ", label)

func settle() -> void:
	for i in range(3): await process_frame

func options(ids: Array) -> Array:
	return ids.map(func(id): return {"id": str(id), "info": "about " + str(id)})

## A body shaped the way the API documents a choice answer.
func answer_body(choice: String, confidence: float, wrapped: bool = false) -> PackedByteArray:
	var answer := {"type": "choice", "choice": choice, "probabilities": {choice: confidence}, "confidence": confidence}
	var body := {"mateo_line": answer}
	return JSON.stringify({"answers": body} if wrapped else body).to_utf8_buffer()

func deliver(jev, cache_key: String, ids: Array, body: PackedByteArray, code: int = 200, result: int = HTTPRequest.RESULT_SUCCESS) -> void:
	jev.pending = cache_key
	jev.pending_options = PackedStringArray(ids)
	jev._on_answer(result, code, PackedStringArray(), body)

func run() -> void:
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"

	# --- the seam itself -------------------------------------------------------------
	var local := Advisor.new()
	check(local.choose("topic", "q", options(["a", "b", "c"]), {"hull": 80}, 2) == 2, "the local advisor returns the game's own decision")
	check(local.choose("topic", "q", [], {}, -1) == -1, "including when the game had no decision to make")
	check(not local.live() and local.describe() == "LOCAL", "the local advisor does not claim to be a service")

	game = load("res://main.tscn").instantiate()
	game.settings_path = "user://advisor-test-isolated.cfg"
	root.add_child(game)
	await settle()
	game.save_enabled = false
	check(not game.advisor.live(), "a check suite never gets a live advisor, whatever is in the environment")
	OS.set_environment("TYPESAFE_API_KEY", "not-a-real-key-for-tests")
	game.build_advisor()
	check(not game.advisor.live(), "and not even with a key present, because --test excludes itself outright")
	OS.set_environment("TYPESAFE_API_KEY", "")
	game.storm_ai = false
	game.build_advisor()
	check(not game.advisor.live(), "turning the option off leaves the game deciding for itself")
	game.storm_ai = true
	game.build_advisor()
	check(not game.advisor.live() and game.advisor.describe() == "LOCAL", "no key in the environment means no service, silently")

	# --- the Jev advisor, without a network --------------------------------------------
	var jev = AdvisorJev.new("test-key", game)
	await settle()
	check(jev.live() and jev.describe() == "JEV", "a key and a host make it live")
	check(AdvisorJev.new("", game).live() == false, "an empty key does not")
	var three := options(["mateo_cow", "mateo_dodge", "mateo_recording"])
	var moment := {"hull": 82, "speed_mph": 190, "just_dodged": true}
	check(jev.choose("mateo_line", "q", three, moment, 1) == 1, "a cold cache answers with the game's own decision")
	check(jev.requests <= 1, "and asks at most once while doing it")

	var cache_key: String = jev.signature("mateo_line", moment) + "#" + "+".join(PackedStringArray(["mateo_cow", "mateo_dodge", "mateo_recording"]))
	deliver(jev, cache_key, ["mateo_cow", "mateo_dodge", "mateo_recording"], answer_body("mateo_cow", 0.91))
	check(jev.answers == 1 and jev.choose("mateo_line", "q", three, moment, 1) == 0, "an answered question is remembered and used next time")
	jev.decisions.clear()
	deliver(jev, cache_key, ["mateo_cow", "mateo_dodge", "mateo_recording"], answer_body("mateo_cow", 0.91, true))
	check(jev.choose("mateo_line", "q", three, moment, 1) == 0, "an answer wrapped in an answers envelope reads the same")

	# Everything that can go wrong has to come out as the game's own decision.
	var bad := [
		["low confidence", answer_body("mateo_cow", 0.2), 200, HTTPRequest.RESULT_SUCCESS],
		["an option that was never offered", answer_body("mateo_sings_a_song", 0.99), 200, HTTPRequest.RESULT_SUCCESS],
		["an error page", "<html>502</html>".to_utf8_buffer(), 502, HTTPRequest.RESULT_SUCCESS],
		["a connection that failed", answer_body("mateo_cow", 0.99), 0, HTTPRequest.RESULT_CANT_CONNECT],
		["a body that is not JSON", "not json at all".to_utf8_buffer(), 200, HTTPRequest.RESULT_SUCCESS],
		["an empty object", "{}".to_utf8_buffer(), 200, HTTPRequest.RESULT_SUCCESS],
		["a JSON array", "[1,2,3]".to_utf8_buffer(), 200, HTTPRequest.RESULT_SUCCESS],
	]
	var all_safe := true
	for case in bad:
		jev.decisions.clear()
		deliver(jev, cache_key, ["mateo_cow", "mateo_dodge", "mateo_recording"], case[1], int(case[2]), int(case[3]))
		all_safe = all_safe and jev.decisions.is_empty() and jev.choose("mateo_line", "q", three, moment, 1) == 1
	check(all_safe, "a shrug, a wrong answer, an error page, a dropped connection and garbage all leave the game's decision standing")

	jev.decisions.clear()
	deliver(jev, cache_key, ["mateo_cow", "mateo_dodge", "mateo_recording"], answer_body("mateo_cow", 0.91))
	check(jev.choose("mateo_line", "q", options(["mateo_dodge"]), moment, 0) == 0, "a remembered answer is dropped when the options are no longer the same list")

	# The floor scales with what the question decides, so it travels with the
	# question rather than being one number for the whole game.
	jev.decisions.clear()
	jev.pending_floor = Advisor.HARMLESS
	deliver(jev, cache_key, ["mateo_cow", "mateo_dodge", "mateo_recording"], answer_body("mateo_cow", 0.52))
	check(jev.choose("mateo_line", "q", three, moment, 1) == 0,
		"a spread distribution between several acceptable options is still used for a harmless choice")
	jev.decisions.clear()
	jev.pending_floor = 0.9
	deliver(jev, cache_key, ["mateo_cow", "mateo_dodge", "mateo_recording"], answer_body("mateo_cow", 0.52))
	check(jev.decisions.is_empty() and jev.choose("mateo_line", "q", three, moment, 1) == 1,
		"the same answer is refused when the question carries a higher floor")
	jev.pending_floor = Advisor.HARMLESS
	check(Advisor.new().choose("t", "q", three, moment, 2, 0.99) == 2, "the local advisor ignores the floor, having nothing to be unsure about")

	var before_requests: int = jev.requests
	jev.pending = "something in flight"
	jev._ask("another", "mateo_line", "q", three, moment)
	check(jev.requests == before_requests, "only one question is ever in flight")
	jev.pending = ""
	jev.cooldown = 99.0
	jev._ask("another", "mateo_line", "q", three, moment)
	check(jev.requests == before_requests, "and they are rate limited even when nothing is in flight")
	jev.step(100.0)
	check(is_zero_approx(jev.cooldown), "the rate limit expires on its own")

	check(jev.signature("mateo_line", {"hull": 82, "speed_mph": 190}) == jev.signature("mateo_line", {"hull": 78, "speed_mph": 196}),
		"two moments that are the same kind of moment share one cached decision")
	check(jev.signature("mateo_line", {"hull": 82}) != jev.signature("mateo_line", {"hull": 12}),
		"a healthy truck and a wrecked one do not")
	jev.decisions.clear()
	for i in range(AdvisorJev.CACHE_LIMIT + 8): jev.decisions["key%d" % i] = 0
	deliver(jev, cache_key, ["mateo_cow", "mateo_dodge", "mateo_recording"], answer_body("mateo_cow", 0.91))
	check(jev.decisions.size() <= AdvisorJev.CACHE_LIMIT, "the remembered decisions cannot grow without bound")

	# --- what Mateo does with it --------------------------------------------------------
	game.start_chase()
	game.set_process(false); game.world.set_process(false)
	var mateo = game.world.mateo
	var stub := StubAdvisor.new()
	game.advisor = stub

	game.mateo_cooldown = 0.0
	game.mateo_caption = ""
	mateo._speak({"near_miss": false, "intro": false, "cow": false})
	check(game.mateo_caption == "", "with nothing to remark on, Mateo says nothing")

	# The bug this rework exists for: a near miss and a cow in the same frame
	# used to be settled by the order the checks were written in.
	game.mateo_cooldown = 0.0
	mateo.said.clear()
	mateo._speak({"near_miss": true, "intro": true, "cow": true})
	check(game.mateo_caption == "A flying cow?!", "when everything happens at once, the flying cow wins")
	check(stub.seen_topic == "mateo_line" and stub.seen_options.size() == 3, "and all three candidates were offered to the advisor")

	game.mateo_cooldown = 0.0
	mateo._speak({"near_miss": true, "intro": false, "cow": false})
	check(game.mateo_caption == "I got that!", "a near miss on its own is still remarked on")
	game.mateo_cooldown = 5.0
	game.mateo_caption = ""
	mateo._speak({"near_miss": true, "intro": false, "cow": false})
	check(game.mateo_caption == "", "the cooldown still holds him to one line at a time")

	stub.forced = 1
	game.mateo_cooldown = 0.0
	mateo.said.clear()
	mateo._speak({"near_miss": true, "intro": true, "cow": true})
	check(game.mateo_caption == "I got that!", "an advisor can re-rank the candidates, and the chosen line is what is said")
	stub.forced = 99
	game.mateo_cooldown = 0.0
	mateo.said.clear()
	mateo._speak({"near_miss": true, "intro": true, "cow": true})
	check(game.mateo_caption == "A flying cow?!", "an advisor answering off the end of the list is ignored")
	stub.forced = -1

	var offered_ids: Array = stub.seen_options.map(func(o): return str(o.id))
	var known_ids: Array = mateo.LINES.map(func(l): return str(l.id))
	check(offered_ids.all(func(id): return id in known_ids), "an advisor is only ever offered lines that have already been recorded")
	check(stub.seen_options.all(func(o): return o.has("info") and not str(o.info).is_empty()), "each candidate carries the description that says when it fits")
	var identifying := ["name", "player", "user", "email", "id", "run_id", "key"]
	check(identifying.all(func(field): return not stub.seen_state.has(field)), "the moment sent out carries no identity of any kind")
	check(stub.seen_state.has("hull") and stub.seen_state.has("dodge_combo") and stub.seen_state.has("level"), "it carries the run's own numbers, which is all it carries")
	check(is_equal_approx(stub.seen_floor, Advisor.HARMLESS), "Mateo's line is asked at the harmless floor, because that is what being wrong costs")

	game.mateo_cooldown = 0.0
	mateo.said.clear()
	mateo._speak({"near_miss": false, "intro": true, "cow": false})
	check(game.mateo_caption.begins_with("Keep it steady"), "the opening line is still spoken at the start of a chase")
	check(mateo.intro_spoken, "and is not repeated")

	print("ADVISOR_TESTS ", checks, " checks; ", failures, " failures")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
