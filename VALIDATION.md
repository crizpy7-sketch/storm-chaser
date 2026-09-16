# Validation of Final Impact / 0.6.0

Engine: official Godot 4.5.2 stable. Rendering: Compatibility / OpenGL, 1280×720, Mesa llvmpipe software rendering. Windows is cross-exported from this source and has not been executed on Windows here.

## 0.6 collision and terminal-state checks

Seventeen final-crash checks pass: fragment emission and hit slowdown, paused/resumed particles, Calm FX reduction, fatal-crash entry, cancellation of a queued dodge reward, frozen chase state, duplicate-loss protection, safe skip without probe deployment, clean restart, normal radar-loss debrief, normal victory, missing-media fallback, decoder timeout, focus-loss exit, pause/resume protection and return-to-base cleanup.

The 28 gameplay checks and 36 dodge-film checks also pass. The old test expecting immediate results on fatal damage was updated to require the new active final-crash state and cancellation of the dodge reward. An initialization-order error in camera feedback was found and fixed before the final runs.

The preview uses staged hazards in the actual game so all four object materials and the last collision are visible. The staging only chooses obstacle timing and lanes; damage, invulnerability, scoring and final-state transitions run through the ordinary gameplay code.

## 0.6 rendered playback

The actual Godot preview registered five staged collisions, entered CRASH at zero hull, decoded the full final film through 8.0167 seconds, and naturally entered RESULTS with GAME OVER. The impact frame and final wreck-backed result screen were inspected. A remaining driving dashboard behind Game Over was removed, and the ending now stops the truck state and shows the wreck with only the results panel. The complete gameplay-to-film-to-results capture was repeated after this correction. The completed Higgsfield film was reviewed in a contact sheet before embedding. Windows, Linux and Web exports completed without export errors. Windows execution and Web browser testing remain unverified.

The 28-second preview is rendered at 60 fps offline, so it does not establish real-time performance on player hardware. Existing shutdown resource-reference warnings remain; no script or shader errors occurred in the final capture.

## 0.5.1 visual verification

Rendered the four character poses in the actual OpenGL scene and inspected the color match. The shader compiles without errors. The blue clothing is subdued, skin remains readable, and the lower-body shading matches the dark truck bed. Gameplay behavior is unchanged; the previous functional results below apply to the underlying v0.5 system. No new behavior tests were added for this material adjustment.

## Gameplay

### Mateo animation

All **ten character checks** passed: attachment to the truck, counterlean and reversal, airborne-object tracking, semi ducking, close-dodge look back, impact bracing, frozen pause animation, restart reset and unchanged health/scoring. The complete 28-check gameplay suite was rerun and passed with Mateo present.

All four poses were captured in a real OpenGL window and reviewed. The character was lowered into the bed after the first capture so his legs sit behind the opaque tailgate. The final material keys cleanly without a visible background and compiles without shader errors.

```bash
godot --headless --path . --script res://tools/test_mateo.gd -- --test
```

The v0.5 preview uses the normal automated driver for 24 seconds at 60 captured frames per second. A contact sheet from the recording was reviewed: the camera pose changes, ducking and look-back reactions remain visible during normal driving. Automatic films are disabled only in this capture script to show continuous live animation. The saved films have not been edited to include Mateo.

The 36-check cinematic behavior suite also passed again in v0.5. Windows, Linux and Web exports completed without export errors. The exported Linux game ran for 180 frames in a real OpenGL window with no script, shader or missing-resource errors. The earlier complete video-decoding checks below were performed for v0.4; the media and playback controller are unchanged in v0.5.

All **28 functional checks** passed. They cover probes and tracking range; single-hit collisions and temporary invulnerability; supplies and near misses; pause, upgrades, restart and loss conditions; turbo acceleration and fast swept collisions; fishtail response, countersteering, level world-space wheels and settling; overhead flyby collision separation; one-shot lens strikes and pause/reset behavior; and the complete mission.

The deterministic 90-second chase finished after 5,401 simulation steps with **67 hull, six probes, five impacts and 13,839 data**. The demo driver follows the same collision, health and probe rules as the player. It has no invulnerability or extra-health allowance.

Run the suite with:

```bash
godot --headless --path . --script res://tools/test_game.gd -- --test
```

## Real-window controls

The underlying Skyfall controls were previously verified by driving the actual Godot window with keyboard and mouse: title opens; Storm Film plays and advances; Escape returns from the film; Enter starts; C hides and restores the HUD; A/D steer; W boosts above 200 mph; Escape pauses; the timer remains frozen; Resume works; M toggles sound; the Pause button works; Return to Base opens the title.

Physical controllers, touchscreens and Windows hardware were not tested here. The Web export is supplied but has not been browser-tested.

## Cinematic rewards

All **36 new functional checks** passed. These cover six bundled media resources; four road-item mappings; the clearance delay; a frozen chase during playback; audio handoff; Space skipping without transmitting a probe; resumed simulation; general and per-item cooldowns; the three-film cap; canceling after damage, stage change or game over; excluding supplies; both actively steered overhead-pass mappings; no unattended-flyby reward; the Off setting; focus-loss pause; restart; unavailable-media fallback; and gallery return paths.

All **21 rendering/playback checks** passed in a real OpenGL window. Each of the six Theora videos started, advanced through decoded frames, finished naturally without hitting the timeout and returned to the gallery. Synthetic controller events skipped back to driving without advancing the frozen chase; simulation resumed on subsequent frames. A gallery entered from pause returned to pause after focus loss. This is controller-event coverage, not testing with a physical controller.

The title, pause screen, all film overlays and the six-card gallery were captured and reviewed. A TextureRect sizing issue found in the gallery was corrected and its final layout captured again.

```bash
godot --headless --path . --script res://tools/test_dodge_films.gd -- --test
godot --path . --script res://tools/test_dodge_playback.gd --fixed-fps 60 -- --test
```

## Visual and media verification

The truck, weather, sky flybys and lens effects were inspected in Godot captures. Refinement corrected overly bright fields, limited sky coverage, loss of truck detail and instruments obscuring airborne objects. The final view uses mipmaps and 2× MSAA. Vehicle art is on a depth mesh; the semi is a full mesh; the cow and storm are artwork placed in 3D space.

The v0.4 gameplay preview is recorded directly from Godot with the normal automated driver and automatic dodge films enabled. It includes both live game rendering and the pre-rendered celebration overlays actually played by the application. It is not an exact-steering replay demonstration. The six film assets are 1280×720 Theora/Vorbis at 30 fps, five seconds each; their original generated MP4 masters are supplied separately. The original Higgsfield trailer also remains available through the title screen.

Movies are rendered offline using software graphics. A 60 fps movie does not establish 60 fps performance on the player's hardware. GPU/CPU performance, especially on phones and older computers, needs device testing.

Windows, Linux and Web exports completed without export errors. The standalone Linux executable was launched with its embedded assets under an OpenGL display and ran the chase successfully. The source imports and runs without script or shader errors. Some headless tests and forced/movie exits report resource references during process shutdown; gameplay checks pass. This shutdown cleanup remains a follow-up item.

## Scope

This is a complete single-player arcade prototype with three escalating fronts in one prairie environment. It is not an open-world driving simulation, a realistic model of tornadoes, or an exact recreation of every generated film frame. Dodge films are deliberately reusable per-item celebrations. Cinematic flybys remain visual set pieces above the road; ordinary road debris causes damage. Lens cracks clear so they do not permanently obscure play.
