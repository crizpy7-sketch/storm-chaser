extends RefCounted
## The career's persistence seam.
##
## Everything the career knows -- the spendable balance, the lifetime total,
## the parts owned and the badges earned -- is read and written through this
## one class. No game code opens a file or a socket for it. The owner has asked
## about a VPS with a database later; when that exists, a second implementation
## with these same three methods drops in and nothing else changes.
##
## A store returns an EMPTY dictionary when no career has ever been stored --
## a save from before the wallet existed, or a player the server has never
## seen. That is not the same as a career of zero, and main.gd seeds a first
## career from it rather than locking the player out of the truck they are
## already driving.

const SECTION := "career"
const KEYS := ["banked", "earned", "owned", "badges", "last_run", "last_amount"]

## A career that has earned nothing yet.
static func blank() -> Dictionary:
	return {"banked": 0, "earned": 0, "owned": [], "badges": [], "last_run": "", "last_amount": 0}

## Stored careers are untrusted: a hand-edited cfg, a save from a future
## version, or one day a server response. Every implementation runs this, so a
## bad value can never reach the game as anything but a blank field. Balances
## floor at zero rather than being rejected, because refusing to load a career
## would silently cost a child everything they have earned.
static func sanitize(value) -> Dictionary:
	var result := blank()
	if not value is Dictionary: return result
	result.banked = maxi(0, _as_int(value.get("banked", 0)))
	result.earned = maxi(0, _as_int(value.get("earned", 0)))
	# Lifetime earnings can never be less than what is currently spendable.
	result.earned = maxi(result.earned, result.banked)
	result.owned = _as_ids(value.get("owned", []))
	result.badges = _as_ids(value.get("badges", []))
	var run = value.get("last_run", "")
	result.last_run = run if run is String else ""
	result.last_amount = maxi(0, _as_int(value.get("last_amount", 0)))
	return result

static func _as_int(value) -> int:
	if value is int: return value
	if value is float and is_finite(value): return int(value)
	return 0

## Ids are free-form strings ("wheels:bronze_beadlock", "first_light") so that
## adding a part or a badge never needs this file. Duplicates and non-strings
## are dropped.
static func _as_ids(value) -> Array:
	var result: Array = []
	if not value is Array: return result
	for id in value:
		if id is String and not id.is_empty() and id not in result: result.append(id)
	return result

## Points a file-backed store at a new location; a remote store ignores it.
## Only the harnesses, which each run against their own cfg, use this.
func rebind(_path: String) -> void:
	pass

## The stored career, or an empty dictionary when there is none.
func read() -> Dictionary:
	return {}

func write(_career: Dictionary) -> void:
	pass
