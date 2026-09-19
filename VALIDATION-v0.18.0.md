# v0.18.0 validation

Run on a clean extraction with **Godot 4.5.1 stable** (`Godot_v4.5.1-stable_linux.x86_64`),
Compatibility renderer, Linux, software GL via Xvfb/llvmpipe.

## Automated suites

Fifteen suites pass **520 checks with 0 failures**. Eight checks need the audio and
film pack, which this copy omits, so they report SKIP rather than PASS.

| Suite | Checks | Failures |
|---|---:|---:|
| checkpoints | 175 | 0 |
| route | 71 | 0 |
| finale | 49 | 0 |
| garage | 39 | 0 |
| solid impacts | 38 | 0 |
| polish | 26 | 0 |
| runtime | 22 | 0 |
| driving | 20 | 0 |
| rigid truck | 16 | 0 |
| truck 3D | 16 | 0 |
| landscape | 15 | 0 |
| road margin | 14 | 0 |
| weight | 13 | 0 |
| storm art | 4 | 0 |
| contact campaign | 2 | 0 |
| **total** | **520** | **0** |

The same 520 checks pass on the unmodified v0.17.0 baseline, so this branch
neither adds nor removes coverage; it changes behaviour the existing coverage
already guards.

## Feel telemetry

`tools/measure_feel.gd` asserts nothing. It prints the numbers that decide whether
the truck reads as heavy, so a tuning change can be diffed rather than argued
about. Raw before/after output is in `validation/v0.18.0/`.

| Measurement | v0.17.0 | v0.18.0 |
|---|---:|---:|
| Full-lock reversal, cross zero | 0.067 s | 0.183 s |
| Full-lock reversal, complete | 0.292 s | 0.442 s |
| Steering rise time (t63) | 0.092 s | 0.183 s |
| Lateral authority at 146 mph | 2.35 | 2.44 |
| Lateral authority at 240 mph | 2.55 | 2.02 |
| Landing compression, soft | −0.090 m | −0.103 m |
| Landing compression, hard | −0.203 m | −0.232 m |
| Landing compression, extreme | −0.203 m | −0.260 m (bottoms out) |
| Landing nose dive, soft/hard/extreme | none | −1.34° / −3.02° / −4.36° |
| Tyre deflection on landing | none | 0.009 / 0.020 / 0.029 m |
| Crate impact at 90 mph | −27.8 mph (30.8%) | −24.3 mph (27.0%) |
| Crate impact at 240 mph | −32.0 mph (13.3%) | −48.9 mph (20.4%) |
| Masonry impact at 240 mph | −36.6 mph (15.3%) | −62.8 mph (26.2%) |
| Hit stop, light → heavy | 0.085 s flat | 0.123 → 0.191 s |

Two figures are the headline. Before, a full-lock reversal turned the truck around
in 67 ms, and `landing_severity` saturated at 1.0 for any impact at or above 18,
so a 0.8 m hop and a 23 m crest landing produced byte-identical compression,
shake, audio and speed loss.

## Rendered evidence

`tools/capture_review.gd` was run under Xvfb before and after the change; all
fifteen stills render, framing is preserved on every stage, and the dashboard
layout was checked at 3× crop. These are actual game renders, not cinematics.

## What was deliberately not changed

- No art, model, texture or shader asset was replaced or regenerated.
- The campaign, checkpoints, save format, footage unlocks and garage loadout
  format are untouched; v0.17.0 saves load unchanged.
- Camera shake amplitude was not increased. The existing budget was re-aimed
  along the contact normal and the undirected ring was cut to pay for it.

## Known limits

- Not yet played on Windows, on the owner's Galaxy Book2, or with a controller.
  Every figure above is from headless simulation or software-GL capture on Linux,
  so none of it is a statement about hardware frame rate.
- Audio changes are reasoned from the mixing levels and the generator script.
  This copy ships without the `.wav` payloads, so they have not been heard.
- The truck casts no readable contact shadow on dirt. This was investigated and
  is not shadow bias; it is unresolved and is the strongest remaining visual
  weight cue still missing. See the pull request for the evidence.
