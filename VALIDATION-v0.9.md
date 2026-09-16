# Storm Chaser v0.9 — Validation

## Automated game checks

Godot 4.5.2 headless, isolated test settings; no production save files modified.

- `verify_driving.gd`: 21 checks passed. Real lateral aquaplaning, restraint and continuity of fishtail yaw, speed-scaled water kick, countersteering/braking, grip upgrade, pause/reset, audio variants and vibration-off behavior.
- `verify_checkpoints.gd`: 46 checks passed. Correct movie selection, playback-finished signal, keyboard/controller/touch skip, focus-loss pause, stopped/stalled decoder fallback, safe return, snapshot restoration, duplicate-finish protection, score integrity and a complete normal three-front mission.
- `verify_polish.gd`: 27 checks passed. Wheel steering/rotation, bounded suspension, hull-linked damage/repair, recovery and reaction-time assists, permanent assisted-run label, quiet intervals, bounded water pool, lighter graphics, gallery locks/unlocks, gallery state isolation, setting persistence, character-line cooldown and an assisted completion that can earn all footage.

**Total: 94 passing checks.** Source includes the verification scripts. Run them with `--headless --path <project> --script res://tools/verify_driving.gd -- --test`, substituting the other script paths for their suites.

## Rendering review

The game was rendered at 1280×720 and 30 recorded frames per second using Godot Movie Maker and software OpenGL. The controller capture follows normal driving, boost, damage, probe and upgrade rules; it deliberately crosses the first puddle, then chooses safer lanes. Health and scoring are not overridden. Automatic dodge films are disabled for this capture so the driving and checkpoint movies remain visible.

The full review chase reached both checkpoint movies, unlocked both gallery entries, and finished with 15,300 data and 100 hull. Gallery thumbnails, the bottom dashboard, checkpoint approach, and all seven settings rows were visually inspected. The final shorter showcase records the revised lamps, roof reflector and batched roadside geometry, through the first checkpoint and into the gallery/settings screens. It is edited gameplay, including the game's existing prerecorded checkpoint reward movie.

The chapter movies retain their original subject matter. Their color pass uses a separate vertex tint so the sampled movie color is not multiplied by itself; see the [Godot 4.5 canvas shader reference](https://docs.godotengine.org/en/4.5/tutorials/shaders/shader_reference/canvas_item_shader.html#color-and-texture).

## Build checks and limits

Windows, Linux, Web and editable source are packaged separately. Every ZIP is completely closed and its CRCs checked before saving. The source ZIP identifies version 0.9.0 and uses ordinary Godot export-template settings; local custom template paths are removed from the source deliverable. Font and Godot license notices are included. The matching Godot 4.5.2 Web runtime is retained and its PCK size entry is updated.

The exported Linux executable is checked for startup and rendering separately from the editor project. Windows export, Web export, and source packaging are verified structurally; this does not substitute for running on the user's devices.

**Not device-tested:** Galaxy Book2, Windows hardware, browsers, native Android/iOS, handheld vibration and simultaneous phone touch input. The video is an offline render, not a real-time frame-rate benchmark. No signed mobile binary is included.

The headless test runner still reports ObjectDB/resources-in-use warnings during engine shutdown. No script, material or shader compile errors are accepted in the final render or export logs. Shutdown cleanup is a remaining maintenance item.

## Asset provenance

- Existing local truck, character, storm and cinematic assets are retained. The truck's old shallow image mesh is replaced by rigid 3D assemblies and panel texture mapping.
- No new Higgsfield generation was used for this release.
- ElevenLabs generated three brief synthetic character reactions (10 successful takes total; one take selected per line). Two additional variations were rate-limited and not retried. Completed-take records report 159.984 credits in total; failed jobs are listed separately in the voice manifest. No claim is made about final account billing beyond those returned records.
- The desktop game uses only local assets at runtime; it has no generation-service dependency or API key.
