# Storm Chaser v0.10.5 — Validation

243 checks pass: 21 driving, 27 polish, 124 checkpoints and 71 route checks. The checkpoint suite now exercises all five films and all three supplied route movies. It verifies selection, frozen gameplay/scoring, natural-finish handling, safe return, skip controls, sound restoration, save/retry behavior, fallback, aspect ratio, earned replay, gallery pagination and earlier-save unlocks. Normal and assisted full-campaign checks pass.

The route suite retains the perpendicular-junction mesh check, hard asphalt/mud seam, steering recovery, rigid truck geometry, lens splash clearing, airborne handling and finale checks. This integration does not retune driving or road geometry.

The supplied third route movie is prepared as a six-second 898 × 512, 30 fps Theora/Vorbis stream. Video and audio are fully decoded to check for errors. Native playback is recorded from the exported Linux game and must finish naturally into level six, demonstrate a launch and landing, and show checkpoint 05 unlocked. The movie, driving and gallery frames are visually reviewed.

ZIP CRCs, source contents and packaged binaries are verified. The H.264/AAC preview receives a complete decode check before delivery. Windows/Galaxy Book2 hardware, browser performance and mobile controls/vibration still need device testing. No Android or iOS package is included. Known engine shutdown resource messages remain; gameplay script errors and shader compilation failures block delivery.
