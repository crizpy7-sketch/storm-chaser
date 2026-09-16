extends RefCounted
## Mateo Garage catalog.
##
## Five cosmetic slots never change handling, collision or scoring, and every
## slot's first entry is the approved v0.16 look. The CHASE SETUP slot is the only
## performance choice: each alternative is a trade-off, and STOCK multiplies every
## factor by exactly 1.0 so the original tune is untouched.

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
		{"id": "storm_white", "name": "STORM WHITE", "info": "Pale ceramic armor that reads clearly through rain.", "color": Color(0.70, 0.72, 0.71), "metallic": 0.18, "roughness": 0.42},
		{"id": "rescue_red", "name": "RESCUE RED", "info": "Deep red armor, cage and bumpers.", "color": Color(0.46, 0.075, 0.055), "metallic": 0.35, "roughness": 0.4},
		{"id": "glacier_teal", "name": "GLACIER TEAL", "info": "Cold teal armor to match Mateo's storm camera.", "color": Color(0.085, 0.33, 0.35), "metallic": 0.4, "roughness": 0.42},
		{"id": "desert_bronze", "name": "DESERT BRONZE", "info": "Warm anodized bronze on every dark trim piece.", "color": Color(0.40, 0.27, 0.13), "metallic": 0.72, "roughness": 0.36},
	],
	"wheels": [
		{"id": "stock", "name": "STOCK GRAPHITE", "info": "The approved graphite all-terrain wheels.", "rim": Color(0.145, 0.157, 0.165), "rim_metallic": 0.56, "rim_roughness": 0.45, "bolts": Color(0.0, 0.0, 0.0, 0.0)},
		{"id": "bronze_beadlock", "name": "BRONZE BEADLOCK", "info": "Bronze rims with bright bolted beadlock rings.", "rim": Color(0.42, 0.29, 0.13), "rim_metallic": 0.8, "rim_roughness": 0.32, "bolts": Color(0.78, 0.66, 0.42)},
		{"id": "polished_alloy", "name": "POLISHED ALLOY", "info": "Mirror-finish alloy rims.", "rim": Color(0.72, 0.74, 0.75), "rim_metallic": 0.95, "rim_roughness": 0.18, "bolts": Color(0.85, 0.86, 0.86)},
		{"id": "stealth_black", "name": "STEALTH BLACK", "info": "Matte black rims and lugs.", "rim": Color(0.035, 0.037, 0.04), "rim_metallic": 0.2, "rim_roughness": 0.8, "bolts": Color(0.06, 0.06, 0.065)},
	],
	"roof": [
		{"id": "stock", "name": "RADAR DISH", "info": "The approved dish, four antennas and amber beacons."},
		{"id": "light_bar", "name": "DISH + LIGHT BAR", "info": "Adds a roof LED bar for night intercepts."},
		{"id": "weather_mast", "name": "WEATHER MAST", "info": "Adds a spinning anemometer and wind vane behind the cab."},
		{"id": "doppler_dome", "name": "DOPPLER DOME", "info": "Swaps the open dish for a sealed white radome."},
	],
	"armor": [
		{"id": "stock", "name": "STOCK BUMPERS", "info": "The approved front and rear bumpers."},
		{"id": "bull_bar", "name": "TUBE BULL BAR", "info": "Adds a tubular grille guard with twin work lights."},
		{"id": "ram_plate", "name": "STEEL RAM PLATE", "info": "Adds a bolted steel plate and a front skid plate."},
		{"id": "winch", "name": "WINCH + RECOVERY", "info": "Adds a bumper winch, red recovery hooks and a rear hitch."},
	],
	"trim": [
		{"id": "stock", "name": "STOCK RIDE HEIGHT", "info": "The approved ride height and hidden dampers.", "lift": 0.0},
		{"id": "lift_kit", "name": "3-INCH LIFT", "info": "Raises the body 7.5 cm on yellow coilovers.", "lift": 0.075, "spring": Color(0.86, 0.66, 0.12)},
		{"id": "rally", "name": "RALLY COILOVERS", "info": "Drops the body 3 cm on red rally springs.", "lift": -0.03, "spring": Color(0.72, 0.1, 0.07)},
		{"id": "desert_runner", "name": "DESERT RUNNER", "info": "Lifts 4 cm on blue springs with remote reservoirs.", "lift": 0.04, "spring": Color(0.12, 0.34, 0.72)},
	],
	"setup": [
		{"id": "stock", "name": "STOCK", "info": "The original chase tune.", "effects": "NO CHANGES"},
		{"id": "rally", "name": "RALLY", "info": "More grip on dirt and faster landing recovery. The hull takes 12% more damage.", "effects": "DIRT GRIP +15%   LANDING +25%   DAMAGE +12%", "dirt_grip": 1.15, "landing": 1.25, "damage": 1.12},
		{"id": "armored", "name": "ARMORED", "info": "Takes 20% less damage, but accelerates 8% slower and drains turbo faster.", "effects": "DAMAGE -20%   ACCEL -8%   TURBO DRAIN +15%", "damage": 0.8, "accel": 0.92, "boost_drain": 1.15},
		{"id": "turbo", "name": "TURBO", "info": "Turbo lasts longer and recharges faster, with 10% less grip on dirt and water.", "effects": "TURBO DRAIN -23%   RECHARGE +20%   GRIP -10%", "boost_drain": 0.77, "boost_recharge": 1.2, "dirt_grip": 0.9, "water_grip": 0.9},
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
