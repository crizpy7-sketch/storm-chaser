extends RefCounted
## Optional media loading.
##
## The full Storm Chaser project ships ElevenLabs audio, prerecorded films and
## generated textures. A trimmed source copy (for example a code-review ZIP) may
## omit them while their .import files remain, which makes ResourceLoader.exists()
## report true even though load() fails. Every optional file goes through here:
## real media always wins; otherwise a small in-memory stand-in keeps the game
## running. Stand-ins are never written to disk, so copying the real asset
## folders back into the project restores the original look and sound.

const REFERENCE_PATH := "res://assets/art/interceptor-reference.jpeg"
const TRUCK_GLB := "res://assets/models/interceptor-3d.glb"
## A representative sample. When any is absent the menu shows a media notice
## and media-dependent automated checks are reported as skipped.
const MEDIA_PACK := [
	"res://assets/audio/engine.wav",
	"res://assets/audio/chase.wav",
	"res://assets/audio/hit.wav",
	"res://assets/cinematics/storm-film.ogv",
	"res://assets/cinematics/checkpoints/barn.ogv",
	"res://assets/cinematics/finale/final_transmission.ogv",
	"res://assets/art/terrain/clay-ruts.png",
	"res://assets/art/building-materials.png",
	"res://assets/art/flying-cow.png",
	REFERENCE_PATH,
]

static var _fallbacks: Dictionary = {}
static var missing: PackedStringArray = PackedStringArray()
static var _complete: int = -1
## Automated suites set this to a tiny placeholder .ogv so film orchestration
## (pausing, saving, gallery replay) is still exercised in a trimmed copy.
## The shipped game never sets it.
static var stand_in_film := ""

## True only when the resource can actually be loaded (source file present, or
## its imported/exported remap target present).
static func available(path: String) -> bool:
	if not stand_in_film.is_empty() and path.get_extension() == "ogv" and not _installed(path): return true
	return _installed(path)

static func _installed(path: String) -> bool:
	if path.is_empty() or not ResourceLoader.exists(path): return false
	if FileAccess.file_exists(path): return true
	var remap := ConfigFile.new()
	if remap.load(path + ".import") != OK:
		# Not an imported file (exported scenes use .remap); the loader knows it.
		return true
	if not remap.has_section("remap"): return false
	for key in remap.get_section_keys("remap"):
		if str(key).begins_with("path"):
			var target := str(remap.get_value("remap", key, ""))
			if not target.is_empty() and FileAccess.file_exists(target): return true
	return false

static func media_complete() -> bool:
	if _complete < 0:
		_complete = 1
		for path in MEDIA_PACK:
			if not _installed(path): _complete = 0
	return _complete == 1

static func _note_missing(path: String) -> void:
	if path in missing: return
	missing.append(path)
	if missing.size() == 1:
		push_warning("Storm Chaser: optional media is missing (first: %s). Built-in stand-ins are used; copy the full assets folders back to restore it." % path)

## Loads a texture, or returns a generated stand-in: "clay", "building", "cow",
## "reference", or "" for null (callers then choose an existing texture).
static func texture(path: String, fallback: String = "") -> Texture2D:
	if available(path):
		var loaded := load(path) as Texture2D
		if loaded != null: return loaded
	_note_missing(path)
	if fallback.is_empty(): return null
	var key := "texture:" + fallback
	if not _fallbacks.has(key):
		match fallback:
			"clay": _fallbacks[key] = _clay_ruts()
			"building": _fallbacks[key] = _building_atlas()
			"cow": _fallbacks[key] = _cow_cutout()
			"reference": _fallbacks[key] = _reference_from_glb()
			_: return null
	return _fallbacks[key]

## Returns the real stream, or a fresh short silent clip (fresh so per-player
## loop settings never leak between players).
static func audio(path: String) -> AudioStream:
	if available(path):
		var loaded := load(path) as AudioStream
		if loaded != null: return loaded
	_note_missing(path)
	return silence()

static func video(path: String) -> VideoStream:
	if _installed(path):
		var loaded := load(path) as VideoStream
		if loaded != null: return loaded
	if stand_in_film.is_empty(): return null
	var key := "film:" + path
	if not _fallbacks.has(key):
		var placeholder := VideoStreamTheora.new()
		placeholder.file = stand_in_film
		placeholder.set_meta("media_path", path)
		_fallbacks[key] = placeholder
	return _fallbacks[key]

## The project path a stream represents, including test placeholders.
static func film_path(stream: Resource) -> String:
	if stream == null: return ""
	if not stream.resource_path.is_empty(): return stream.resource_path
	return str(stream.get_meta("media_path", ""))

static func using_stand_ins() -> bool:
	return not stand_in_film.is_empty()

static func silence(seconds: float = 0.5) -> AudioStreamWAV:
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_8_BITS
	clip.mix_rate = 11025
	clip.stereo = false
	var data := PackedByteArray()
	data.resize(maxi(1, int(seconds * clip.mix_rate)))
	clip.data = data
	return clip

## The approved truck scene references the reference sheet by path. When that
## JPEG is absent, register the identical sheet embedded in the truck GLB under
## the same path so the scene loads unchanged.
static func ensure_truck_reference() -> void:
	if available(REFERENCE_PATH) or _fallbacks.has("provided:" + REFERENCE_PATH): return
	var sheet := texture(REFERENCE_PATH, "reference")
	if sheet == null: return
	if not ResourceLoader.has_cached(REFERENCE_PATH):
		sheet.take_over_path(REFERENCE_PATH)
	_fallbacks["provided:" + REFERENCE_PATH] = sheet

static func clear_fallbacks() -> void:
	_fallbacks.clear()

# --- Generated stand-ins -----------------------------------------------------

static func _reference_from_glb() -> Texture2D:
	var scene := load(TRUCK_GLB) as PackedScene if available(TRUCK_GLB) else null
	var found: Texture2D = null
	if scene != null:
		var root := scene.instantiate()
		found = _find_reference(root)
		root.free()
	if found == null:
		var plain := Image.create(8, 8, false, Image.FORMAT_RGB8)
		plain.fill(Color(0.72, 0.42, 0.16))
		found = ImageTexture.create_from_image(plain)
	return found

static func _find_reference(node: Node) -> Texture2D:
	if node is MeshInstance3D and node.mesh != null:
		for surface in range(node.mesh.get_surface_count()):
			var mat := node.mesh.surface_get_material(surface) as StandardMaterial3D
			if mat != null and mat.albedo_texture != null and str(mat.resource_name).begins_with("Reference bodywork"):
				return mat.albedo_texture
	for child in node.get_children():
		var hit := _find_reference(child)
		if hit != null: return hit
	return null

static func _noise(seed_value: int, size: int, frequency: float, octaves: int) -> Image:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = seed_value
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	return noise.get_seamless_image(size, size, false, false, 0.12)

static func _clay_ruts() -> Texture2D:
	# Light tan wet clay with two longitudinal ruts; tiles seamlessly.
	var size := 256
	var base := _noise(7041, size, 0.018, 5)
	var grit := _noise(913, size, 0.22, 2)
	var image := Image.create(size, size, false, Image.FORMAT_RGB8)
	var tan := Color(0.64, 0.50, 0.35)
	var dark := Color(0.39, 0.29, 0.19)
	var puddle := Color(0.50, 0.53, 0.54)
	for y in range(size):
		var wobble := sin(float(y) / size * TAU) * 0.012
		for x in range(size):
			var n := base.get_pixel(x, y).r
			var g := grit.get_pixel(x, y).r
			var u := float(x) / size
			var rut := 0.0
			for center in [0.27, 0.73]:
				rut = maxf(rut, 1.0 - smoothstep(0.025, 0.085, absf(u - center - wobble)))
			var color := tan.lerp(dark, clampf(n * 0.8 + rut * 0.38 - 0.18, 0.0, 1.0))
			color = color.lerp(puddle, smoothstep(0.58, 0.72, n) * rut * 0.75)
			var fleck := smoothstep(0.78, 0.9, g)
			color = color * (0.9 + g * 0.18) + Color(0.06, 0.05, 0.03) * fleck
			image.set_pixel(x, y, color)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

static func _building_atlas() -> Texture2D:
	# 2 x 2 atlas matching building-materials.png: barn siding, corrugated
	# roofing, cast concrete and blue-gray sheet steel.
	var tile := 128
	var image := Image.create(tile * 2, tile * 2, false, Image.FORMAT_RGB8)
	var grain := _noise(311, tile, 0.05, 4)
	var fine := _noise(1709, tile, 0.3, 2)
	for y in range(tile):
		for x in range(tile):
			var n := grain.get_pixel(x, y).r
			var f := fine.get_pixel(x, y).r
			var streak := grain.get_pixel(x, (y * 7) % tile).r
			# Barn: 16 px vertical planks, peeling red paint over gray wood.
			var plank := x % 16
			var seam := 1.0 if plank == 0 else 0.0
			var peel := smoothstep(0.62, 0.72, n)
			var barn := Color(0.46, 0.17, 0.13).lerp(Color(0.43, 0.37, 0.31), peel)
			barn = barn * (0.82 + f * 0.25) * (1.0 - seam * 0.55)
			if plank == 8 and (y % 40) == 10: barn = Color(0.18, 0.16, 0.15)
			image.set_pixel(x, y, barn)
			# Roofing: 8 px ribs with rust streaks.
			var rib := 0.78 + 0.22 * sin(float(x) / 8.0 * TAU)
			var roof := Color(0.63, 0.65, 0.64) * rib
			roof = roof.lerp(Color(0.46, 0.30, 0.18), smoothstep(0.66, 0.8, streak) * 0.55)
			image.set_pixel(tile + x, y, roof * (0.9 + f * 0.12))
			# Concrete: aggregate flecks, rain streaks and a shallow crack.
			var concrete := Color(0.55, 0.56, 0.55) * (0.86 + n * 0.2)
			concrete = concrete.darkened(smoothstep(0.6, 0.75, streak) * 0.22)
			if smoothstep(0.85, 0.92, f) > 0.5: concrete = concrete.lightened(0.12)
			if absf(float(x) - (40.0 + y * 0.35 + sin(y * 0.2) * 3.0)) < 0.8 and y > 30 and y < 100:
				concrete = concrete.darkened(0.45)
			image.set_pixel(x, tile + y, concrete)
			# Steel: panels, bolts, scratches and rust at the joins.
			var joint := x % 64 == 0 or y % 64 == 0
			var steel := Color(0.28, 0.33, 0.37) * (0.88 + n * 0.18)
			if joint: steel = Color(0.40, 0.25, 0.16)
			var bolt_x := x % 64
			var bolt_y := y % 64
			if (bolt_x == 5 or bolt_x == 59) and (bolt_y == 5 or bolt_y == 59): steel = Color(0.62, 0.64, 0.64)
			if smoothstep(0.88, 0.95, f) > 0.5 and (x + y) % 3 == 0: steel = steel.lightened(0.2)
			image.set_pixel(tile + x, tile + y, steel)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

static func _ellipse(p: Vector2, center: Vector2, radius: Vector2) -> float:
	var d := ((p - center) / radius).length()
	return 1.0 - smoothstep(0.94, 1.06, d)

static func _cow_cutout() -> Texture2D:
	# Side-view Holstein silhouette with soft edges for the tumbling flyby.
	var w := 384
	var h := 256
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var patches := _noise(4242, 128, 0.045, 2)
	var white := Color(0.9, 0.88, 0.84)
	var black := Color(0.08, 0.075, 0.07)
	for y in range(h):
		for x in range(w):
			var p := Vector2(x, y)
			var body := _ellipse(p, Vector2(180, 118), Vector2(104, 52))
			var head := _ellipse(p, Vector2(302, 92), Vector2(38, 27))
			var snout := _ellipse(p, Vector2(334, 104), Vector2(18, 15))
			var ear := _ellipse(p, Vector2(282, 70), Vector2(16, 8))
			var neck := _ellipse(p, Vector2(262, 104), Vector2(36, 30))
			var legs := 0.0
			for lx in [110.0, 138.0, 222.0, 248.0]:
				if absf(x - lx) < 9.0 and y > 140 and y < 228: legs = 1.0
			var tail := 1.0 if absf(float(x) - (78.0 - (y - 104) * 0.25)) < 3.0 and y > 104 and y < 186 else 0.0
			var alpha := maxf(maxf(body, head), maxf(maxf(snout, ear), maxf(neck, maxf(legs, tail))))
			if alpha <= 0.0: continue
			var spot := patches.get_pixel(x % 128, y % 128).r
			var color := black if spot > 0.56 else white
			if snout > 0.5: color = Color(0.78, 0.6, 0.56)
			if legs > 0.5 and y > 214: color = black
			if tail > 0.5: color = black
			color.a = alpha
			image.set_pixel(x, y, color)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
