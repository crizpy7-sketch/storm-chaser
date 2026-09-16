# v0.17.0 validation

On a clean extraction of this package, fourteen suites pass 504 checks with no failures. Eight checks need the audio and film pack, which the handoff ZIP omitted, so they report SKIP. With a synthetic media pack at every missing path, all 512 checks run and pass. Logs, summaries and stills are in `validation/v0.17.0/`.

| Suite | Trimmed copy | With media pack |
|---|---:|---:|
| checkpoints | 175 + 1 skipped | 176 |
| route | 71 | 71 |
| finale | 49 + 1 skipped | 50 |
| garage (new) | 39 | 39 |
| solid impacts | 38 | 38 |
| polish | 26 + 2 skipped | 28 |
| driving | 20 + 3 skipped | 23 |
| runtime (new) | 22 | 22 |
| truck 3D | 16 | 16 |
| landscape | 15 | 15 |
| road margin | 14 | 14 |
| weight | 13 + 1 skipped | 14 |
| storm art | 4 | 4 |
| contact campaign | 2 | 2 |

Run a suite with `godot --headless --path . --script res://tools/verify_garage.gd -- --test`. `verify_rigid_truck.gd` remains an alias for the truck 3D suite and is not counted.

## Test environment

- Godot 4.5.2 stable (official Linux x86_64 build) on a two-core Intel Xeon (2.8 GHz) Linux virtual machine.
- Suites and frame-cost runs were headless. Stills used the GL Compatibility renderer on Mesa llvmpipe (software OpenGL) under Xvfb at 1280×720 with `--fixed-fps 30`.
- **Trimmed copy:** the package as shipped, with no `.godot` cache and no media pack. The game used its in-memory stand-ins, and the film checks played `tools/test_media/stand_in_film.ogv`.
- **With media pack:** the same extraction plus synthetic files at every missing path: 57 WAV tones, 16 images and 17 copies of the stand-in film. It confirms that the game and suites switch to installed files. It does not test the owner's real recordings or art.

## What the new checks cover

- **Garage (39).**
  - Stock parts come first, a fresh save is all stock, and damaged or unknown values fall back to stock.
  - Every alternative setup has a benefit and a cost. Stock's factors are exactly 1.0, and each setup's effect is measured in play.
  - Cosmetic parts never alter the approved 67,656-triangle truck mesh, and STOCK LOOK restores every original finish. A customized look drives identically: steering, jumps, hull and boost.
  - Also covered: save and reload, keyboard and controller input in the garage, checkpoint resume, the scoreboard and gallery labels, and Mateo's facing.
  - The automated driver completes the full campaign with each setup.
- **Runtime (22).**
  - Media stand-ins are generated in memory and never written to asset paths. An `.import` file alone never counts as installed media. The storm film button is disabled only when the film is missing.
  - The optimized elevation field matches the original formula to within 0.00001 units. Shared road rows reproduce every road and shoulder vertex.
  - The hill grid updates shader inputs without rebuilding. Grass reads the same field inputs, and its cached positions match per-frame placement across scroll cycles and level changes.
  - The course-frame cache refreshes whenever progress or the level changes.
  - Interface fixes: the duplicate hint, the debrief footage button inside its panel, and controller B/Start closing the title film.
  - Jump height stays within 3% between 30 and 120 FPS: Ridgeline 3.24 m at both, Wild Hills 8.57 / 8.58 m.
- The grass placement check and the three interface-fix checks were each run against a deliberately broken version of the code, and each failed as expected.

## Performance

`frame-cost.log` holds three runs of this build and two of the v0.16 code. The v0.16 runs include only the media loader, so they start without the media pack. "View update" is the GDScript cost of the 3D view per simulated frame:

| Level | v0.16 | v0.17 |
|---|---:|---:|
| 1 Prairie Approach | 2.4 ms | 1.9–2.0 ms |
| 4 Crosswind Curves | 11.2–11.4 ms | 4.7–5.0 ms |
| 5 Dirt Shortcut | 59.6–66.4 ms | 5.3–5.8 ms |
| 6 Ridgeline Jumps | 70.5–70.9 ms | 6.6–7.0 ms |
| 7 Wild Hills | 75.1–76.2 ms | 6.5–7.3 ms |
| 8 Vortex Run | 7.8–9.0 ms | 2.4–2.5 ms |

The driving simulation stays under 0.35 ms per frame in both builds, including the new 1/120 s substeps. These are CPU figures from one virtual machine. They exclude GPU rendering and are not a Galaxy Book2 benchmark. The hill grid and grass heights now run in vertex shaders, and that GPU cost was not measured on real hardware.

## Rendering

`render-diff.txt` compares the 15 stills from `tools/capture_review.gd`:

- Moving the hill grid to the GPU changed at most 15 pixels in any still.
- Moving grass heights to the GPU changed no pixels. The grass shader uses the same lighting model as the material it replaced.
- The remaining differences from v0.16 are expected:
  - the new garage button;
  - Mateo turning toward the camera;
  - route substeps moving the truck slightly in later-level stills;
  - the removed duplicate hint;
  - the resized results panel;
  - the FILM NOT INSTALLED labels.

The JPEG stills show the garage in its stock look and three custom looks, a custom truck in the chase and vortex-orbit views, and Wild Hills with GPU terrain. The folder contains `.gdignore`, so Godot does not import them.

Setup balance was sampled separately with five automated campaigns per setup; the results are in `NEXT-UPGRADE.md`.

## Limits

- **Hardware.** Nothing was tested on Windows, a Galaxy Book2, a TV, a physical controller or touch hardware, and no exports were built. Input checks inject keyboard and controller events.
- **Media.** Media checks ran only against synthetic files; the real audio and films were not available.
- **Model textures.** On first import of a trimmed copy, Godot reports that `assets/models/interceptor-3d_0.png` and `interceptor-3d_1.png` are missing, then embeds the model's own textures, so the truck renders correctly. The full project has both files.
- **Legacy renderer.** `scripts/world.gd`, the unused early 2D renderer, still preloads `tornado.png` and `flying-semi.png`. Nothing loads it, but opening it in the editor in a trimmed copy shows missing-file errors.
- **Exit warning.** Headless suites end with "ObjectDB instances leaked at exit" because looping audio players are still active when a test quits. The v0.15.0 validation already noted this; it does not affect results.
