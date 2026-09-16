# Next upgrade — after Mateo's Garage

Mateo's Garage shipped in v0.17.0: paint accents, wheels, roof equipment, bumper armor and suspension trim, plus an optional chase setup (Stock, Rally, Armored, Turbo). Every slot starts on the approved stock part, and the stock setup keeps the original handling.

Open items that need the owner's feedback or hardware:

- **Playtest on the Galaxy Book2 / Windows and a controller.** Confirm the garage controls, the hill-level frame rate and the slightly lower 60 FPS jump height (now the same at every frame rate).
- **Setup balance.** In five automated campaigns per setup, run on the same five seeds, Armored averaged about 1.4% more DATA than Stock and Turbo about 1.1%. Stock's own scores varied by about 4% between seeds. Rally scored like Stock but crashed once in level one, on a seed where Stock ended that level with 10 hull left. The automated driver is not a human, so check real runs before tuning the factors in `scripts/loadout.gd`. The scoreboard already labels non-stock setups.
- **Garage art pass (optional).** Accessories are procedural meshes built in `scripts/truck_kit.gd`. They could be replaced with authored models later without touching the save format.
