# Storm Chaser v0.12.0 — Validation

358 automated checks pass: driving 21, polish 27, checkpoints 176, route 71, finale 50, weight 13. Normal and assisted full-campaign completion checks pass. New motor tests agree at 30/60/120 Hz; boost from 112 displayed mph reaches 221.51 after three seconds. Straight landing, crooked landing, suspension travel/settling, recovery and motor resets are checked.

Windows, Linux and Web exports were built with Godot 4.5.2 official release templates. Native Linux gameplay is recorded at 1280×720, 30 fps with audio; recording uses isolated stage selection, not a full campaign. Existing end movies are unchanged. Render capture uses software graphics and is not a real-time performance claim.

Cristian playtested the previous Windows release. This release still needs his laptop/controller/speaker feedback. Physical gamepad vibration, phone haptics and Web performance cannot be established by headless tests. A known resource-cleanup warning can appear when the capture harness exits; gameplay/script/shader errors are checked separately.

Research and implementation details: research/Heavy-Truck-Research.md. Test logs: validation/v0.12.0.
