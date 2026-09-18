extends "res://scripts/advisor.gd"
## Jev (TypeSafe AI) behind the decision seam.
##
## Jev is a System One model: given a state and a typed question it returns a
## choice with calibrated probabilities and a confidence, rather than text. That
## is the only shape of AI this game has any use for. It never writes a word a
## child reads; it picks which of Mateo's already-recorded lines fits what just
## happened, out of the lines the game handed it.
##
## ## How it runs inside a frame budget
##
## It never asks a question it needs answered now. choose() returns instantly
## from a cache of decisions Jev has already made about *this kind of moment* --
## a coarse signature of the state, not the exact numbers -- and, when it has no
## entry, returns the game's own answer and queues one request to fill it in.
## At most one request is ever in flight. A cold cache plays exactly like no
## advisor at all, which is also what a dropped connection degrades to.
##
## ## What it will not do
##
## The answer is matched back to the option ids that were sent. Anything else --
## a renamed option, a garbled body, an error page, a timeout -- is discarded in
## favour of the game's own decision. Nothing from the network can reach the
## player except the choice of which recorded line to play.

const ENDPOINT := "https://api.typesafe.ai/v1/systemone"
const MODEL := "jev-latest"
## One request in flight, and no more often than this.
const MIN_INTERVAL := 0.5
const TIMEOUT := 4.0
## Decisions remembered. Small on purpose: the signatures are coarse, so this
## covers the moments that actually recur.
const CACHE_LIMIT := 192

var key := ""
var endpoint := ENDPOINT
var http: HTTPRequest
var decisions := {}
var pending := ""
var pending_options: Array = []
var pending_floor := HARMLESS
var cooldown := 0.0
## Counters the check suite and the HUD read; no behaviour depends on them.
var requests := 0
var answers := 0
var discards := 0
var last_error := ""

func _init(api_key: String, host: Node) -> void:
	key = api_key
	if is_instance_valid(host):
		http = HTTPRequest.new()
		http.timeout = TIMEOUT
		# The chase must not hitch while a body is parsed.
		http.use_threads = true
		host.add_child(http)
		http.request_completed.connect(_on_answer)

func live() -> bool:
	return not key.is_empty() and is_instance_valid(http)

func describe() -> String:
	return "JEV" if live() else "LOCAL"

func step(dt: float) -> void:
	cooldown = maxf(0.0, cooldown - dt)

## A moment, coarsely. Two near misses at 190 and 197 mph with a dented hull are
## the same situation, and asking Jev about each of them separately would warm
## nothing. Buckets are what make an asynchronous cache worth having.
func signature(topic: String, state: Dictionary) -> String:
	var parts: PackedStringArray = [topic]
	for field in state.keys():
		var value = state[field]
		if value is float or value is int:
			parts.append("%s=%d" % [field, int(round(float(value) / 25.0))] if float(value) > 3.0 else "%s=%d" % [field, int(value)])
		elif value is bool:
			parts.append("%s=%d" % [field, 1 if value else 0])
		else:
			parts.append("%s=%s" % [field, str(value)])
	parts.sort()
	return "|".join(parts)

func _ids(options: Array) -> PackedStringArray:
	var ids: PackedStringArray = []
	for option in options: ids.append(str(option.get("id", "")))
	return ids

func choose(topic: String, question: String, options: Array, state: Dictionary, fallback: int, floor: float = HARMLESS) -> int:
	if not live() or options.is_empty(): return fallback
	var ids := _ids(options)
	var cache_key := signature(topic, state) + "#" + "+".join(ids)
	if decisions.has(cache_key):
		var remembered: int = int(decisions[cache_key])
		# The option list can change between moments; an index that no longer
		# addresses the same thing is worth nothing.
		if remembered >= 0 and remembered < options.size(): return remembered
	_ask(cache_key, topic, question, options, state, floor)
	return fallback

## Queues one question. Returns quietly when another is in flight -- the moment
## has passed by the time an answer could arrive, and the next one like it will
## be served from the cache.
func _ask(cache_key: String, topic: String, question: String, options: Array, state: Dictionary, floor: float = HARMLESS) -> void:
	if not pending.is_empty() or cooldown > 0.0: return
	pending_floor = floor
	var criteria := {}
	for option in options: criteria[str(option.get("id", ""))] = str(option.get("info", ""))
	var body := {
		"model": MODEL,
		"state": state,
		"questions": {topic: {"type": "choice", "instructions": question, "criteria": criteria}},
	}
	var headers: PackedStringArray = ["Content-Type: application/json", "Authorization: Bearer " + key]
	var sent := http.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if sent != OK:
		last_error = "request failed to start: %d" % sent
		return
	pending = cache_key
	pending_options = _ids(options)
	cooldown = MIN_INTERVAL
	requests += 1

func _on_answer(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var cache_key := pending
	var asked := pending_options
	pending = ""
	pending_options = []
	if cache_key.is_empty(): return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		last_error = "http %d (result %d)" % [code, result]
		discards += 1
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary:
		last_error = "body was not an object"
		discards += 1
		return
	# The API returns {model, answers, usage} with answers keyed by the question
	# ids sent. Reading a bare map too costs one expression and means a body
	# that arrives unwrapped is still understood. The single question is taken
	# back out by position, since this only ever asks one.
	var answer_map = parsed.get("answers", parsed)
	if not answer_map is Dictionary or answer_map.is_empty():
		last_error = "no answers in body"
		discards += 1
		return
	var answer = answer_map.values()[0]
	if not answer is Dictionary:
		last_error = "answer was not an object"
		discards += 1
		return
	# Choice and Score answers carry a confidence derived from the probability
	# distribution; below the floor the model is saying none of the options is a
	# clear winner, and the game's own decision is what that should leave
	# standing. It is not an error -- an honest "I am not sure" is a useful
	# answer, and the floor scales with what the question decides.
	if float(answer.get("confidence", 0.0)) < pending_floor:
		discards += 1
		return
	var picked := str(answer.get("choice", ""))
	var index := asked.find(picked)
	if index < 0:
		last_error = "answer named an option that was not offered"
		discards += 1
		return
	if decisions.size() >= CACHE_LIMIT: decisions.clear()
	decisions[cache_key] = index
	answers += 1
	last_error = ""
