# Storm Chaser — handoff back to ChatGPT

You built Storm Chaser through v0.17.0. Claude did one pass on top of it,
released as **v0.18.0**, whose single goal was: *make the truck feel heavy —
the steering, the landing, the actions, the strikes.*

This document is written so you can pick the project up cold. It assumes no
memory of the conversation that produced v0.18.0.

---

## 1. Where the work is

| | |
|---|---|
| Repo | `crizpy7-sketch/storm-chaser` |
| Branch | `claude/game-polish-feel-dgm10c` |
| Pull request | #1 (open, **draft**, mergeable, CI green) |
| Base | `main`, which contains only a README — the game itself lands in this PR |
| Version | 0.17.0 → **0.18.0** |
| Engine | Godot **4.5.1 stable**, GL Compatibility renderer |

The PR contains the entire v0.17.0 project as its first commit, unmodified, so
every later commit is a reviewable diff against your original. The baseline
commit is `a54de05`.

**The game code changes are small and concentrated.** Ignore the file count;
551 files are the imported project. Only these were touched:

```
scripts/main.gd        +156 / -~40   driving, impacts, audio, notifications
scripts/world3d.gd      +84          camera
scripts/truck_rig.gd    +51          suspension, landing attitude
scripts/crashes.gd      +49          impact response, hit stop, impact audio
scripts/hud.gd          +49          dashboard
scripts/route.gd        +31          landing severity, airborne pitch
tools/verify_road_margin.gd  +7      one test, see section 5

NEW: tools/measure_feel.gd      telemetry probe
NEW: tools/run_suites.sh        runs all 15 suites
NEW: .github/workflows/verify.yml   runs them on every push
```

No art, model, texture, shader, audio or cinematic asset was added, removed or
regenerated. No media-generation credits were spent.

---

## 2. How to verify anything in this document

```bash
# All 15 suites. Exits non-zero if any check fails or any suite crashes.
GODOT=/path/to/Godot_v4.5.1-stable_linux.x86_64 tools/run_suites.sh

# The feel numbers. Asserts nothing; prints the measurements.
$GODOT --headless --path . --script res://tools/measure_feel.gd -- --test

# Rendered stills from actual gameplay (needs a display; Xvfb works).
STORM_CAPTURE_DIR=/abs/path $GODOT --path . --script res://tools/capture_review.gd -- --test
```

Current state: **520 checks across 15 suites, 0 failures.** The same 520 pass on
your unmodified v0.17.0 baseline, so v0.18.0 added no coverage and removed none —
it changed behaviour that your existing tests already guarded.

---

## 3. Why the truck felt light — the two measurements that explain it

`tools/measure_feel.gd` exists because the recurring failure mode on this project
was "tests passed, but it still felt wrong." It measures rather than asserts.

**(a) A full-lock reversal turned the truck around in 67 milliseconds.**
In v0.17.0 the raw input axis reached the lateral-velocity lag directly. Nothing
modelled the steering column, so `steer` could jump −1 → +1 in a single frame and
only `velocity_x` lagged. Speed did not enter the handling model at all, and
boost *raised* lateral authority from 2.35 to 2.55 — the truck was more agile at
240 mph than at 146.

**(b) Every jump above roughly 135 mph landed identically.**
`route.gd` clamped `landing_severity` to `[0.15, 1.0]` via `impact/18.0`.
Measured impacts across stages 5 and 6 run **6.4 to 32.8**, so everything at or
above impact 18 saturated at exactly 1.0. A 0.8 m hop and a 23 m, 2.6-second
flight produced byte-identical compression, shake, audio, haptics and speed loss.

---

## 4. What changed, and the reasoning you need in order not to undo it

### Steering — `main.gd` `_update_driving()`
A new `steer_column` sits between input and chassis. Input is a *demand*; the
column follows it at a bounded rate that tightens with speed:

```gdscript
var column_rate: float = lerpf(8.2, 4.4, clampf((speed - 90.0) / 150.0, 0.0, 1.0))
if absf(steer) < absf(steer_column) or steer * steer_column < 0.0: column_rate *= 1.75
```

The `1.75` asymmetry is load-bearing, not a fudge: caster self-centres, so
unwinding and reversing return faster than new lock is added. **Without it,
`verify_road_margin`'s countersteer check fails** — countersteering off the
shoulder must clear `|player_x| < 0.65` within 0.5 s.

`response` now falls to 0.72× and lateral `authority` falls from 2.55 to 2.02
across 120 → 240 mph, so speed costs agility rather than granting it.

Airborne, `velocity_x` integrates from the wheels instead of lerping toward a
steer-driven target. Previously releasing the stick in mid-air decayed lateral
velocity to zero with τ≈0.36 s, i.e. **the player could cancel a sideways launch
by letting go.** Rear-axle swing is damped to 7.5 in the air (was 36, the same as
on tarmac).

### Landings — `route.gd` and `truck_rig.gd`
The clamp ceiling went `1.0` → `1.6`:

```gdscript
landing_severity=clampf(impact/18.0,0.15,1.6)
```

**The `/18.0` divisor must not change.** `verify_weight` calls `_land(18)` and
requires `aquaplane > 0.65`, which needs `severity(18) > 0.833`; any divisor
above 21.6 fails. Raising the *ceiling* leaves `_land(18)` mapping to exactly
1.0, so every existing assertion is bit-identical, while opening headroom above
it. `aquaplane` is bounded at 0.92 so the `lerpf(10.0, 3.8, aquaplane)` steering
term cannot go out of range.

`truck_rig.gd` gained three things, all inside the existing 1/120 substep loop:

- **`pitch_kick`** (spring 120/11, ζ≈0.50, 1.74 Hz) — drops the nose on
  touchdown. Deliberately *faster* than the 74/9.5 body bounce (1.37 Hz) so the
  read is nose-slams → body-squats → rear-settles. This is the highest-value
  change in the batch: a 3–5° shear across a 4.5 m silhouette is worth far more
  screen area than the ~5 px the vertical translation buys at a 10 m chase.
- **`tire_squash`** (spring 900/42, 4.8 Hz) — unsprung slap. Finishes before the
  body reaches peak compression, so the wheels punch up first.
- **Asymmetric damping** — 7.4 compressing, 14.0 rebounding. Symmetric damping is
  the toy-spring signature.

Plus `route.ground_acceleration` is now a member rather than a discarded local,
so the body loads against the ramp face (~6 g up) and extends over the crest
(~6 g down) instead of being welded to the terrain until the launch frame.

### Impacts — `main.gd`, `crashes.gd`, `world3d.gd`
**The owner's standing rule is: do not add camera shake as a substitute for
weight. This was respected literally.** The undirected sine ring coefficient was
cut from `0.008` to `0.0026` and capped, and `shake` decay went 14/s → 22/s. The
freed budget went into a spring-returned impulse along the contact normal, plus
camera roll and a truck yaw kick. **Peak camera displacement is unchanged; it is
simply aimed now.** If you revisit this, keep that trade — do not restore the
ring amplitude *and* keep the impulse.

Collision cost was regressive: a flat `19.0 + 11.0*severity` meant a crate at
240 mph took 13.3% of your speed where the same crate at 120 took 23.8%. It is
now proportional plus flat, and routed through `powertrain.acceleration` so the
weight-transfer model in `truck_rig` finally has a deceleration to dive on.

Hit stop scales 88–200 ms with severity and eases out of a near-freeze rather
than stepping back to full speed in one frame.

### Camera — `world3d.gd`
`_update_view(_dt)` took a delta and never used it. Only `camera_pan` was
smoothed; height, reach, FOV and the look-at target were assigned raw every
frame, so every cue except the sideways follow read as a cut. All four now have
their own time constants. **All use `1.0 - exp(-dt*k)`**, because
`verify_driving` calls `_update_view(0.0)` and requires a zero delta to be a
no-op. Do not substitute a fixed-alpha lerp.

Suspension breathing and the load dolly were gated behind `route.active`, which
is false below stage 3 — **the first three stages, the whole first impression,
had a camera that was perfectly rigid in Y and Z** while the suspension spring
ran the entire time. Both are properties of the truck, so they now apply
everywhere.

### Audio — `main.gd`
There was no speed cue. Gearing pins rpm near 3700 at every cruise speed, so
`0.62 + rpm/6600` was flat — and actually *fell* from 112 mph (1.191) to 178 mph
(1.187). Wind moved **2.33 dB** across the entire speed range, below the ~3 dB a
listener notices. A subordinate `speed/1400` term restores the climb without
masking shifts; wind now moves ~8 dB and rises in pitch. Engine dynamic range
went 6 dB → 15 dB with a real lift-off drop driven by deceleration.

**Do not add keys to the `sfx` dictionary.** `verify_driving` asserts
`sfx.size() == 15` and that every entry has ≥2 variant takes. New transients
(gearshift, turbo blow-off) use a dedicated `shift_audio` player, mirroring how
`landing_audio` already works.

### HUD — `hud.gd`, `main.gd`
`notify()` was two unconditional assignments into one slot shared by 22 call
sites. Over one full chase, **118 notifications fired and 68 overwrote a message
still on screen.** The upgrade confirmation was stomped by the checkpoint notice
every single run — players bought a part and were never told. Notices are now
ranked; the guard only applies while a message is live, so it self-clears.

The dashboard now shows rpm, gear and a shift ring. Your six-speed box with its
0.23 s shift interrupt is the most heavy-truck system in the codebase and was
100% audio-only.

---

## 5. One test was edited — read this before assuming the worst

`tools/verify_road_margin.gd` only. Its pavement-margin probe compares two
single-step responses and **already zeroed `velocity_x` between them**. It now
zeroes `steer_column` too, so both probes start from matched input state;
otherwise the second probe runs with the wheel further wound on and measures the
column rather than the margin gain.

The guarded behaviour is unchanged. Measured with matched state, the edge/centre
gain ratio is **0.199** against the test's 0.30 threshold. No assertion was
weakened, no check was skipped, disabled or deleted.

---

## 6. Invariants — things that will break if you touch them

These are enforced by the suites. Each is here because it is non-obvious.

- `route.gd` **`/18.0` divisor** — see §4. Change the clamp, never the divisor.
- **`sfx.size() == 15`** — new sounds need a dedicated player, not a dict entry.
- **`motor_body.wav` must stay exactly 4.0 s** (`verify_weight`). Re-tuning
  `pitch_scale`/`volume_db` is safe; regenerating at another length is not.
- **Suspension travel stops at −0.26 / +0.13** are hard invariants. Travel cannot
  be widened. Peak compression must land in `[−0.26, −0.13)` after `_land(18)`.
- **`truck.rotation.z` must be 0** and **`body.rotation.z` ≤ 0.0451 rad (2.58°)**.
  Chassis lean is capped; roll headroom comes from the camera, not the truck.
- **`body.scale` must stay `Vector3.ONE`** and the truck mesh vertices must never
  change. The owner has rejected stretching/morphing truck fixes repeatedly.
- **Airborne wheel `position.y` ∈ [0.5399, 0.55)** — `wheel_droop` airborne
  target must stay −0.13.
- `verify_truck_3d` **sets `landing_severity = 1.0` directly**, so the rig's
  landing impulse must keep reading `landing_severity` — do not rename it or
  move it behind a new variable.
- **`_update_view(0.0)` must be a no-op.** Exponential smoothing only.
- `world3d.camera_shift()` is the **single owner** of the camera's offset.
  `scene_truck_yaw()` previously reconstructed that expression by hand and could
  silently drift from it; that duplication was removed deliberately. Do not
  reintroduce a second copy.
- `verify_polish` runs a full 22,000-step seeded demo (seed 99152) that must
  still reach `"INTO THE VORTEX"`. Changes to speed loss can push `distance`
  past the 1850 m fail-out. **Re-run `verify_polish` after any speed-cost edit.**

---

## 7. What is NOT done — the honest list

1. **Nobody has played it.** Every figure in v0.18.0 is headless simulation or
   software-GL capture on Linux. It has **not** been run on Windows, on the
   owner's Galaxy Book2, or with a controller. None of the numbers are a
   statement about hardware frame rate.

2. **The audio has not been heard.** The handoff ZIP ships `.import` sidecars
   without `.wav` payloads, so the mix changes are reasoned from levels and from
   `tools/generate_weight_audio.py`, not listened to. They need a listen before
   release. One specific concern worth checking: `landing_body.wav`'s tonal layer
   is a 66→35 Hz chirp, and at `pitch_scale 0.78` it drops to 51→27 Hz, which is
   below what laptop and TV speakers reproduce. Consider adding a ~190→113 Hz
   layer that survives small drivers.

3. **The truck casts no readable contact shadow on dirt.** This is the strongest
   remaining visual weight cue and it is unresolved. What was ruled out:
   the truck's meshes all have `cast_shadow = 1`; `ground.gdshader` and
   `wet_road.gdshader` are not `unshaded` so they should receive; correcting
   `shadow_normal_bias` from Godot's default 2.0 down to 0.06 changed
   self-shadowing and distant geometry but put nothing under the wheels; and
   moving the sun to −78° elevation (nearly overhead) still produced no contact
   pool. That points at the terrain/ground shader path rather than the light.
   **This was left alone rather than guessed at — it is the best next task.**

4. **Two audit areas never reported.** Six parallel review agents were run; the
   steering/chassis and the correctness/latent-bug audits both died on a rate
   limit before returning. The correctness sweep in particular — framerate-
   dependent `lerpf(a,b,dt*k)` call sites, state that survives a checkpoint
   retry, `set_shader_parameter` names that don't match any shader uniform — was
   never completed and is worth redoing.

5. **Tuning constants are judgement calls.** Everything in §4 is a number someone
   chose. They are all named in the commit messages and `VALIDATION-v0.18.0.md`,
   and `measure_feel.gd` turns any re-tune into a diff instead of an argument.
   If the owner says it is now *too* heavy, the first dials to turn back are
   `column_rate` (8.2/4.4), the `authority` range (2.55→2.02), and the landing
   clamp ceiling (1.6).

---

## 8. Suggested next steps, in order

1. **Get it on real hardware.** Windows + Galaxy Book2 + controller. Everything
   above is unvalidated on the target machine.
2. **Fix the contact shadow** (§7.3). Highest remaining visual payoff.
3. **Listen to the mix** and re-cut `landing_body.wav` for small speakers.
4. **Redo the correctness sweep** that never completed (§7.4).
5. Optional: the garage accessories in `scripts/truck_kit.gd` are still
   procedural meshes and could be authored models without touching the save
   format — that was already on your `NEXT-UPGRADE.md`.

---

## 9. Ground rules carried over from the owner

These come from `CLAUDE-REVIEW-HANDOFF.md` and still apply:

- Preserve Mateo's appearance and age, his connection to the truck, and the
  original detailed orange truck style.
- Preserve the campaign, checkpoint films, score/progress, controller support
  and settings. v0.17.0 saves must keep loading.
- **Do not substitute a slanted, rubbery, stretching or morphing truck for a
  realistic drift.**
- **Do not increase camera shake as a substitute for weight.**
- Do not spend media-generation credits without asking.
- Passing tests are not proof that the movement looks right. Show actual
  gameplay renders, not cinematics.
