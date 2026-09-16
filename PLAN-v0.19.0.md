# Storm Chaser v0.19.0 — Longer Chase, Full Gamepad, Earned Upgrades

## Context

Storm Chaser is played by the owner's ~10-year-old. Three gaps:

1. **It is over in about five minutes.** Eight stages of 30 s plus seven 6 s
   films — 5:27 wall clock.
2. **The gamepad is unverified**, and every on-screen hint names keyboard keys.
3. **Nothing is earned.** All 24 garage parts are free from first launch, and
   the DATA score buys nothing.

Design bias: **a 10-year-old must never lose much progress to one crash, must
make visible progress even in a failed run, and must be able to say their next
goal out loud.**

**This plan will be executed by ChatGPT, the project's original author.** It is
written to be picked up cold. Where a decision exists only to keep a future door
open, that is stated.

### What the owner can supply later (and what this plan does about it)

| Owner can add later | Plan's response |
|---|---|
| More cinematic clips | **Phase 8** adds campaign stages 9–12. Deliberately deferred, because a new stage without a film is the single riskiest change in the codebase (see below). The plan makes that phase cheap when clips exist. |
| Art / textures | No phase depends on new art. Garage parts are procedural meshes (`scripts/truck_kit.gd`) and can be re-skinned later without touching the save format. |
| A VPS with a database | **Phase 5 puts all career persistence behind one small interface** so a cloud backend can replace the local file later without touching game code. |

---

## Correction to my earlier recommendation

I initially proposed raising `STAGE_LENGTH` to 55 and growing the campaign to 12
stages. A design review found two things that make that wrong, both verified
directly:

- **`route.enter()` generates only 3,300 m of road** (`scripts/route.gd:63`,
  `range(1100)` × `STEP 3.0`). At `STAGE_LENGTH = 55` with sustained boost you
  need *exactly* 3,300 m. Past the end, `course()`'s `clampi` pins the index and
  **the road silently collapses to a single point** — the level goes flat with
  no error. My number sat precisely on that cliff.
- **`game.stage` is used as the route level in ~25 places** across
  `world3d.gd`, `storm_landscape.gd`, `storm_shelters.gd`, `world.gd` and
  `vortex_finale.gd` (`game.stage in [4,5,6]`, `game.stage==7`). The moment
  stage index ≠ route level — exactly what "12 stages reusing levels 3–7" means
   — terrain visibility desyncs from terrain height and the truck launches off
  invisible hills. No existing test covers that configuration, because every
  suite sets `game.stage = level; game.route.enter(level)` together.

Also caught: reaching stage 8 would pass `unlock_footage()`'s `FINALE_FOOTAGE`
check and **hand the child the ending film before they ever see the vortex**.

**Revised recommendation: keep 8 stages and 7 films. Raise `STAGE_LENGTH` to 90
and add silent mid-stage save flags every 30 s.** This reaches 12:27 wall clock
while keeping progress-lost-per-crash at 30 s — today's number.

| Design | Driving | Wall clock | Lost per crash | Files touched |
|---|---|---|---|---|
| Today (T=30) | 3:52 | 5:27 | 30 s | — |
| My first idea (T=45, 12 stages) | 8:37 | 10:32 | 45 s | 7 files, ~25 sites |
| **T=90 + 30 s save flags** | **10:52** | **12:27** | **30 s** | 3 files, ~12 sites |

`STAGE_LENGTH == 3 × SAVE_SPAN`. The kid's goal stays sayable: *"8 levels,
7 films, 21 flags."*

---

## Phase 0 — Baseline

`time GODOT=... tools/run_suites.sh`. Record per-suite wall time and the health
figures in `.suite-logs/`. Everything later is measured against this.
**Gate:** 520 checks, 15 suites, timings written down.

## Phase 1 — Gamepad

Lowest risk, touches nothing structural. Menus already work with a pad (real
focusable Buttons, `grab_focus()` seeded in `hud.rebuild()`, Godot's `ui_*`
defaults intact). What is missing:

- Route mute through an InputMap action instead of five hand-rolled `KEY_M`
  checks (`main.gd:428`, `checkpoints.gd:386`, `crashes.gd:231`,
  `dodge_films.gd:199`, `garage.gd:175`); bind `JOY_BUTTON_BACK`.
- Add **FULLSCREEN**, **TOUCH CONTROLS** and **CINEMA VIEW** as rows in
  `settings_rows()` — pad-reachable for free through existing focus navigation.
  Do not invent pad chords for F11.
- Add `JOY_AXIS_TRIGGER_RIGHT` to `boost`.
- Hint strings behind one `pad_connected()` helper: `hud.gd:170,247`,
  `garage.gd:301-302`, `checkpoints.gd:389`, `dodge_films.gd:262`.

New `tools/verify_gamepad.gd`. **Critical:** `ui_*` focus navigation is handled
by the Viewport, not `_unhandled_input` — a test calling
`game._unhandled_input(...)` proves nothing. Push through
`get_viewport().push_input()` and assert `gui_get_focus_owner()` is non-null and
changes, on every screen.

**Known trap to fix here:** `dodge_films.gd:259` only grabs focus
`if not b.disabled`. With everything locked, nothing is focused and **the pad is
stuck on the gallery screen** — a real bug today.

**Gate:** baseline green + new suite; total rises above 520.

## Phase 2 — Route path length (prerequisite)

`scripts/route.gd:59-65`. Replace `range(1100)` with a const sized from the
campaign, and add a `path_exhausted` flag set when `course()`'s clamp bites so a
test can catch it.

```gdscript
const PATH_LENGTH := 6200.0   # >= STAGE_LENGTH * TURBO_SPEED * 0.25 + level-4's 260 m offset
```

Ship **alone, before any length change**, so the check goes green at today's
numbers and then keeps protecting you.

**Gate:** all green; new check passes at T=30 and demonstrably *fails* if
`PATH_LENGTH` is temporarily set back to 3300 with T=90.

## Phase 3 — Save flags, at the current length

`SAVE_SPAN = 30.0`; snapshot `version: 3` carrying `elapsed`; a v3 branch in
`valid_checkpoint()` (leave v1/v2 byte-identical); `_mark_save()`;
`is_breathing()` keyed to `SAVE_SPAN` so `verify_polish.gd:72-76`'s literals stay
green; HUD tick marks.

`_mark_save()`: `save_checkpoint()`, `+15` hull, `+500` DATA, pickup sound,
`"SAVE FLAG / +15 HULL / +500 DATA"`. **No upgrade, no film** — so
`valid_checkpoint()`'s `boost_max <= 310` and `tires <= 1` bounds stay derived
from exactly seven upgrades.

**Leave `STAGE_LENGTH = 30.0` in this phase.** At T=30 no flag ever fires, so
this is pure schema plumbing with behaviour bit-identical.

**Gate:** all green with **no** budget change and **no** result drift. Drift here
means the v3 path leaked into old behaviour.

## Phase 4 — Flip the length

`STAGE_LENGTH 30 → 90`. Fix the duplicated literals: `main.gd:615`,
`hud.gd:214,215,283`, menu copy `hud.gd:170`. Replace hard-coded `* 30.0` with
`* game.STAGE_LENGTH` in six suites (`verify_checkpoints.gd:32`,
`verify_garage.gd:35,280`, `verify_route.gd:15`, `verify_runtime.gd:48`,
`verify_finale.gd:33`, `verify_polish.gd:90`) — reading the constant is strictly
more honest than the status quo. Raise the three 22,000-frame budgets to 48,000
(the *assertions* are unchanged; only the budget grows).

**Watch:** seven campaign runs go from ~14,600 to ~39,900 simulated frames, 2.7×.
`run_suites.sh` has a 600 s per-suite timeout. If `verify_garage` nears it, step
those campaign loops at `1/30` — `verify_runtime`'s existing 30-vs-120 FPS check
is the proof that is safe — and re-baseline.

Tune `_mark_save()`'s hull grant until campaign runs land back in the 70–85
health band. **Tune the grant, never the assertion.**

**Gate:** all green; `stages == [1..7]` still literally true; ≥21 save points in
non-decreasing order. Then **play it** — 12 minutes is the first time anyone
feels whether level 3 drags.

## Phase 5 — Career wallet (read-only, VPS-ready)

```ini
[career]
banked = 128450          ; spendable
earned = 421900          ; lifetime, never decreases; drives badges
owned  = ["wheels:bronze_beadlock", ...]
badges = ["first_light", ...]
last_run = "1758000000-8814231"
last_amount = 47300
```

**Put every read and write behind one thin `CareerStore` interface** with a local
ConfigFile implementation. This is the only concession to the future VPS: when a
server exists, a second implementation drops in and no game code changes.

Three non-negotiables:

1. `save_settings()` (`main.gd:325-341`) builds a **fresh** ConfigFile — all six
   keys must be written there or they vanish on next save. Easiest save-wipe bug
   in the project.
2. **Migration.** A v0.18 cfg has no `[career]`. Without it the child opens the
   garage and finds the parts *they are currently driving* locked. Seed `owned`
   from every non-stock id in the loaded loadout, and seed `banked = best` —
   their best run becomes their opening balance, which is a good first-launch
   moment.
3. **Close the farming exploit.** Bank → crash → `retry_checkpoint()` (which
   restores `score`) → bank again. Reuse the per-`run_id` dedupe already in
   `_record_score()` (`main.gd:1130-1140`).

**Bank on every `finish()`, win or lose**, and print `"+47,300 DATA BANKED"` on
results. Keep **two separate numbers**: `best`/`high_scores` is the bragging
number and is never decremented; `banked` is the wallet. If shopping shrank the
scoreboard, buying would feel like a punishment.

No prices and no locks in this phase — the wallet just fills.

**Gate:** all green; `verify_garage`'s catalog and sanitize checks untouched; a
hand-written v0.18 cfg loads with the right parts already owned.

## Phase 6 — Prices, badges, garage lock UI

`loadout.gd` catalog gains two optional fields (absent = free):
`cost: int`, `badge: String`. **Do not touch `sanitize()` or `cycle()`** —
`sanitize()` stays ownership-blind so a saved loadout is never silently reset,
and `cycle()` stays unconditional so the child can *browse* locked parts and see
them on the truck. That preview is the carrot. Enforcement lives in exactly one
place: `leave_garage()` calls a new `Loadout.owned_only()`.

Prices, calibrated against a T=90 run (≈150k for the demo driver; a child will
see 80–140k; a bad run 15–25k). Cosmetics 12k–50k, totalling ≈456k ≈ 3–4 runs.

**Chase setups are free but badge-gated, not priced.** They are trade-offs, not
upgrades — priced at 25–30k a child just drives STOCK forever because cosmetics
are cheaper and shinier. Badge-gating reads as *I did a thing*, which is exactly
what the owner asked for.

Eight badges, each reading a counter **that already exists** (only `iron_hull`
needs one new int):

| id | Said out loud | Counter |
|---|---|---|
| `first_light` | FIRST CHECKPOINT | `stage_seen` |
| `storm_veteran` | ALL SEVEN FILMS | `footage_unlocked` |
| `vortex_recorded` | INTO THE VORTEX | `finish(won)` |
| `probe_master` | TEN PROBES IN ONE RUN | `probes` |
| `big_air` | TEN CLEAN LANDINGS | `route.landings - route.hard_landings` |
| `dodge_ace` | FIVE-DODGE COMBO | `combo` (HUD already draws 5 pips) |
| `one_take` | WIN WITH NO RETRY | `checkpoint_retry` |
| `iron_hull` | A WHOLE LEVEL, NO HITS | `hits` + one new snapshot int |

Awarded in two places only, both mirroring `unlock_footage()`
(`main.gd:1156-1159`): `checkpoints.complete()` and `finish()`.

Garage UI reuses the existing badge slot at `garage.gd:273-275`, and the
currently-unused `RED` at `garage.gd:15` for unaffordable. **Every locked row
shows price and current balance on the same screen** — a child will not go
hunting for their wallet. Buy on `KEY_B` / `JOY_BUTTON_X` (unused in
`garage.handle_input`).

**Gate:** all green; new checks that an unowned part cannot survive
`leave_garage()`, that a badge-gated part stays locked with sufficient DATA, and
that buying is idempotent and never drives `banked` negative.

## Phase 7 — Endless Chase

Cycle `stage` through **3→4→5→6→3…** — every one of those ~25
`game.stage in [4,5,6]` sites stays correct for free. Guard `main.gd:722` with
`not endless` so the finale never fires on a throwaway run. No checkpoints, no
films, no new assets.

**Do not make wrecking the only exit** — a mode you can only lose teaches "you
always lose." Bank DATA continuously as it is earned, and make PAUSE →
**"END RUN AND BANK"** a legitimate exit with a personal best to beat.

**Gate:** all green; new check that endless never sets `stage = 7` and never
enters `Mode.VORTEX`; campaign suites unaffected.

## Phase 8 — More stages (only once clips exist)

Deferred deliberately. When the owner has films for checkpoints 8–12:

- Extend the four length-8 arrays (`CRUISE_SPEEDS`, `STAGE_NAMES`,
  `DEBRIS_MULTIPLIERS`, and the inline `[0,0,0,820,650,490,320,180]`).
- **Introduce an explicit `route_level` separate from `stage`** and migrate the
  ~25 `game.stage in [...]` sites in the 3D code. This is the real work and the
  reason the phase is last.
- Raise `valid_checkpoint()`'s stage bound and the upgrade-derived
  `boost_max`/`tires` ceilings in step.
- Extend `CHECKPOINT_FOOTAGE` and move `FINALE_FOOTAGE` off 8.

---

## Tools the owner needs to supply

| For | Tool | Notes |
|---|---|---|
| Building / testing | **Godot 4.5.1 stable** | Already required. CI downloads it automatically. |
| New cinematic clips | Any video generator, then **FFmpeg** | Godot needs **Ogg Theora `.ogv`**. Convert with `ffmpeg -i in.mp4 -c:v libtheora -q:v 7 -c:a libvorbis out.ogv`. Match the existing 6.0 s checkpoint length (`checkpoints.gd:4`). |
| New art | Any image generator | Drop PNGs in `assets/`; Godot imports on open. Garage parts are procedural (`truck_kit.gd`) and can be re-skinned without touching saves. |
| VPS cloud save | A small HTTP API + **Postgres or SQLite**, and **HTTPS** | Godot side is `HTTPRequest` — **the project has zero networking today**, so this is built from scratch. Phase 5's `CareerStore` interface is the seam. Needs: one `GET /career/:player` and one `POST /career/:player`, plus a shared secret. Keep the local file as the offline fallback. |
| CI | **GitHub Actions** | Already running; all 520 checks execute on every push. |

---

## Verification

Every phase ends with `tools/run_suites.sh` green (520 checks and rising) before
the next begins. CI runs it on every push. New suites: `verify_gamepad.gd`,
`verify_career.gd`, `verify_endless.gd`, plus new checks folded into
`verify_route.gd` and `verify_checkpoints.gd`.

**No assertion may be weakened or deleted.** Where a test encodes today's
campaign, it is updated to the new truth — and where a number moves (frame
budgets, hull bands) the *budget* changes, never the claim.

**If time runs out, stop after Phase 4.** The child then has 12 minutes of game
with 30-second forgiveness and a working controller — two of the three asks, at
a fraction of the risk.

---

## What I would not do

- **Do not add campaign stages before clips exist.** Highest risk in the
  codebase, and it spoils the finale film.
- **Do not raise `STAGE_LENGTH` without Phase 2 first** — you drive off the end
  of the generated road, silently.
- **Do not gate Endless Chase behind finishing the campaign.** One more rule to
  explain, no benefit.
- **Do not let buying reduce the scoreboard number.**
- **Do not make any part permanently missable.** Badges gate *when*, never
  *whether*.
- **Do not stretch the vortex lap to pad runtime.** It is the climax and the
  hardest section; doubling it makes the best 25 seconds the most frustrating 50.
