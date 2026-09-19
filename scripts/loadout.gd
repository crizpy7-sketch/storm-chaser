extends RefCounted
## Mateo Garage catalog.
##
## Five cosmetic slots never change handling, collision or scoring, and every
## slot's first entry is the approved v0.16 look. The CHASE SETUP slot is the only
## performance choice: each alternative is a trade-off, and STOCK multiplies every
## factor by exactly 1.0 so the original tune is untouched.
##
## Two optional fields decide what has to be earned. A cosmetic carries a
## "cost" in DATA and is bought from the career wallet. A chase setup carries a
## "badge" instead: the setups are trade-offs rather than upgrades, and priced
## next to cosmetics a child simply buys the shiny paint and drives STOCK
## forever. A badge reads as "I did a thing", which is what was asked for.
## An entry with neither field is free, so the approved stock look always is.

## What every badge is called when the garage asks for it, in the words a child
## would use out loud. Each reads a counter the run already keeps.
const BADGE_TITLES := {
	"first_light": "FIRST CHECKPOINT",
	"storm_veteran": "ALL SEVEN FILMS",
	"vortex_recorded": "INTO THE VORTEX",
	"probe_master": "TEN PROBES IN ONE RUN",
	"big_air": "TEN CLEAN LANDINGS",
	"dodge_ace": "FIVE-DODGE COMBO",
	"one_take": "WIN WITH NO RETRY",
	"iron_hull": "A WHOLE LEVEL, NO HITS",
}

const COSMETIC_SLOTS := ["accent", "wheels", "roof", "armor", "trim"]
const SLOTS := ["accent", "wheels", "roof", "armor", "trim", "setup"]
const SLOT_TITLES := {
	"accent": "PAINT ACCENTS",
	"wheels": "WHEELS",
	"roof": "ROOF EQUIPMENT",
	"armor": "BUMPER ARMOR",
	"trim": "SUSPENSION TRIM",
	"setup": "CHASE SETUP",
}

const CATALOG := {
	"accent": [
		{"id": "stock", "name": "STOCK GRAPHITE", "info": "The approved armor, bumper and roll-cage finish.", "color": Color(0.145, 0.157, 0.165), "metallic": 0.56, "roughness": 0.45},
		{"id": "storm_white", "name": "STORM WHITE", "info": "Pale ceramic armor that reads clearly through rain.", "color": Color(0.70, 0.72, 0.71), "metallic": 0.18, "roughness": 0.42, "cost": 12000},
		{"id": "rescue_red", "name": "RESCUE RED", "info": "Deep red armor, cage and bumpers.", "color": Color(0.46, 0.075, 0.055), "metallic": 0.35, "roughness": 0.4, "cost": 18000},
		{"id": "glacier_teal", "name": "GLACIER TEAL", "info": "Cold teal armor to match Mateo's storm camera.", "color": Color(0.085, 0.33, 0.35), "metallic": 0.4, "roughness": 0.42, "cost": 26000},
		{"id": "desert_bronze", "name": "DESERT BRONZE", "info": "Warm anodized bronze on every dark trim piece.", "color": Color(0.40, 0.27, 0.13), "metallic": 0.72, "roughness": 0.36, "cost": 38000},
	],
	"wheels": [
		{"id": "stock", "name": "STOCK GRAPHITE", "info": "The approved graphite all-terrain wheels.", "rim": Color(0.145, 0.157, 0.165), "rim_metallic": 0.56, "rim_roughness": 0.45, "bolts": Color(0.0, 0.0, 0.0, 0.0)},
		{"id": "bronze_beadlock", "name": "BRONZE BEADLOCK", "info": "Bronze rims with bright bolted beadlock rings.", "rim": Color(0.42, 0.29, 0.13), "rim_metallic": 0.8, "rim_roughness": 0.32, "bolts": Color(0.78, 0.66, 0.42), "cost": 30000},
		{"id": "polished_alloy", "name": "POLISHED ALLOY", "info": "Mirror-finish alloy rims.", "rim": Color(0.72, 0.74, 0.75), "rim_metallic": 0.95, "rim_roughness": 0.18, "bolts": Color(0.85, 0.86, 0.86), "cost": 38000},
		{"id": "stealth_black", "name": "STEALTH BLACK", "info": "Matte black rims and lugs.", "rim": Color(0.035, 0.037, 0.04), "rim_metallic": 0.2, "rim_roughness": 0.8, "bolts": Color(0.06, 0.06, 0.065), "cost": 24000},
	],
	"roof": [
		{"id": "stock", "name": "RADAR DISH", "info": "The approved dish, four antennas and amber beacons."},
		{"id": "light_bar", "name": "DISH + LIGHT BAR", "info": "Adds a roof LED bar for night intercepts.", "cost": 20000},
		{"id": "weather_mast", "name": "WEATHER MAST", "info": "Adds a spinning anemometer and wind vane behind the cab.", "cost": 32000},
		{"id": "doppler_dome", "name": "DOPPLER DOME", "info": "Swaps the open dish for a sealed white radome.", "cost": 40000},
	],
	"armor": [
		{"id": "stock", "name": "STOCK BUMPERS", "info": "The approved front and rear bumpers."},
		{"id": "bull_bar", "name": "TUBE BULL BAR", "info": "Adds a tubular grille guard with twin work lights.", "cost": 22000},
		{"id": "ram_plate", "name": "STEEL RAM PLATE", "info": "Adds a bolted steel plate and a front skid plate.", "cost": 34000},
		{"id": "winch", "name": "WINCH + RECOVERY", "info": "Adds a bumper winch, red recovery hooks and a rear hitch.", "cost": 38000},
	],
	"trim": [
		{"id": "stock", "name": "STOCK RIDE HEIGHT", "info": "The approved ride height and hidden dampers.", "lift": 0.0},
		{"id": "lift_kit", "name": "3-INCH LIFT", "info": "Raises the body 7.5 cm on yellow coilovers.", "lift": 0.075, "spring": Color(0.86, 0.66, 0.12), "cost": 16000},
		{"id": "rally", "name": "RALLY COILOVERS", "info": "Drops the body 3 cm on red rally springs.", "lift": -0.03, "spring": Color(0.72, 0.1, 0.07), "cost": 28000},
		{"id": "desert_runner", "name": "DESERT RUNNER", "info": "Lifts 4 cm on blue springs with remote reservoirs.", "lift": 0.04, "spring": Color(0.12, 0.34, 0.72), "cost": 40000},
	],
	"setup": [
		{"id": "stock", "name": "STOCK", "info": "The original chase tune.", "effects": "NO CHANGES"},
		{"id": "rally", "name": "RALLY", "info": "More grip on dirt and faster landing recovery. The hull takes 12% more damage.", "effects": "DIRT GRIP +15%   LANDING +25%   DAMAGE +12%", "dirt_grip": 1.15, "landing": 1.25, "damage": 1.12, "badge": "big_air"},
		{"id": "armored", "name": "ARMORED", "info": "Takes 20% less damage, but accelerates 8% slower and drains turbo faster.", "effects": "DAMAGE -20%   ACCEL -8%   TURBO DRAIN +15%", "damage": 0.8, "accel": 0.92, "boost_drain": 1.15, "badge": "iron_hull"},
		{"id": "turbo", "name": "TURBO", "info": "Turbo lasts longer and recharges faster, with 10% less grip on dirt and water.", "effects": "TURBO DRAIN -23%   RECHARGE +20%   GRIP -10%", "boost_drain": 0.77, "boost_recharge": 1.2, "dirt_grip": 0.9, "water_grip": 0.9, "badge": "probe_master"},
	],
}

static func default_loadout() -> Dictionary:
	var result := {}
	for slot in SLOTS: result[slot] = "stock"
	return result

static func options(slot: String) -> Array:
	return CATALOG.get(slot, [])

static func index_of(slot: String, id: String) -> int:
	var list := options(slot)
	for i in range(list.size()):
		if list[i].id == id: return i
	return 0

static func option(slot: String, id: String) -> Dictionary:
	var list := options(slot)
	return list[index_of(slot, id)] if not list.is_empty() else {}

static func cycle(loadout: Dictionary, slot: String, step: int) -> Dictionary:
	var list := options(slot)
	if list.is_empty(): return loadout
	var next := loadout.duplicate()
	next[slot] = list[posmod(index_of(slot, str(loadout.get(slot, "stock"))) + step, list.size())].id
	return next

## Unknown slots or ids (an edited or future save) fall back to stock.
static func sanitize(value) -> Dictionary:
	var result := default_loadout()
	if value is Dictionary:
		for slot in SLOTS:
			var id = value.get(slot, "stock")
			if id is String and options(slot).any(func(o): return o.id == id): result[slot] = id
	return result

## What a part costs in DATA; zero when it is free or badge-gated.
static func price(slot: String, id: String) -> int:
	return maxi(0, int(option(slot, id).get("cost", 0)))

## The badge a part is gated behind, or "" when it is bought or free.
static func gate(slot: String, id: String) -> String:
	return str(option(slot, id).get("badge", ""))

## The id an owned list stores. Slot-qualified, because two slots can and do
## use the same word: trim:rally is a spring, setup:rally is a chase tune.
static func part_id(slot: String, id: String) -> String:
	return slot + ":" + id

## Whether a part may be driven. Stock is always available, a badge-gated part
## needs its badge and can never be bought, and a priced part needs to have been
## bought. Note what this deliberately is not wired into: sanitize() stays
## ownership-blind, so a saved loadout is never silently reset by a career that
## failed to load, and cycle() stays unconditional, so a locked part can be
## browsed and seen on the truck. That preview is the whole carrot.
static func unlocked(slot: String, id: String, owned: Array, badges: Array) -> bool:
	if id == "stock": return true
	var badge := gate(slot, id)
	if not badge.is_empty(): return badge in badges
	if price(slot, id) <= 0: return true
	return part_id(slot, id) in owned

## The loadout with every part that has not been earned returned to stock. This
## is the only enforcement in the game.
static func owned_only(loadout: Dictionary, owned: Array, badges: Array) -> Dictionary:
	var result := sanitize(loadout)
	for slot in SLOTS:
		if not unlocked(slot, str(result[slot]), owned, badges): result[slot] = "stock"
	return result

## Everything that carries a price, for the checks that assert the catalog adds
## up to a few runs' work rather than a grind.
static func priced_parts() -> Array:
	var result: Array = []
	for slot in SLOTS:
		for entry in options(slot):
			if price(slot, str(entry.id)) > 0: result.append(part_id(slot, str(entry.id)))
	return result

static func is_stock_look(loadout: Dictionary) -> bool:
	return COSMETIC_SLOTS.all(func(slot): return str(loadout.get(slot, "stock")) == "stock")

static func with_stock_look(loadout: Dictionary) -> Dictionary:
	var result := sanitize(loadout)
	for slot in COSMETIC_SLOTS: result[slot] = "stock"
	return result

## Performance factor for the selected chase setup; 1.0 when not specified.
static func factor(loadout: Dictionary, key: String) -> float:
	return float(option("setup", str(loadout.get("setup", "stock"))).get(key, 1.0))

static func setup_name(loadout: Dictionary) -> String:
	return str(option("setup", str(loadout.get("setup", "stock"))).name)

static func summary(loadout: Dictionary) -> String:
	var parts: PackedStringArray = []
	for slot in COSMETIC_SLOTS: parts.append(str(option(slot, str(loadout.get(slot, "stock"))).name))
	return "  /  ".join(parts)
