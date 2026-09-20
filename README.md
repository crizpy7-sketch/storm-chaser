# Storm Chaser

The current source adds a persistent DATA wallet, cosmetic purchases, eight badges, and earned chase setups to the Storm Grade game. Completed and failed runs both bank DATA; retrying the same run banks only its additional score. Existing saves keep their equipped parts and setups.

Timed stages last 90 seconds, with save flags every 30 seconds. A flag preserves its repair and DATA reward as well as progress along the road. Controller buttons and triggers work with any connected device ID. The optional Storm Link chooses among existing recorded voice lines and falls back to local decisions when unavailable; see `STORM-AI.md`.

Run the Godot checks with `GODOT=/path/to/godot tools/run_suites.sh`, packaging regressions with `python -m unittest discover -s tools -p 'test_package_release.py'`, and runner regressions with `bash tools/test_run_suites.sh`. The GPU transparency check requires a graphical renderer: `godot --path . --script res://tools/check_storm_render.gd`.

## v0.18.1 — Storm Grade

The 3D chase now has a storm-grade look: lower ambient so the truck plants a real contact shadow, lightning that actually lights the world, a crossed tornado with a dust foot, wet asphalt and prairie grass tiles, and rain that recedes down the road. Handling, campaign and films are unchanged from v0.18.0 Weight.

# Storm Chaser v0.17.0 — Mateo's Garage

**Mateo's Garage** opens from the base over the live 3D truck. It has five cosmetic slots: paint accents, wheels, roof equipment, bumper armor and suspension trim. Each slot starts on the approved stock part, and **STOCK LOOK** restores all of them. A separate, optional **chase setup** (Stock, Rally, Armored, Turbo) is the only performance choice, and Stock keeps the original tune. The loadout is saved, shown in Mateo's Footage, and labeled on the scoreboard when a non-stock setup is used.

This release also makes the three hill levels much cheaper to run, and the terrain looks the same. Jump height no longer depends on frame rate, and Mateo stays visible from side and orbit cameras. Trimmed project copies that lack the audio/film media now launch. Full details, the merge steps for your media folders, and the limits are in `README-v0.17.0.md` and `VALIDATION-v0.17.0.md`.

v0.16.0 added swept solid debris impacts and the roadside shelter corridor (`README-v0.16.0.md`). v0.15.0 added the storm damage corridor: ruined homes, splintered trees, fences, fires and the breaking semi (`README-v0.15.0.md`). The approved truck mesh, Mateo, the campaign and the cinematic films are unchanged.

## Play the campaign

| Level | Route | New challenge | Cruise |
|---|---|---|---:|
| 1 | Prairie Approach | Wet highway, debris and puddles | 146 mph |
| 2 | Barn Breakout | Barn destruction checkpoint, timber and roofing | 162 mph |
| 3 | Warehouse Collapse | Warehouse checkpoint, concrete and steel | 178 mph |
| 4 | Crosswind Curves | Repeated bends push the truck toward the outside shoulder | 146 mph |
| 5 | Dirt Shortcut | A marked ninety-degree right turn leaves the closed highway for narrower dirt and small hills | 122 mph |
| 6 | Ridgeline Jumps | Larger crests launch the truck; sideways landings break traction | 136 mph |
| 7 | Wild Hills | Large jumps and curves together, with less grip | 148 mph |
| 8 | Vortex Run | Follow a full circle around the tornado, then get pulled into it | 112 mph |

The first seven levels last 90 seconds of active driving each, with a save flag every 30 seconds. Upgrades, checkpoint previews and celebration videos freeze progression. The final level advances by actual route distance: approach the tornado and complete the circle at your own speed. It has no countdown that can end the lap early.

Survive to the vortex and transmit at least **three probes** for a completed survey. The suction finale still plays if you arrive with fewer probes; the debrief then reports an incomplete survey and offers a checkpoint retry. Mateo stays with the truck and braces during jumps and landings in gameplay. The finale is the approved prerecorded sequence, which plays before the survey results. If video playback fails, the existing in-engine suction sequence completes the run.

## Controls and handling

- **A/D or arrows:** steer. **W / Shift / Up:** boost, up to 240 mph. **S / Down:** brake.
- **Space:** transmit a charged probe while in range. **P / Escape:** pause, including during the ending movie. **Space / Enter / controller A, B or X** skips the ending; the earned final transmission is still counted.
- **T:** touch controls. **M:** mute. **C:** hide the driving HUD. **F11:** fullscreen.
- Controller: left stick / D-pad steers, A boosts, B brakes, X transmits, Start pauses.
- **Mateo's Garage** (base screen): Up/Down select, Left/Right change, Q/E or drag to orbit, R stock look, Enter start, Escape back. Controller: D-pad or stick, LB/RB orbit, Y stock look, A or Start to start, B back.

Brake before a tight curve, hold steering against the outward drift, then accelerate out. Dirt reduces grip. Braking over big crests helps keep the tires down; at higher speed the truck follows a ballistic jump and must reconnect with the terrain. Steering is weaker in the air. Land straight to earn data; landing with a large sideways slide can damage the hull and kick the rear outward. High jumps can clear low debris, but cannot collect ground supplies or trigger puddles beneath the truck. Staying on the shoulder too long damages the truck.

Each of seven checkpoints offers repair, grip or boost capacity. The first two play the existing building movies. Checkpoint 03 plays your first route film before Crosswind Curves (level four). Checkpoint 04 plays the second route film before Dirt Shortcut (level five). Checkpoint 05 plays the latest hill-jump-and-drift film before Ridgeline Jumps (level six). The original version remains an earned alternate replay, labeled RIDGELINE / ORIGINAL on gallery page two. Checkpoint 06 plays the fourth before Wild Hills (level seven), showing winding muddy hills, a jump and sliding landing. Checkpoint 07 plays the fifth route film before Vortex Run (level eight). If a movie is disabled or fails, the Godot preview of that route remains available with Mateo in the truck. **Keep Chasing** skips a preview. Retry restores the saved level entrance, hull, upgrades, score and probes, clears airborne/sliding state, and grants no second upgrade or failed-attempt rewards. Existing older checkpoint saves remain compatible.

DATA remains the score. Probes, close dodges, supplies and tracking earn data as before; controlled landings earn 200–450, directly clearing a low obstacle in a high jump earns 125, and the final transmission earns 2,000. A successful survey also awards remaining hull × 20. The local top-five scoreboard identifies retried and assisted expeditions.

## Install

- **iPhone browser build:** open the hosted Web build in Safari, turn the phone sideways, and tap **START CHASING**. Touch controls appear automatically: hold an arrow to steer and use a second finger for boost or brake. Tap **SEND PROBE** when charged. If the phone stays upright, turn off Portrait Orientation Lock. Progress saves in that browser; private browsing or clearing website data can remove it.
- **Windows / Galaxy Book2:** extract the entire Windows ZIP and open `Storm-Chaser.exe`.
- **Linux:** extract the Linux ZIP and run `./Storm-Chaser.x86_64`.
- **Godot:** extract the project ZIP and import `project.godot` with Godot 4.5.2. Install official export templates to export on your own machine. The v0.17.0 source package omits the large audio and film files; extract it over a copy of your complete project (see `README-v0.17.0.md`).
- **Web:** serve the complete Web folder over HTTP(S); opening `index.html` directly from disk is not supported.

The driving/display menu retains optional steering recovery, extra hazard reaction time, lighter graphics, reduced camera effects and Mateo voice controls. Mobile browsers start with lighter graphics unless a saved preference overrides it. Independent touch inputs support steering, boost/brake, probes, sound and pause; cancellation and loss of focus clear held controls. No native Android or iOS package is included. Physical iPhone performance and Safari device behavior still need device feedback. Supported gamepads receive brief impact pulses when haptics are enabled.

The Web preset uses a single thread, mobile-compatible textures and `web/shell.html`. Install Godot 4.5.1 export templates, import the complete project, then export with `godot --headless --path . --export-release Web /absolute/path/to/output/index.html`. Serve the entire output folder over HTTPS. The shell preserves a 16:9 play area inside Safari's safe area and shows a portrait-orientation prompt. The optional large cinematic files can be omitted; the game uses its existing in-engine checkpoint and finale fallbacks. Run `tools/verify_touch.gd` or the complete suite runner to check simultaneous touch inputs.

## Preview and implementation

`Storm-Chaser-v0.12.0-Heavy-Truck.mp4` records actual Godot gameplay with audio, using isolated stage selection to demonstrate acceleration, the dirt shortcut and hill landings. It contains no trailer footage and is not a full campaign run or hardware performance benchmark. The six automated suites pass 358 checks, including normal and assisted campaign completion.


`Storm-Chaser-v0.11.0-Finished-Game.mp4` records the exported Linux game: the end of the playable tornado lap, the full approved ending film, the resulting score and the earned finale card. Earlier stages are simulated by the existing automated driver using ordinary game rules. The film is prerecorded; driving and results are generated by the game. The capture runs offline at 30 fps and is not a Galaxy Book2 performance benchmark.


`Storm-Chaser-v0.10.8-Ridgeline-Drift-Cinema.mp4` begins with the latest supplied film playing in the checkpoint UI, then records actual Ridgeline Jumps driving, launches and landings, and the gallery with both Ridgeline films unlocked. The opening movie is prerecorded; the driving after it uses the game simulation.

`Storm-Chaser-v0.10.7-Vortex-Cinema.mp4` begins with the fifth supplied Grok film playing in the checkpoint UI, then records the actual final approach, complete tornado lap, Godot suction finale with Mateo, survey results and earned gallery entry. The opening movie is prerecorded; the driving and finale after it use the game simulation. The earlier campaign is simulated under ordinary rules.

`Storm-Chaser-v0.10.6-Wild-Hills-Cinema.mp4` shows the fourth supplied Grok route film playing inside the exported Godot game, followed by actual Wild Hills driving and the unlocked footage entry. The opening film is prerecorded; the driving after it uses the game simulation.

`Storm-Chaser-v0.10.5-Ridgeline-Cinema.mp4` shows the supplied Grok film playing inside the exported Godot game, then actual Ridgeline Jumps gameplay and its unlocked footage entry. The opening film is prerecorded; the driving after it is live game logic recorded offline.

`Storm-Chaser-v0.10.4-Hard-Right.mp4` records actual gameplay from the exported Linux build: the perpendicular junction, tight right drift, lens mud impact and the return to a clear view. The existing checkpoint movie is skipped before recording; no prerecorded film appears in this preview.

`Storm-Chaser-v0.10.2-Shortcut-Cinema.mp4` records the second film in Godot, the return to level-five driving, the sharp right turn onto dirt, and the earned gallery entry. Its opening is your prerecorded Grok film; the following driving is actual Godot gameplay.

`Storm-Chaser-v0.10.1-Crosswind-Cinema.mp4` records the supplied film playing inside Godot, the automatic return to level-four driving, and the earned gallery entry. The movie segment is prerecorded Grok footage; the driving after it is actual Godot gameplay.

`Storm-Chaser-v0.10.0-Into-the-Vortex.mp4` is the previous release recording of the actual Godot build, edited to show the new levels. An automated driver uses ordinary game handling, collisions, upgrades and probes. Unshown driving is simulated between highlights; health and earned progress carry through the campaign. Automatic dodge films are disabled for the capture. It is recorded offline at 30 fps, not a device performance benchmark.

The ground, obstacles and puddles follow the driving route. At the shortcut, two perpendicular road rectangles form the junction, while a tight rounded driving line stays within it. The road and truck render in 3D; weather and character art still include illustrated layers, and campaign travel remains route-based. The approved cinematic supplies the immersive final sequence; the earlier 3D spiral remains a playback fallback. This release creates no new AI images, movies or audio and spends no Higgsfield or ElevenLabs credits.

See `VALIDATION-v0.17.0.md` for this release. `research/Heavy-Truck-Research.md` and earlier release notes document historical tuning.
