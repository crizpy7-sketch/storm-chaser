# Version 0.8 validation

Tested with Godot 4.5.2, GL Compatibility and Mesa software rendering.

## Behavioral checks

- verify_driving.gd: 21 checks passed, zero failures. Covers audio resources and variations, loop setup, open routes around puddles, one splash per patch, actual lateral sliding, speed and tire-upgrade effects, brake/countersteer recovery, bounded rapid steering, level wheels with zero roll, paused physics, checkpoint/retry/menu reset and vibration-off behavior.
- verify_checkpoints.gd: 46 checks passed, zero failures. Covers both film resources, audio pause/restore, frozen gameplay, finish/save/skip behavior, safe handback, keyboard/controller/touch skip events, focus loss, decoder fallback/watchdog, retry state and a complete mission.
- The normal-rule 90-second simulated mission reached both fronts, transmitted six probes and finished with 100 hull and 14,300.67 DATA. No extra score, health or probes were granted. This is one deterministic test run, not a difficulty guarantee for every player.

## Rendered gameplay

The 20.03-second driving capture uses controller inputs to enter naturally generated puddles, with ordinary collision and damage rules. Four water hits occurred; the truck retained 12 hull at the end. The inspected frames show Mateo, horizontal yaw, splashes, the overhead semi/cow, lens strikes and bottom-corner instruments. This demonstration deliberately pursues puddles and does not try to avoid every obstacle.

The 28.03-second checkpoint capture records the actual game with unshown driving simulated between chapters. The barn film started at capture time 4.16 seconds and returned at 10.22; the warehouse started at 14.36 and returned at 20.43. Both completed naturally without a fallback timeout. The mission then reached CHASE COMPLETE with six probes and 14,299.27 DATA. Score differs slightly from the headless run because of timestep/capture timing.

The combined 48.07-second preview contains these two captures in order. It includes live Godot rendering and the actual prerecorded film overlays played by the application; it is not a newly generated trailer or an exact-player replay.

The driving preview's measured average audio level was -19.3 dBFS, with a -2.2 dBFS maximum after AAC encoding; no clipping was measured. Audio source files decode successfully and were peak-normalized with loop boundary smoothing. Sixty-two ElevenLabs takes were generated across nineteen categories; rejected extra variations were not retried. IDs and reported costs are preserved with the original audio pack.

## Platform limits

Windows and Linux native exports and a Web PCK were built with the matching Godot 4.5.2 release runtimes. The standalone Linux executable also ran a 180-frame chase in the real OpenGL renderer without gameplay script or shader errors. Windows execution, Web browser behavior, physical controllers, touchscreen multitouch and phone haptic strength remain untested on devices. The Android preset is setup only, with VIBRATE permission enabled; no Android/iOS application has been built or signed here.

Rendering was offline using a software GPU. A 30 fps movie does not establish 30 fps on a Galaxy Book2 or phone. Normal unsupported-driver messages and pre-existing shutdown resource-reference warnings remain in some test/movie exits; no gameplay script or shader errors occurred in the captures.

Older VALIDATION.md notes are historical and describe prior source-only checks that were not available after recovery. Use the included v0.8 tests for this source package.
