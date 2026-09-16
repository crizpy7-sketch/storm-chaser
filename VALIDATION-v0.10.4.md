# Storm Chaser v0.10.4 — Validation

217 gameplay checks: 21 driving, 27 polish, 98 checkpoints and 71 route checks. These cover normal and assisted campaign completion, movie mappings, replay persistence and save compatibility.

The new junction checks measure both the actual rendered road axes and the driving route: the highway and mud road are perpendicular, their surface colors have a hard seam, the tight driving line remains inside the junction, and the outgoing road connects continuously to the later terrain. The truck's original vertex array and smooth 0.13-radian yaw limit remain unchanged. Steering can recover the lateral slide; braking reduces its force.

Lens checks cover muddy versus asphalt puddles, a visible impact, retrigger cooldown, pause, natural clearing, airborne suppression and reset. Calm FX reduces the effect without changing steering or damage rules.

Visual review covers the straight approach, square junction, right drift, wet lens splats and clearing. The release preview runs the exported native Linux game and includes no AI film segment. Package ZIP CRCs, source contents, native binary matches and complete video/audio decoding are checked before delivery.

Windows/Galaxy Book2 hardware, browser performance, Android/iOS and phone vibration still need device testing. No mobile package is included. Known engine shutdown messages about ObjectDB/resources in use are not accepted as evidence of runtime failure; gameplay script errors and shader compilation failures block delivery.
