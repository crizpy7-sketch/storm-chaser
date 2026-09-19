# Storm Chaser v0.17.0 — Mateo's Garage

## Mateo's Garage

Choose **MATEO'S GARAGE** at the base. The garage opens over the live 3D truck, parked in the rain with Mateo filming from the bed; the camera orbits slowly and can be turned by hand.

Five slots change the look only:

| Slot | Options (first = approved stock) |
|---|---|
| Paint accents | Stock Graphite, Storm White, Rescue Red, Glacier Teal, Desert Bronze (armor, roll cage, flares and bumpers) |
| Wheels | Stock Graphite, Bronze Beadlock, Polished Alloy, Stealth Black |
| Roof equipment | Radar Dish, Dish + Light Bar, Weather Mast (spinning anemometer and vane), Doppler Dome |
| Bumper armor | Stock Bumpers, Tube Bull Bar with work lights, Steel Ram Plate with skid plate, Winch + Recovery hooks and rear hitch |
| Suspension trim | Stock Ride Height, 3-Inch Lift, Rally Coilovers, Desert Runner. Visible coilovers track the wheels. |

Every slot starts on the approved part, and **STOCK LOOK** puts all five back. Parts are separate rigid meshes on the sprung body; the approved 67,656-triangle truck mesh, its textures and Mateo's artwork are never modified. An automated test drives the same scripted route with the stock look and a fully customized look and requires identical steering, jumps, hull and boost.

**Chase setup** is the only performance choice, shown separately:

| Setup | Effect |
|---|---|
| Stock | The original v0.16 tune. Every factor is exactly 1.0. |
| Rally | Dirt grip +15%, landing recovery +25%, hull damage +12% |
| Armored | Hull damage −20%, acceleration −8%, turbo drain +15% |
| Turbo | Turbo drain −23%, turbo recharge +20%, dirt and water grip −10% |

"Hull damage" covers debris hits, hard landings, the shoulder and driving too close to the tornado. The automated driver completes the full campaign with every setup. A non-stock setup is labeled on the local top-five board and in the debrief. Checkpoint snapshots record the setup; a retry uses whatever setup the garage holds.

The loadout is saved in the existing settings file under `[garage]`. Older saves load the stock loadout, and unknown or edited values fall back to stock. Mateo's Footage shows the current loadout under the film cards, and the base screen shows the look and setup under the garage button.

**Garage controls.** Keyboard: Up/Down or W/S select, Left/Right or A/D change, Q/E or mouse drag orbit, R stock look, Enter/Space start (or resume a checkpoint), Escape back. Controller: D-pad or left stick, LB/RB orbit, Y stock look, A or Start to start, B back. Mouse and touch: click a row or its arrows, drag the truck.

## Fixes and performance

- **Hill levels run far faster.** In Dirt Shortcut, Ridgeline Jumps and Wild Hills, the road, its shoulders, a 1,360-point hill grid and the roadside grass heights were recomputed in GDScript every frame. The course frame is now cached, and the road and its shoulders share the same road rows. The hill grid is a static mesh: `ground.gdshader` computes its heights and smooth normals from the original formula (`shaders/terrain_field.gdshaderinc`), and `field_grass.gdshader` sets the grass on the same field. On one test machine, `tools/measure_frame_cost.gd` measured the per-frame view update in those levels falling from 60–76 ms to 5.3–7.3 ms. It fell from about 11 to 5 ms in Crosswind Curves and from about 8–9 to 2.5 ms in Vortex Run. These figures exclude GPU rendering time. Terrain looks the same: review frames rendered before and after the terrain change differ by at most 15 pixels, and the grass matches exactly.
- **Jumps no longer depend on frame rate.** Route physics now runs in fixed 1/120 s substeps. Before, a 30 FPS player's big-hill jumps were up to about 20% higher than at 144 FPS. At 60 FPS, jumps are about 5% lower than in v0.16 (Ridgeline 3.4 → 3.2 m, Wild Hills 8.8 → 8.6 m in the route test), matching high-refresh play.
- **Mateo stays visible from the side.** His flat filming artwork turned edge-on in side, orbit and in-engine finale views. It now turns toward the camera around his seat, within ±72°. From the normal chase camera he turns only a few degrees.
- **Trimmed copies launch.** A project copy missing audio, films or generated textures (for example a review ZIP) failed to parse, because hard preloads referenced files that existed only as `.import` entries. Optional media now loads through `scripts/media.gd`: real files always win. Otherwise the game uses silent clips, generated clay/building/cow textures, and the reference sheet embedded in `interceptor-3d.glb`. Nothing is written to disk. The base screen shows a media notice, missing films show **FILM NOT INSTALLED**, and the existing in-engine checkpoint/finale fallbacks play.
- The route hint no longer repeats an on-screen notice on the same topic (for example two AIRBORNE panels).
- The debrief's MATEO'S FOOTAGE button now sits inside the results panel.
- A controller's B or Start button closes the title-screen storm film.

## Merge with your full project

This package contains code, shaders, documentation, tools and the smaller assets from the handoff ZIP. It does **not** contain `assets/audio/*.wav`, `assets/cinematics/**/*.ogv`, `assets/art/terrain/*.png`, `assets/art/truck-poses/*.png` or `assets/art/{building-materials,flying-cow,flying-semi,tornado}.png` / `interceptor-reference.jpeg` or the `assets/models/interceptor-3d_*.png` textures that Godot extracts from the truck model. It never places files at those paths.

1. Copy your complete v0.16.0 `Storm-Chaser` folder to a new folder, for example `Storm-Chaser-v0.17`.
2. Extract this ZIP over that copy and replace existing files.
3. Open `project.godot` with Godot 4.5.2 and let it finish importing. The base screen should not show the media notice.

Saves stay compatible in both directions: v0.16 ignores the new `[garage]` section.

## Verification

See `VALIDATION-v0.17.0.md` for suites, counts and limits. Physical Windows / Galaxy Book2, controller and TV testing is still needed; captures in this round used Linux with software rendering.
