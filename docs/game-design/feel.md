# Feel

The biggest gap between these games and cheap clones isn't mechanics. It's that every number arrives as a physical event with motion and sound. Most of it is client-side and cheap. Names in brackets are evidence.

## Feedback on every action

Each player action needs at least three of: **a world reaction, a popup, a sound, a camera response, a HUD response.**

- **The world reacts under the player.** Keycaps sink 1.4 studs (fast down, slow return) with a randomised switch click [Keyboard Escape]. Pads sink 0.22 studs with a gold sparkle [Sushi]. Water spawns an expanding ring decal at every step (×3.2 over 1.3–1.8 s) [DONT SPLASH].
- **"+N" popups** on every gain: Back-out scale-in, a random arc, 0.85 s life [Keyboard Escape]. Colour them by source or multiplier tier: x3 yellow, x9 cyan, x25 pink, x100 red [Keyboard Escape, Break and Steal]. Throw them from the source toward the bar they fill [Spider Arm].
- **Hits:** damage numbers with gravity, a random tilt and Back easing. A white Highlight flash for 0.12 s, a small camera shake and coloured particles. "CRIT 48!" in red [Bug Evolution]. Squash the target to 0.85 scale, shake it 18° and throw debris chunks [Break and Steal].
- **The HUD answers.** Punch the counter to 1.1–1.12 scale on gain [Depth Incremental, Sushi]. Lerp the counter instead of jumping it. Flash the XP bar on big gains [Bug Evolution].
- **Fly rewards to where they're counted.** Orbs send neon wisps with trails into your body [Bug Evolution]. 12 gold coins fly from the register to you [Sushi]. **Hold the counter back until the coins land**, so the number visibly comes from its cause [Clean a Painting, DONT SPLASH].
  - Coin count = log10(amount) × 4 + 2.5, giving 5–18 coins.
  - Each coin follows a Bezier curve, 0.05 s after the previous one.
  - Each landing plays a click that rises in pitch, and the last coin plays a bigger burst [DONT SPLASH].
- **Use the camera.** FOV punch +5° to +10° on big moments. Slow-mo to 0.3x for 0.45 s on the hero action [Steal and Drive]. Escalate the effects with the stacked boost: FOV kick +1.2° to +5°, camera roll, shake, sparkles, police-light edge flashes, and an "x5 BOOST!" callout [Spider Arm].
- **Raise pitch on chains.** +2.5% per tree node owned, capped at 20 nodes [Depth Incremental]. +4% per worm in a chain, up to 10. Three package shakes at pitch 1.0, 1.1, 1.2 [Scare Your Neighbor]. Meter ticks rise in pitch as it fills [Throw Food]. Randomise repeated sounds between 0.92 and 1.08 pitch [Depth Incremental].

## Staging: turn numbers into objects

- **Show income as things moving.** In [Sushi] a fish is reeled in, arcs over the fisherman, splashes, floats down a channel and tumbles into a pool. A customer eats a visible plate and gets a gold "+$X" over their head, then coins pop at the register. In [Clean a Painting] visitors walk the hall and pay at each painting. In [Steal and Drive] customers react with emoji and speech bubbles ("Take my money!") and tip. A ticking label is the cheap version.
- **Turn waits into shows.**
  - The truck backs in, its doors swing open, and crates arc onto marked slots [Clean a Painting].
  - Minions walk out and smash your package, with "-N" numbers and a health bar like "4,350 / 201.6K" [Scare Your Neighbor].
  - An egg's growth bar ends with a "READY" label that pops with Elastic easing [Steal An Egg].
  - Treadmill time plays short videos on a phone overlay [Steal An Egg].
- **Let the world fill as you grow.** Restaurant seats = floor(log10(rate) × 1.5) + 1, capped at 12 [Sushi]. Pets are sized by weight [Break and Steal]. The free visual progression is on a log scale.
- **Switch the screen into a mode during danger.** While carrying loot: a red vignette pulsing on a 0.6 s sine, a "RUN!" banner pulsing to 1.15x every 0.4 s, a sting sound, the side HUD hidden, and a big Drop button [Break and Steal]. Chase music only while you carry loot [Scare Your Neighbor]. Red and blue light vignettes plus a "CATCHING UP / LOSING YOU" bar [Steal and Drive].
- **Make failure a beat, ideally a funny one.**
  - Crashes are graded Light / Medium / Heavy / Knockout, each with its own roll, FOV punch, vignette and sound. A knockout shows a kinetic joke line and a red DNF stamp [Backseat Rally].
  - Getting caught flings you (75 forward, 45 up), ragdolls you for 1.5 s and flashes the screen red [Scare Your Neighbor].
  - A jumpscare lasts 1.3 s, then 2 s of static, then black [DONT SPLASH].
  - Failure that's fun to watch is sticky.
- **Use cinematics once, at the first big moment.** A two-shot camera orbit on your first scare [Scare Your Neighbor]. Your troops taking the first camp [Mini War]. Hide the HUD during cinematics; letterbox bars help [Throw Food].
- **Make clips.** Auto-pick the 3 best moments of a run (speed, near-misses, air, crashes) and replay them as shaky portrait phone footage from spectators [Backseat Rally].

## Celebrations scaled to importance

Match the size of the celebration to how rare or important the event is. Spamming big effects on common events cheapens them.

| Tier | Event | Treatment |
|---|---|---|
| 0 | Every action (step, hit, pickup) | "+N" popup, click, small world reaction |
| 1 | Purchase, small goal | Toast, counter punch, sound, short sparkle |
| 2 | Level up, stage win, new item | Banner (0.6 s Back scale), a sound, an FOV punch, a trophy flying into the counter; "Level 10 > Level 11 / Arms 5 > 6 / +1 ARM!" [Spider Arm] |
| 3 | Transformation, rebirth, new zone, tutorial complete | Full screen, takes the camera for 2–5 s: "YOU EVOLVED!" [Bug Evolution], "REBIRTH N ACHIEVED!" with charge, boom and fireworks [Depth Incremental], a zone banner sliding in [Scare Your Neighbor] |
| 4 | Very rare drop | Longer, can't be skipped, server announcement: Lucky Catch tiers LUCKY! → GODLY LUCK!!! → IMPOSSIBLE!!! at 5%, 2%, 1%, 0.2%, 0.02%, 0.001% [Throw Food]; a `[GLOBAL]` chat broadcast [Depth Incremental] |

- **Scale by formula, not by hand.** Hype = clamp((log10(odds/luck) − 2) / 4, 0, 1). A 1-in-100 find gets no fanfare; a 1-in-1M find gets the biggest pop, scaled 1.3 + 0.5 × hype [Depth Incremental].
  - Reveal zoom takes 0.9 s, or 2.2 s for "dramatic" catches: Legendary+, mutated, new or lucky [Throw Food].
  - The reveal holds 3 s for owned or common items and 5 s for new ones [Throw Food].
  - The banking effect scales by rarity band [Steal and Drive].
- **Account for habituation.** Repeated rewards count for less, and a long dry spell should be broken with a good moment [Throw Food].
- **Itemise payouts.** Tick reward lines in one at a time, each with a pop and a coin sound rising 0.03 in pitch per line up to 1.25x ("STAGE FINISH +100 XP", "GOLD MEDAL", "CLEAN RUN", "DUO BONUS"). Then fill the XP bar, then LEVEL UP, then unlock cards [Backseat Rally]. The player sees *why* they earned it.

## Reward reveals

**Recipe: anticipation → build-up → burst → show → stats → collect.** Let the player hear that it's big before they see it.

| Game | Sequence and timings |
|---|---|
| [Break and Steal] hatch | spin 1 s → shake 1.75 s → explode → show 2.5 s; for big rolls, a "Grow" phase up to 4 s while a tick speeds up from 0.25 s to 0.05 s gaps and rises from pitch 1.0 to 2.0, with rumble and shake, before BIG / HUGE / TITANIC |
| [Clean a Painting] crate | shake, crack twice, burst over 2.15 s (+2 s build-up for Rare+) → painting spins 1.92 s → holds 1.7 s with name, income, "RARE / 1 in 412", "NEW PAINTING DISCOVERED!" |
| [Clean a Painting] frame roll | slot machine of ≥18 ticks slowing over 3.8 s, a click per tick, a thunk on the last, the odds table visible with the result highlighted, and the delta "$60 → $144 (+$84)" |
| [Scare Your Neighbor] package | 3 shakes rising in pitch → neon pillar and ring in the rarity colour → item pops 0.05 → 1.15 → 1 over 0.34 s → flies in an arc into the player over 0.55 s, spinning and shrinking |
| [Throw Food] catch | a POV walk-up as the animal approaches the food (2–5 s, A/B tested) → zoom out → name typed letter by letter with rising ticks → rarity outline and dust; "tap to continue" after 1 s |
| [Sushi] boat hire | a 2.2 s slot-machine roll on a glowing silhouette, which becomes the fisherman, who walks off the boat to his spot |

- **Show odds and the value change** on the reveal card.
- **Use rarity colour everywhere**: outline, label, panel stroke, particles. Use animated multi-stop gradients from Mythic up [Break and Steal].
- **Make paid reveals reuse the free reveal**, so the paid item feels like the free one, only better [Scare Your Neighbor].
- **New discoveries get their own beat.** A "New fish!" card flies to the screen centre, then shrinks into the Index button, teaching where the Index is [Sushi].

## Sound

- **Give every verb a sound, ideally a satisfying one.** Mechanical-keyboard switch packs, which the game also sells [Keyboard Escape]. Randomised scrub strokes [Clean a Painting]. Tape, paper, stamp and box-close sounds [My Small Business].
- **Music follows state, with crossfades of 1.5–4 s.** Base, neighbourhood and chase tracks [Scare Your Neighbor]. Day, night, title, combat and boss tracks, with combat music kicking in when you're hit [Bug Evolution]. A dedicated POV-reveal track [Throw Food]. Classical music in the gallery [Clean a Painting]. Night music for the 5-min night [Steal An Egg].
- **Match the sound to the size of the impact.** The landing is louder and lower-pitched the further you threw. Wind volume and pitch follow the projectile's speed [Throw Food].
- **Let sound sell the fantasy.** Voice chat is filtered like a helmet radio (high-pass 360 Hz, low-pass 3.3 kHz, compression, static, squelch clicks), so shouting pace notes sounds like real rally [Backseat Rally].
- **Budget sounds.** Pool them (40 sounds, a 30 ms throttle [Keyboard Escape]) and cap SFX per frame [Break and Steal].
- **Give purchases their own sound**: a "Dev Product" sound on Robux buttons [Scare Your Neighbor], a "Magic Reveal" on a successful purchase [Break and Steal].

## Cost and care

- **Run juice on the client** from a few sound and texture assets [Depth Incremental, Bug Evolution].
- **Respect `ReducedMotionEnabled`** [Clean a Painting].
- **Cull and budget** so busy scenes run on phones. Spread unit spawning over frames [Mini War]. Adapt quality to FPS: drop below 40 FPS, recover above 54 [Break and Steal].
