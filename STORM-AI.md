# Storm link — Jev behind the decisions

Storm Chaser can ask [Jev](https://typesafe.ai/blog/introducing-system-one-models-and-jev),
TypeSafe AI's System One model, to make some of the judgement calls the game
makes about a moment. There are two: **which of Mateo's recorded lines he says
next**, and **the Storm Director** — how hard the next wave of debris presses.

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

## The Storm Director

Before every wave of debris, the game picks one of three pacing bands and the
Director may re-rank that choice:

| Band | Space between waves | How fast debris flies at you |
|---|---|---|
| `ease` | ×1.18 | ×0.80 |
| `hold` | ×1.0 — the shipped tune | ×1.0 |
| `press` | ×0.86 | ×1.15 |

Those are the same two levers the **EXTRA REACTION TIME** setting already moves,
by about as much, so every band is a pace this game is known to play well at.
`press` is the milder of the two, because making a ten-year-old's game harder
deserves more caution than making it easier.

**`hold` is always the fallback**, so a game with no storm link is not merely
close to the shipped campaign, it is bit-for-bit that campaign — which is what
the 710 checks run against. `verify_advisor` measures both levers in the running
game rather than reading them off the constants, and asserts each band moves
them by exactly what it declares.

One rule lives in the game rather than in the question: **the Director never
presses against EXTRA REACTION TIME.** Somebody switched that on having decided
this player needs more room; the Director may ease further, never crowd. Policy
stays in code, so it holds however the answer comes back.

It is asked at `Advisor.CONSEQUENTIAL` (0.75) rather than `HARMLESS`, because
the player feels this one. Refusing to act is always safe: the fallback is the
tune the game shipped with.

## Confidence, and why the bar is low

Choice answers carry a `confidence` derived from the probability distribution
across the options. TypeSafe's guidance is that **a threshold is not one number:
it scales with what being wrong costs.** `Advisor.HARMLESS` (0.5) is the floor
for a decision whose worst outcome the player would not notice, and it travels
with the question rather than being one setting for the whole game.

It is deliberately low. A spread distribution usually means several options were
*acceptable*, not that the answer was bad — and a high bar would throw the answer
away in exactly the case the question was worth asking, which is the tie between
a near miss and a flying cow. A decision that changes difficulty or progress
belongs at a higher floor, passed per call.

## What it costs to be wrong

Nothing that cannot be turned off in one toggle. For Mateo, the worst case is a
less apt line than the game would have picked, thirteen seconds apart, with the
opening line still guaranteed and the flying cow still winning ties. For the
Director, it is one wave of debris paced as if the run were going better or
worse than it is — inside a range the game already ships as an accessibility
setting, never against that setting, and reconsidered at the very next wave.

## What is not done

- **The Storm Director.** Every few seconds, score how the run is going and
  choose the next hazard wave from the waves the game already spawns — lean in
  when they are cruising, ease off after a bad stretch. It is the same seam and
  the same rules, and it is the one with real engagement upside. It touches what
  the campaign suites guard, so it is its own piece of work.

  **Not done, and it matters:** the two questions are asked separately, and one
  request is in flight at a time. The Director asks every wave, roughly twice a
  second at pace; Mateo asks at most once every thirteen. So the Director wins
  the slot almost every time and Mateo's question is usually dropped, falling
  back to the game's own choice. The fix is the one the docs point at —
  **independent questions over the same state go in one request and are answered
  in parallel** — which means batching both into a single call rather than
  racing them. Until that is built, the line selection is mostly running local.

  On `Score`: an earlier note here called it the right primitive for the
  Director. It is not, and `Choice` is. What the game needs is a bounded action
  — one of three bands it knows how to play — and `Choice` returns the
  distribution over exactly those actions. `Score` would give a continuous
  reading of how the run is going that the game would then have to threshold
  itself, which is a second policy to tune for no gain here. It would earn its
  place if that reading were wanted for something else too.
- **Nobody has played this with a live key.** The request and response shapes
  were checked field by field against TypeSafe's published API reference — the
  `{state, model, questions}` body, the choice question's `criteria` map, and the
  `{model, answers, usage}` response whose Choice answer carries `choice`,
  `probabilities` and `confidence`. They match, and they are exercised against
  synthetic bodies in `verify_advisor`. The first live call is still ahead.
- **More of Mateo's lines.** The system is worth most when he has more to choose
  between. A new line needs an entry in `LINES` and its `.wav` beside the
  others; `mateo_takes()` already finds the takes.
