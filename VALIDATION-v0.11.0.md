# Storm Chaser v0.11.0 — Validation

345 checks pass: 21 driving, 27 polish, 176 checkpoints, 71 route and 50 finale. Both normal and assisted campaign simulations remain winnable. The new suite covers the actual lap trigger, approved movie selection, aspect ratio, frozen mission state, final data and hull awards, duplicate callbacks, skips, controller Start pause/resume, focus loss, stopped/stalled decoder fallback, incomplete surveys, checkpoint retry, saved unlocks and nested gallery playback.

The native Linux export is recorded from the end of the playable tornado lap through the approved ending movie, score screen, earned footage gallery, a complete replay and return to results. Both film plays complete naturally. The lap reaches 100%, the survey has 17 probes, and replaying does not change its 49,337 data score or scoreboard. The capture uses the ordinary automated driver and game rules; earlier driving and checkpoint skips happen before the recording highlights. No free score, probes or hull are injected.

Gameplay, the movie, results and earned-gallery frames are visually reviewed. The approved film is 910 × 512 at 30 fps with Theora video and Vorbis sound. It passes a complete decode. Its tiny audio-container padding is preserved. The source edit has not been cropped, enlarged, recolored or given a new soundtrack.

The release preview contains the end of actual driving, the approved movie playing inside the game, results and the unlocked gallery card. It is an offline 1280 × 720, 30 fps capture, not a hardware performance benchmark. The separate full capture also verifies that the earned replay completes naturally.

Godot 4.5.2 exports Windows x86-64, Linux x86-64 and Web packages. ZIP CRCs, source-file hashes and packaged executable hashes are checked during packaging; the build manifest records those results and the preview's full-decode result. The source includes this validation suite, capture script and release notes.

Windows/Galaxy Book2, a real television, physical controllers, Web browsers, mobile multitouch and phone vibration still require device testing. No Android or iOS package is included. Known Godot shutdown resource messages remain; there are no gameplay script errors or shader compilation failures in the successful test/capture logs.
