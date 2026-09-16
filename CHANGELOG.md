# 0.17.0 — Mateo's Garage

- Adds Mateo's Garage at the base: live orbiting 3D preview, five cosmetic slots (paint accents, wheels, roof equipment, bumper armor, suspension trim) with the approved part first, and a STOCK LOOK reset.
- Adds an optional chase setup (Stock, Rally, Armored, Turbo). Each alternative is a trade-off; Stock leaves every handling factor at 1.0. Non-stock setups appear on the scoreboard and debrief.
- Saves the loadout under `[garage]`; older saves load stock. Mateo's Footage and the base screen show the loadout.
- Hill levels: a cached course frame, shared road rows, and GPU-evaluated hill grid and grass heights cut the per-frame view update from 60–76 ms to 5.3–7.3 ms on one test machine (GPU time excluded). Renders match the previous terrain.
- Route physics runs in 1/120 s substeps so jump height is the same at any frame rate.
- Mateo turns toward side, orbit and finale cameras instead of disappearing edge-on.
- Optional media loads safely; trimmed copies launch with in-memory stand-ins and a media notice.
- Removes a duplicated airborne hint, fits the debrief footage button inside its panel and lets a controller close the title film.
- Adds garage and runtime suites and `tools/measure_frame_cost.gd`. Existing suites report media-only checks as skipped in trimmed copies.

# 0.15.0 — Storm Damage Corridor

- Adds ruined homes, lifting roof sheets, splintered trees, broken fences and textured prairie ground along highway and hill routes.
- Splits the flying semi into sixteen rigid sections with metal rupture audio and a trailing fire.
- Adds four roadside flame/smoke/ember sites, with warm local light.
- Preserves truck geometry, driving, collision damage, saves, footage and checkpoint rules.
- Adds 15 scenery/breakup checks; all 407 release checks pass. Preview is actual Godot gameplay. No generation credits used.

# 0.10.8 — Ridgeline Drift Cinema

- Uses the latest supplied hill-jump-and-drift film at checkpoint 05 before Ridgeline Jumps, preserving original sound, speed and proportions.
- Retains the previous Ridgeline film as RIDGELINE / ORIGINAL on gallery page two. Both share the earned checkpoint 05 unlock, including valid existing saves.
- Keeps all seven checkpoint previews, safe movie return, road fallback and the eight-level campaign.
- The existing 295 checks pass; native playback, jumps, landings and both gallery entries are reviewed. No driving changes or generation credits spent.

# 0.10.7 — Vortex Cinema

- Integrates supplied route clip 5 at checkpoint 07 before Vortex Run, preserving original sound, speed and frame proportions.
- Completes the seven-film checkpoint collection and adds the final earned replay on gallery page two, with saved unlocks and valid earlier-checkpoint migration.
- Retains frozen mission time, safe playback/skip/return and the Godot road fallback with Mateo.
- Adds 26 checkpoint checks for 295 total. The playable tornado lap, Godot suction finale, original truck, earlier films and driving upgrades remain. No generation credits spent.

# 0.10.6 — Wild Hills Cinema

- Integrates supplied route clip 4 at checkpoint 06 before Wild Hills, preserving original sound, speed and frame proportions.
- Adds the sixth earned checkpoint replay on gallery page two, with saved unlocks and valid earlier-checkpoint migration.
- Retains frozen gameplay, safe playback/skip/return and the Godot road fallback.
- Adds 26 checkpoint checks for 269 total. All prior driving, mud, truck, route and movie upgrades remain. No generation credits spent.

# 0.10.5 — Ridgeline Cinema

- Integrates supplied route clip 3 at checkpoint 05 before Ridgeline Jumps, preserving sound, speed and frame proportions.
- Adds the fifth earned checkpoint replay on page two of Mateo's Footage, with saved unlocks and earlier-checkpoint migration.
- Retains frozen gameplay, safe skip/return and the in-engine road preview fallback.
- Extends checkpoint coverage by 26 checks; all 243 checks pass. Square junction, mud lens splash, truck style and driving remain unchanged. No generation credits spent.

# 0.10.4 — Hard Right

- Replaces the sweeping exit with two perpendicular roads, a square junction and a hard asphalt/mud boundary.
- Tightens the playable right turn to a fourteen-unit radius, retaining steering recovery, braking and the original rigid truck.
- Adds mud flying onto the lens, wet splats, drips and automatic clearing; muddy puddles can also splash the camera.
- Raises the approach view to reveal the junction. Calm FX, pause and checkpoint reset handle the new effect.
- Adds fourteen junction/lens checks for 217 total gameplay checks. All existing movies, saves and levels remain. No generation credits spent.

# 0.10.3 — Mud & Drift

- Tightens the right-hand shortcut and releases setup braking earlier, adding sustained but controllable rear slide, muddy tire spray, skid audio and a restrained drift camera.
- Keeps the original truck mesh, smooth yaw limit and upright body; Mateo stays in the bed.
- Replaces almost-black dirt with lighter brown clay, wet ruts, puddled reflections and mud-colored splash sheets. Mud begins at the turn entry.
- Smooths field noise, prevents wide terrain strips folding around the tight turn, and textures the closed highway spur as asphalt.
- Adds eight targeted turn/terrain checks; all 203 gameplay checks pass. Existing films and saves remain compatible. No generation credits used.

# 0.10.2 — Shortcut Cinema

- Adds the second supplied Grok film at checkpoint 04, before Dirt Shortcut, preserving sound and frame proportions.
- Unlocks its persistent replay alongside the first route film on the second gallery page; earlier checkpoint-04-and-later saves qualify.
- Retains frozen gameplay, natural film completion, safe skip/return and road-preview fallback.
- Preserves all eight levels and existing handling/art/audio. No generation credits spent.

# 0.10.1 — Crosswind Cinema

- Integrates the first supplied route film at checkpoint 03 before Crosswind Curves, preserving its sound and frame proportions.
- Lets decoded playback finish before restoring driving; retains skip, focus-loss, checkpoint saving and safe-entry protection.
- Uses the road/Mateo preview if the route movie is disabled or fails, without spawning a destruction scene.
- Adds an earned, persistent replay and gallery pagination for all nine films. Existing checkpoint-03-and-later saves unlock the new clip.
- Preserves the v0.10.0 route, original truck and gameplay. No generation credits used.

# 0.10.0 — Into the Vortex

- Extends the three existing chapters to eight, with seven saved retry checkpoints.
- Adds physical outward curve drift, a ninety-degree right shortcut, dirt grip, small hills, ballistic big jumps, landing slides and combined curves/crests.
- Uses shared route geometry for road, terrain, obstacles, puddles and shadows, with gravel/wood hazards off-road.
- Adds braking cues, per-level progress, a distance-based tornado lap, and a paused/resumable in-engine suction finale featuring Mateo.
- Preserves the original truck and rolling tread; Mateo braces and the suspension compresses on landing.
- Retains old checkpoint films, dodge rewards, audio, impact/game-over sequence, settings and local scoreboard. Supports older checkpoint saves.
- Uses existing assets; no generation credits spent. Includes fresh actual-game highlights.

# v0.9.2 — Rolling Tires (2026-09-14)

Animated the original pickup's visible rubber tread with distance-driven scrolling and speed-sensitive blur. The body and tire silhouette remain fixed. Pauses and cinematic playback freeze the animation; a new chase resets it. Recorded curves, off-roading and mini hills as the next requested upgrade.

# v0.9.1 — Original Truck Style (2026-09-14)

Restored the original detailed orange pickup artwork and fixed depth mapping at Cristian's request. Preserved smooth gliding, bounded spring motion, Mateo, the layered water, hazard cues, checkpoint gallery, sound, assists and performance settings. Damage now adds surface scuffs and taillight flicker to the original art without deforming it. See README-v0.9.1.md.

# v0.9 — Field Polish (2026-09-14)

Rigid textured 3D truck with independent wheels and suspension; water sheets, mist and lens droplets; hazard shadows and early pass cues; calm stretches and landmark anticipation; persistent checkpoint footage gallery; visible hull wear and engine roughness; three brief voiced Mateo reactions; saved driving assists and lighter graphics. Existing checkpoint movies receive a restrained color pass and smooth return. See README-v0.9.md.

# Changes

## 0.8.1 — Smooth glide

- Replaced the extreme heading swing with a damped fishtail capped at 7.5 degrees.
- Reduced the puddle's rotational kick while keeping its sideways glide and brake/countersteer recovery.
- Smoothed heading changes separately from lateral travel to prevent the rear-view depth artwork from looking twisted during quick reversals.

## 0.8.0 — Water & Thunder

- Increased speed-sensitive horizontal fishtailing and steering momentum; truck roll remains zero.
- Added reflective avoidable puddles, speed-sensitive traction loss, sideways glides, large spray bursts and brake/countersteer recovery. Better tires reduce water kicks.
- Integrated the two supplied six-second Grok checkpoint movies, with frozen gameplay, audio handoff, save/skip protection and the existing Mateo scene as a decoder fallback.
- Replaced the gameplay effects and chase score with nineteen ElevenLabs audio categories and multiple one-shot variations; added loop seam smoothing and a peak limiter.
- Added short mobile vibration pulses for puddles and collisions, a saved toggle and an Android export setup preset with vibration permission.
- Recovered all nine scripts from the intact release and restored available original art/audio files before applying this update.

## 0.7.0 — Destruction Checkpoints

- Added Barn Breakout and Warehouse Collapse fronts with two 8.6-second Godot destruction cinematics: tornado approach, roof lift, slow-motion breakup, dust, large close passes and a smooth return to chase view.
- Mateo records each collapse from the actual truck bed, then ducks for flying panels. His storm color grade and level-wheel fishtail are preserved.
- Added generated weathered barn, roofing, concrete and steel textures shared by the source buildings and their matching road hazards. Impact fragments inherit the building palette.
- Increased later-front debris travel speed in addition to cruise speed, spawn frequency, adjacent waves and crosswind. Every wave leaves an open side of the road.
- Saved post-upgrade checkpoints at 30 and 60 driving seconds. Retry restores the entry state without banking failed-attempt rewards or repeating upgrades. Continue works after restarting the app.
- Added safe cinematic skips, frozen gameplay, focus-loss pause and a clear road on handback.
- Added a persistent local top-five board, one row per expedition, retry labels and score explanations on the title screen.
- Added 33 checkpoint checks; 124 total behavioral checks pass, including a complete simulated mission and previous dodge, crash and Mateo regressions.

## 0.6.0 — Final Impact

- Added powerful collision feedback: fragments, sparks, radial streaks, smoke, camera kicks, a short time punch and layered metal/low-frequency impact sound. Crates and roofing break into fragments; tires and barrels ricochet.
- Added critical-hull smoke and warning feedback. Calm FX reduces fragments and removes the time punch and aggressive visual effects.
- Added one eight-second Higgsfield final-crash cinematic after hull reaches zero. The chase freezes, the film plays once, and GAME OVER opens over the wreck tableau.
- Added keyboard, controller and touch skip; safe focus-loss exit; missing-media and decoder-timeout fallbacks; clean restart; and priority over queued dodge celebrations.
- Wins and non-damage losses retain their normal debrief. The final film is a reusable cinematic, not a reconstruction of the exact collision.

## 0.5.1 — Storm lighting match

- Matched Mateo to the storm palette with muted blue/teal clothing, cooler fill light and lower exposure.
- Added a soft shadow toward the truck bed and a restrained response to existing lightning; Calm FX suppresses that response.
- Preserved his generated artwork, likeness and animation; the color treatment runs in the character material.
- Reviewed the updated character in rendered gameplay and re-exported the playable builds.

## 0.5.0 — Mateo Storm Cam

- Added Mateo to the truck bed with four original camera-operator poses matched to his supplied photo.
- Added continuous counterlean, breathing and camera vibration tied to the truck's motion, with smooth pose transitions.
- Added upward camera tracking for airborne debris, ducking under the semi, impact bracing and a look back after close dodges or probes.
- Added a small bottom-center storm-camera recording indicator, reduced motion under Calm FX, and pause/restart handling.
- Kept the tailgate in front of his lower body so he sits inside the truck bed. Vehicle steering, damage, rewards and controls are unchanged.
- Added ten character behavior checks and a 24-second actual-game preview. Existing prerecorded cinematic footage remains unchanged.

## 0.4.0 — Cinematic Dodges

- Added six reusable five-second Higgsfield films: crate, barrel, tire, roofing sheet, semi and cow. These celebrate the obstacle cleared without claiming to reconstruct the player's exact maneuver.
- Added matching road-dodge and clean, actively steered overhead-pass triggers, a brief clearance delay, per-item repeat protection, 20 seconds between films and a three-film limit per chase.
- Added frozen-state playback, automatic return, keyboard/controller/touch skip, audio handoff, safe focus-loss pause and a decoder timeout fallback.
- Added a six-film gallery and persistent automatic-film setting on the title and pause screens. Films play locally and require no service access.
- Kept the bottom instruments, 240 mph turbo, physical road collisions and full three-front mission.
- Added functional reward checks and real-renderer playback checks for all six bundled Theora files.

## 0.3.0 — Skyfall 3D

- Replaced the chase view with a low 3D camera, curved wet highway, passing poles, wires, reflectors and wind turbines.
- Replaced truck body roll with a damped fishtail and countersteer response. The wheels remain level in world space.
- Preserved the detailed truck artwork on a depth mesh; included editable pickup and semi geometry authored in Higgsfield 3D Jutsu.
- Added an enormous tumbling 18-wheeler and airborne cow with heavy passing sounds.
- Added camera strikes, short impact kicks, temporary lens cracks, shards and water.
- Added skid audio and more tire spray; moved instruments to the lower corners. C toggles an unobstructed cinema view.
- Added the labeled Higgsfield cinematic to the title screen with skip/return controls.
- Retained the complete 90-second mission, upgrades, supplies, damage, probes and 240 mph turbo.
- Added fishtail, settling, lens, pause and restart checks.

## 0.2.0 — Adrenaline

- Cruise speed rises across the three fronts: 146, 162 and 178 mph. Turbo reaches 240 mph.
- Sharper steering and faster acceleration make dodges immediate. Braking remains available for tight situations.
- Debris approaches in roughly half the original time, grows larger, spins faster, lifts off the road and continues past the camera.
- Amber road markers preserve readable hazard paths. Collisions still register once per object at high speed.
- Steering body roll, boost camera pullback, faster road texture, heavy tire spray and peripheral streaks strengthen the sense of motion.
- New turbo audio, stereo passing whooshes and a faster 138 BPM soundtrack support the action.
- Calm FX reduces added camera motion and disables streaks, trails, shake and flashes.
- The demo driver anticipates faster hazards and spaces out turbo bursts. It uses the same gameplay rules as the player.
- Functional checks expanded to cover fast collisions, boost acceleration and frozen pause feedback.
