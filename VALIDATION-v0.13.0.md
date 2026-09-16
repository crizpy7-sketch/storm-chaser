# Storm Chaser v0.13.0 validation

371 checks pass across driving (21), polish (27), checkpoints (176), route (71), finale (50), weight (13), and storm art (13). Existing normal and assisted campaign completion is covered. New checks cover seven pose textures, steering/drift/flight/compression selection, reset, suction motion, paused scene time and reduced graphics counts.

An exported Linux capture shows all eight truck views with actual game logic across selected stages. It uses scripted steering followed by the automated driver. The cinematic funnel is rendered in the game, with a subdivided mesh for wind sway, keyed image color, separate dust and 24 looping suction objects. These are environmental visual effects, not a fluid simulation or new collision hazards.

Windows, Linux and Web builds use Godot 4.5.2. This upgrade still needs a Galaxy Book2 playtest for subjective feel and performance. Offline software-rendered capture is not a frame-rate benchmark. A known resource cleanup warning appears when the capture/test harness exits; no gameplay script or shader errors are accepted.
