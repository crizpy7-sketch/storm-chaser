# Storm link — Jev behind the decisions

Storm Chaser can ask [Jev](https://typesafe.ai/blog/introducing-system-one-models-and-jev),
TypeSafe AI's System One model, to make some of the judgement calls the game
makes about a moment. Today that is one call: **which of Mateo's recorded lines
he says next.** The Storm Director — hazard pacing — is designed for and not
built.

It is off unless a key is in the environment. There is no key in this
repository, and none in any build.

## Why Jev and not a chatbot

Jev does not write text. Given a state and a typed question it returns a
**choice from options you declared**, with calibrated probabilities and a
confidence. That is the only shape of AI this game has a use for:

- A ten-year-old is playing. Nothing generated should ever reach them. Jev picks
  which already-recorded line plays; it cannot write one.
- The game is 60 fps. Jev is fast, but no network call is fast enough to sit in
  a frame — so none of them does. See below.
- It is cheap enough to be irrelevant: input runs about **$0.042 per million
  tokens**, and a question here is a few hundred.

## The rule the whole design hangs on

**The game always decides for itself, and the advisor may only re-rank.**

`scripts/advisor.gd` is the seam. Every call passes the game's own answer as
`fallback`, and the base class returns it unchanged. So with no key, no network,
a timeout, an error, a low-confidence shrug, or an answer naming something that
was never offered, the game behaves exactly as it always has. That is not a
fallback path bolted on afterwards; it is the default, and the advisor is the
exception.

Two consequences worth stating:

- **No check suite can reach a network.** `build_advisor()` excludes `--test`
  and the demo driver outright, and `verify_advisor` asserts it — including with
  a key present. All 685 checks are as deterministic as they were before.
- **Nothing from the network reaches the player.** An answer is matched back to
  the option ids that were sent. Anything else is discarded.

## How it runs without waiting

`choose()` never asks a question it needs answered now.

1. It builds a **coarse signature** of the moment — hull bucketed, speed
   bucketed, what just happened — not the exact numbers.
2. If Jev has already answered *that kind of moment*, the remembered answer is
   used immediately.
3. If not, the game's own decision is used **right now**, and one request is
   queued to fill the gap for next time.

At most one request is ever in flight, rate limited, with a 4 s timeout on a
threaded `HTTPRequest`. A cold cache plays exactly like no advisor at all. This
is a warm policy cache, not a request-response loop: the answer improves the
*next* moment of its kind, never the current frame.

## Turning it on

Set the key as an environment variable where the game runs. **Never commit it,
and never paste it into a chat or an issue.**

```
TYPESAFE_API_KEY=...        # or JEV_API_KEY
```

- **In a Claude Code web session**: add it to the environment's variables in the
  environment settings, not to a file in the repo.
- **On your own machine**: export it in the shell you launch Godot from.
- **In an exported build**: don't. A Godot export can be unpacked, so a key
  shipped inside one is a key given away. An export simply finds no variable and
  runs local — which is the intended way for the Galaxy Book2 to play.

Then: **SETTINGS → MATEO READS THE CHASE**, on by default. When a link is up,
the base menu shows `STORM LINK  JEV` under the wallet. That line is how you
know the key works.

If you want the link on a machine you do not control, the answer is the same
small server Phase 5's `CareerStore` already anticipates: the game talks to your
server, your server holds the key.

## What it costs to be wrong

Nothing that cannot be turned off in one toggle. The worst case is Mateo picking
a less apt line than the game would have, thirteen seconds apart, with the
opening line still guaranteed and the flying cow still winning ties.

## What is not done

- **The Storm Director.** Every few seconds, score how the run is going and
  choose the next hazard wave from the waves the game already spawns — lean in
  when they are cruising, ease off after a bad stretch. It is the same seam and
  the same rules, and it is the one with real engagement upside. It touches what
  the campaign suites guard, so it is its own piece of work.
- **Nobody has played this with a live key.** The request and response shapes
  follow TypeSafe's published API reference and are exercised against synthetic
  bodies in `verify_advisor`. The first live call is still ahead.
- **More of Mateo's lines.** The system is worth most when he has more to choose
  between. A new line needs an entry in `LINES` and its `.wav` beside the
  others; `mateo_takes()` already finds the takes.
