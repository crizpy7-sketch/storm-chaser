# Storm Chaser — art direction and provenance

Eight original production images were generated for this game with the built-in image generation tool. No separate image API or API key was used. Original generated PNG files are included without manual repainting. Alpha transparency from the generated truck, tornado and debris atlas is preserved. Mateo's atlas uses an original generated green matte, removed by the runtime material without modifying the PNG.

The gameplay screenshots and Storm-Chaser-v0.4-Cinematic-Dodges-Gameplay.mp4 are captured from the actual Godot application. Version 0.4 includes labeled pre-rendered dodge films during that capture; these are reusable celebration clips, not simulations of the player's exact steering. Storm-Chaser-Higgsfield-Trailer.mp4 and the in-menu Storm Film are the original generated cinematic. The title screen uses generated key art.

## Asset manifest

| File | Use |
|---|---|
| `assets/art/key-art.png` | Cinematic title background |
| `assets/art/storm-sky.png` | In-game storm panorama |
| `assets/art/terrain/prairie-storm.png` | Hill-stage supercell panorama |
| `assets/art/terrain/clay-ruts.png` | Seamless wet clay / rut tile |
| `assets/art/terrain/prairie-grass.png` | Seamless olive stubble mixed into the ground shader |
| `assets/art/terrain/wet-asphalt.png` | Seamless wet pavement sampled by the road shader |
| `assets/art/terrain/storm-dust.png` | Seamless dust grain for the tornado foot |
| `assets/art/truck.png` | Original truck art on the 3D depth mesh |
| `assets/art/tornado.png` | Transparent animated vortex sprite |
| `assets/art/debris-atlas.png` | Debris reference and lens projectile atlas |
| `assets/art/flying-semi.png` | Generated red semi/trailer art reference, retained with source |
| `assets/art/flying-cow.png` | Transparent cow artwork moving through 3D space |
| `assets/art/mateo-storm-camera.png` | Mateo's four-pose camera-operator atlas with a runtime chroma matte |
| `assets/models/storm-vehicles.glb` | Editable pickup and 18-wheel tractor-trailer meshes |
| `assets/cinematics/storm-film.ogv` | Labeled Higgsfield cinematic in the title menu |
| `assets/cinematics/dodges/` | Six reusable item celebration films and gallery posters |

The 0.3 highway is a curved mesh with a wet asphalt shader and continuously moving markings. Field shading samples the prairie in the generated panorama. Road debris, poles, wires, reflectors, turbines and the semi are procedural or authored 3D geometry. The tornado is animated artwork in 3D space, with orbiting mesh debris. The cow is a transparent 3D billboard.

The truck retains its generated detail through a 32-band textured depth mesh. Its roof and rear sit at different depths and rotate around the vertical axis during a fishtail. It has no body roll. The authored solid model supplies its contact shadow. This hybrid approach preserves the art better than the untextured model alone. The project includes the original individual GLB parts and the Blender authoring script; the runtime combines solid parts by material for fewer draw calls.

Rain and lens effects are screen-space layers. Tire spray projects moving world-space particles through the chase camera. Lens fractures clear after a few seconds. Calm FX reduces the added camera effects, removes cracks, shards and flashes, and retains a subtle water mark.

## Higgsfield cinematic and vehicle creation

The v0.4 dodge set consists of six five-second `flux_3_video` generations at 720p with synchronized audio: crate, barrel, tire, roofing sheet, semi and cow. All start from a cropped frame two seconds into the original trailer, preserving the orange research truck and storm palette. Each prompt asks for a fast approach, low moving camera, horizontal fishtail, a brief slow-motion near miss and acceleration away. The films are standalone variations, deliberately reusable across steering directions. They are embedded as 1280×720, 30 fps Theora/Vorbis media; original MP4 masters are supplied in the separate six-film archive. Per-item job IDs, source URLs and generation prompts are preserved with the assets. No generation service is called during play.

The ten-second trailer was generated with Higgsfield `flux_3_video`, 720p, audio enabled, using the supplied gameplay screenshot and the requested truck fishtail, overhead semi, cow and lens strike. Generation job: `94b8bbc1-28a5-4a83-9115-2b98c86723c8`. The completed generation used 55 credits. Its original 1280×704 MP4 is delivered separately; a 1280×720 Theora version is embedded in the game. No paid service is called by the game.

The editable vehicle meshes were authored in Blender through Higgsfield 3D Jutsu, project `74910cc5-3158-4686-be65-bde9521eabee`, committed revision 1. The orange research pickup includes off-road wheels, weather equipment, bed cargo, a cage, antennas and lamps. The tractor-trailer includes its cab, exhausts, corrugated trailer, door hardware and 18 wheels. Catalog imports were unavailable, so these are newly authored geometry, not downloaded marketplace models. The portable GLB and reproducible authoring script are included.

The new art briefs were a red tractor with an attached long silver trailer, entirely airborne and isolated on alpha, and a whole Holstein cow with splayed legs, isolated on alpha. Both follow the original painterly storm-lighting direction. Original pixels and alpha channels are preserved.

## Generation prompts

### Mateo storm-camera operator

Identity reference: the user's supplied IMG_8570.jpeg of Mateo, also identified in the existing family character board. The reference photo is not included in the distributed source project. His short dark hair, rounded face, teal shirt and blue shorts inform the generated character. The orange truck art supplies the painterly storm-lighting style.

The production atlas has four poses in a 2×2 layout: filming away from the chase camera; tilting the camcorder upward; looking back with an excited grin; and ducking with the camera held close. All use a compact black camcorder and black chest harness. The first generation painted a checkerboard rather than alpha; a second image-generation edit replaced that background with solid chroma green while preserving the character art. The final PNG is 1254×1254 RGB.

The exact original generation prompt is preserved in `assets/art/mateo-generation.json`. The material in `shaders/mateo_camera.gdshader` removes green and edge spill at runtime, crossfades premultiplied pose samples and bends a subdivided mesh for upper-body movement. His placement is a child of the truck; the truck's depth mesh occludes his legs. This is animated character artwork in 3D space, not a fully rigged character model.

Storm-Chaser-v0.5-Mateo-Gameplay.mp4 is a direct 24-second game capture with automatic films disabled for the recording. Mateo is rendered and animated live. The original trailer and celebration films have not been regenerated with him.

### Title artwork

Use case: stylized-concept. Create a stunning finished key art image for an original premium indie storm-chasing driving game, landscape 16:9. Cinematic low rear three-quarter view of a rugged yellow-orange storm research pickup truck accelerating along a rain-soaked two-lane highway through the American Great Plains toward an immense rotating tornado on the horizon. Truck fills lower right foreground, orange amber roof beacons, roll cage, chunky black off-road tires, roof mounted silver weather radar dish and antenna, rear equipment bed, vivid red tail lights reflecting in wet asphalt, highly readable silhouette. Massive beautifully sculpted spiral funnel in center distance, suspended planks and small debris swirling at its base, brooding layered supercell clouds across the sky. Small leaning power poles, wheat fields, distant wind farm and farmhouse, painterly dust and rain. Deep midnight navy and storm teal with subtle warm golden light cutting through right horizon. Refined painterly 3D / hand-painted adventure game art, expressive dramatic shapes, rich textures, beautiful atmospheric perspective, dynamic but clean composition, a game you would want to play. Road sweeps from lower foreground toward vortex. No people, no real brands, no letters, no text, no UI, no watermark. This art will be the actual game title screen artwork. Save a local image for use in the Godot project.

### Truck

Use case: stylized-concept. Asset type: a single transparent-background game sprite for a Godot storm-chaser driving game. Render one rugged yellow-orange storm research pickup truck viewed EXACTLY FROM DIRECTLY BEHIND, with a slightly elevated chase camera so the rear bumper, back wheels, tailgate, equipment in open bed and cab roof are all visible. Vehicle faces away toward top of frame, rear faces the viewer. Symmetric straight driving pose with no turn, aligned vertically. Long radio antennas, compact silver weather radar dish on roof, roll cage, two small amber warning lamps, black heavy off-road tires, red tail lights, lightly weathered orange body. Premium detailed hand-painted 3D adventure game sprite, beautiful realistic material shading and crisp silhouette, rich midnight-teal shadows with warm amber edge light. Entire truck including antenna and tires inside frame with generous empty margin. Rear-facing truck fills middle 75 percent of a square canvas. Isolated on TRUE TRANSPARENT alpha background, no floor, no cast shadow beyond vehicle, no scenery, no road, no words, no watermark, one sprite only. Preserve alpha transparency in the output. Game production art, matching the rugged orange chase truck visual direction.

### Storm panorama

Use case: stylized-concept. Asset type: actual 2D Godot game landscape backdrop, 16:9 wide panorama. Beautiful storm-chasing game environment across the American Great Plains. A breathtaking menacing supercell cloud ceiling fills the TOP 85 PERCENT of the image, huge dark navy and muted turquoise rolling storm clouds with subtle rain curtains and cold lightning behind distant clouds. A narrow warm gold break in clouds at far right. FLAT DISTANT HORIZON at exactly 85 percent down image, last 15 percent shows distant prairie grass farmland in muted dull olive and gray, a very small farmhouse and tiny utility poles at far edges. Center and lower center open. Premium detailed painterly-realistic game environment, cinematic atmosphere, highly polished beautiful landscape lighting, teal-black heavy weather versus restrained warm amber horizon. No tornado or funnel, no vehicles, no road or pavement, no close foreground objects, no people, no text, no UI, no watermark. We add the moving tornado and moving highway separately in the game. Keep the land flat and extremely distant, sky-focused panoramic asset.

### Tornado

Use case: stylized-concept. Asset type: a single TRANSPARENT alpha game sprite of a tornado for a premium Godot storm chaser game. A huge dark storm tornado funnel, broad and flared at top, becoming a twisting narrower sinuous funnel toward the ground, with a small circular turbulent dust plume at the base. Entire standalone funnel fully within portrait-like centered composition on square canvas. Dramatic sculpted helical bands of dark storm blue-gray cloud with cool teal rim light, swirling warm gray dust at ground contact, beautiful volumetric depth and painterly-realistic textures, highly detailed polished game production art. The tornado top may include a localized mushroom of cloud but NOT a whole rectangular sky. Full tower from top cap to dust foot visible, takes 88% height and 70% width. Isolated on TRUE TRANSPARENT background, preserve alpha; no scenery, no landscape, no horizon, no vehicles, no lettering, no watermark. Opaque dark tornado body and soft semi-transparent feathered edges only.

### Debris atlas

Use case: stylized-concept. Asset type: transparent game sprite atlas, four isolated storm debris props for a premium Godot driving game. Square canvas divided into an INVISIBLE precise 2 by 2 grid, equal sized cells. Top LEFT cell: one broken weathered wooden shipping crate with a few splintered boards attached. Top RIGHT cell: one battered red oil drum barrel tilted slightly. Bottom LEFT cell: one large black rubber truck tire angled three-quarter view. Bottom RIGHT cell: one bent silver-gray corrugated metal roofing sheet angled diagonally. Each complete object centered in its own quadrant, max 65 percent of cell width and height with large transparent margins between objects. They must not touch and must not cross quadrant boundaries. Detailed painterly realistic 3D game prop style, crisp legible silhouettes, storm-blue shadows and soft amber rim lighting matching a storm chaser truck on a wet highway. Actual TRUE transparent alpha background throughout empty space. No floor, no square background panels, no shadows extending far, no lettering, no labels, no numbers, no borders, no grid lines, no watermark. Exactly four props arranged at quarter-canvas centers.

## Sound and fonts

All gameplay music and sound effects were synthesized specifically for this game with the included deterministic `tools/generate_audio.py` script. The score is an original 138 BPM minor-key electronic action cue, with separate engine, wind, turbo surge and loop, stereo debris flybys, thunder, impact, near-miss, pickup, probe and UI sounds. Engine and wind intensity follow driving speed. The Skyfall update adds skid, heavy-pass, cow and lens-impact sounds. The separate generated cinematic includes its own generated soundtrack. Runtime audio uses 16-bit PCM WAV files for reliable cleanup and looping.

The interface uses bundled DejaVu Sans, Sans Bold and Sans Mono. Their redistribution license is in `assets/fonts/LICENSE.txt`.

The game is powered by the open-source Godot Engine. Godot's license and bundled third-party notices accompany the playable builds.

## 0.5.1 runtime color treatment

The original Mateo PNG is preserved. After chroma removal, the material reduces blue-clothing saturation more than skin saturation, applies cool overcast fill and lower exposure, and darkens the lower body inside the truck bed. A small lighting gain follows the existing game lightning value and is disabled by Calm FX. This matches the character to the storm without regenerating his likeness or animation poses.

## Final Impact cinematic / 0.6

An eight-second Higgsfield FLUX 3 Video generation provides the terminal crash: low wheel tracking, corrugated metal impact, a sideways skid through rain and a dented pickup stopped on the shoulder. It uses the same trailer-derived orange truck reference as the dodge films. The camera concentrates on the vehicle; Mateo remains part of live gameplay but is not depicted in this film. The clip and synchronized audio are embedded locally as Theora/Vorbis at 30 fps. The final wreck frame supplies the Game Over backdrop. The original MP4 is delivered separately. Exact generation parameters and the source URL are in assets/cinematics/final-impact-generation.json. The first ten-second generation failed; the completed eight-second retry is used.

## Destruction Checkpoints / 0.7

The two building sequences are scripted Godot 3D scenes, not new prerecorded Higgsfield generations. They use the actual truck and storm-graded Mateo actor. Independent wall bays, roof sheets, beams, doors, dust billows and close-passing panels share materials with the road debris introduced after each checkpoint. The camera stays behind the truck to suit its existing textured depth mesh.

`assets/art/building-materials.png` was created with the built-in image-generation tool in a single four-quadrant atlas. Top-left: aged red barn siding; top-right: galvanized roofing; bottom-left: gray concrete; bottom-right: blue-gray industrial steel. Godot samples the quadrants through material UV scale and offset; the generated image is preserved without cropping or repainting. The full production prompt is in `assets/art/building-generation.json`.
