extends RefCounted
## The decision seam.
##
## Storm Chaser decides everything for itself and always has. An advisor may
## only re-rank a choice the game has already made, among options the game
## itself supplied, and every call carries the game's own answer as `fallback`.
## With no advisor, no key, no network, no confidence or no cache, the fallback
## stands. That is why the check suites are untouched by any of this, and why
## the game plays identically on a laptop in a field with no signal.
##
## Two rules hold for every implementation:
##
## 1. **Nothing waits.** This is a 60 fps game. An implementation that needs a
##    server answers from what it already knows and warms itself for next time.
##    No call may block a frame, and none of them does.
## 2. **Nothing new reaches the player.** An advisor returns an index into a
##    list of things a human already recorded, drew or tuned. It cannot write a
##    word, name a part or invent an event. An answer that is not one of the
##    options offered is discarded.

## How certain an answer must be before it is allowed to overrule the game.
##
## A threshold is not one number: it scales with what being wrong costs, and
## this is the floor for a decision whose worst outcome the player would not
## notice. It is deliberately low, because a spread distribution usually means
## several options were *acceptable* rather than that the answer was bad, and
## discarding those would throw the answer away in exactly the case the question
## was worth asking -- the tie. A decision that changes difficulty or progress
## belongs at a higher floor, passed per call.
const HARMLESS := 0.5

## The game's own answer, possibly improved.
##
## `options` is an Array of Dictionaries carrying an "id" and an "info" that
## describes when that option is the right one. `state` describes the moment.
## `fallback` is what the game decided by itself, and is what is returned unless
## an implementation is available and at least `floor` certain.
func choose(_topic: String, _question: String, _options: Array, _state: Dictionary, fallback: int, _floor: float = HARMLESS) -> int:
	return fallback

## Called once a frame by the game so an implementation can retire stale work.
func step(_dt: float) -> void:
	pass

## True when a real service is behind this, for the one HUD line that says so.
func live() -> bool:
	return false

func describe() -> String:
	return "LOCAL"
