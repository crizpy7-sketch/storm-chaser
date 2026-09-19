# Storm Chaser v0.10.2 — Validation

98 checkpoint checks pass, including all four movies, mission freezing, audio restoration, safe skips, decoder fallbacks, duplicate-finish protection, save/retry, both route replay unlocks, gallery pagination, persistence and earlier-save migration. Both route movies are explicitly checked to continue beyond the old 2.8-second preview deadline, preserve their supplied aspect ratios, and fall back to the road rather than a warehouse scene.

49 route checks pass, including curves, the sharp-right shortcut, airborne hills, landings, the full tornado circle, finale, checkpoint retry and older-save compatibility. A standard automated campaign again reaches all seven checkpoints and completes with 17 probes and approximately 49,537 data using normal rules. Unchanged driving/polish suites passed in v0.10.0; they were not rerun for this movie-only update.

The supplied 898 × 512 H.264/AAC video is converted at its native resolution and 30 fps into a six-second Theora/Vorbis game asset. The original stereo sound is retained with short entry/exit fades. The in-game player fits its aspect ratio instead of stretching the truck. No new generation credits were spent.

The short release preview shows the movie in the exported Linux game, its natural completion, level-five driving through the right turn and onto dirt and the unlocked gallery. The supplied movie is prerecorded Grok footage; the driving segment is actual Godot gameplay. Offline capture does not measure device performance.

Windows/Galaxy Book2 hardware, web browsers, mobile devices, multitouch and vibration still need device testing. No mobile package is included. Pre-existing ObjectDB/resources-in-use warnings occur at engine shutdown; no runtime script or shader failures were found in the checks.
