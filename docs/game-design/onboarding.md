# Onboarding

The first minutes decide whether a player stays. Every top game rigs them for success, teaches by doing, and keeps the shop out of the way. Game names in brackets are evidence.

## The first minute

**Goal: the player does the core verb and gets a real reward within 60 seconds, and cannot fail.**

- **Show the fantasy before any menu.** Use a skippable ~20 s intro that acts out the hook [Spider Arm], a broadcast-style reel of the stage behind the title screen [Backseat Rally], or the monster looming in an aquarium at the end of the lobby [DONT SPLASH].
- **Spawn facing the action, with the first target in sight.** You face straight down the obstacle corridor, with chevrons on the floor [Keyboard Escape]. Your first enemy camp is 130 studs ahead on your own road [Mini War]. The next step glows as a ghost in front of you [Depth Incremental]. The whole lane runs out to a portal at the end [Steal An Egg].
- **Rig the first reward.**
  - The first egg is reserved for you and has 3 HP, and the first two hatches are forced to Common, then Uncommon [Break and Steal].
  - You start with exactly enough cash for one crate ($20 = crate 1), and everyone gets the same first painting [Clean a Painting].
  - The first climb needs 54 grip and you start with 100. The first armature costs 1 Win and the first climb pays 1 Win [Spider Arm].
  - The first pull-up bar costs $1, and the first throw is set to 55 studs [Throw Food].
  - The first egg grows in 3 s [Steal An Egg]. The first farm pays itself back in ~36 s [Mini War].
- **Spawn tutorial targets just for this player** so nobody steals them: a tutorial bug that only you can attack [Bug Evolution], an egg that only you can break [Break and Steal].
- **Make the first danger beatable.** The first guard runs at the player's base speed of 16 [Steal An Egg]. The first chaser waits 1.5 s before chasing and has a grace period [Scare Your Neighbor]. In [Steal and Drive] the tutorial run can't be lost: health never drops below 25%, traffic is cleared 260 studs ahead, and a missed jump rewinds to the bail step.
- **Make the first levels very fast.** Level 1 takes 60 XP and the first new arm comes at level 3 [Spider Arm]. Levels 1–30 take 3–5 s each, and the second biome is about 2 minutes away [Throw Food].
- **Pick safe defaults.** Set difficulty to EASY marked "RECOMMENDED", and if the host does nothing, auto-create the party after 15 s [DONT SPLASH]. An idle new player should still end up playing.
- **Give ownership early when the fantasy is personal.** "Create your Brand!" (name dice, colours, emoji logo, live preview on your shop sign and box) is step 1 [My Small Business].

## The tutorial

- **One verb per step, completed by doing it in the real game.** Typical length is 3–11 steps: 3 [Depth Incremental], 4 [Clean a Painting], 6 [Spider Arm, Bug Evolution], 8 [Steal An Egg, Mini War], 11 [Steal and Drive]. Step titles are imperative verbs: "Place a House!", "Rush your Army!", "Collect materials!", "Sell Materials!" [Mini War].
- **Cover the whole loop once, including the first purchase.** The tutorial chains climb → win → train → climb → buy → train [Spider Arm]. [Break and Steal] covers break → steal → escape → place → earn → treadmill → buy → equip once each.
- **End by teaching the long-term goal.** [Bug Evolution] ends by making you open the Bug Tree, click your next bug, track it and turn on its arrow, so the meta loop is learned in two minutes. Close with a named next goal: "Next: reach Lv 12 to unlock a new bug!" [Bug Evolution], "Something stirs 110m below…" [Depth Incremental], a caged dragon visible from spawn [Steal An Egg].
- **Pay out at the end.** "TUTORIAL DONE! +10 WINS" [Spider Arm]. "+50 coins and bonus XP for 10 min" [Bug Evolution]. Confetti [Steal and Drive].
- **Work out the step from save state, not a counter.** Use rules like "0 animals → Throw step" and "animals but none placed → Place step" [Throw Food], or `chooseTarget` priorities that run on every state change [My Small Business]. This can't desync or be skipped by accident.
- **Freeze the game for each new input.** "HOLD W TO BOOST" pauses play until you do it, and the steal prompt freezes you mid-air [Steal and Drive].
- **Word prompts for the player's device**: "hold SPACE / A / JUMP" [Spider Arm], keyboard / gamepad / touch labels [Steal and Drive, Backseat Rally, Criminal Sim].
- **Show rather than explain.** A cinematic of a worker walking to the farm teaches that farms need workers [Mini War]. A demo sponge scribbles the cleaning gesture [Clean a Painting]. A one-time cutscene frames your first scare [Scare Your Neighbor].
- **Text format:** one line, top centre, typed out at 0.02–0.04 s per character, popping in at scale 0.8 → 1 (Back easing) with a "Pop" sound. Show live progress inside the text: "Earn $42/$100" [Break and Steal].
- **Teach new rules at the moment they matter**, not up front. Each room states its rule on entry in one line [DONT SPLASH]. "Hairpin: brake early, then handbrake" fires 160 studs before a tight corner [Backseat Rally]. A loading screen teaches one rule with a 3D model of the tool [Criminal Sim].
- **Skipping.** Make intros skippable. [Mini War] hides Skip only on step 1, so everyone places one house, and skips the tutorial for returning players who already have >$1,500. Pause the tutorial during chaotic live events [Steal An Egg].

**Where games disagree:** pure environment with no text [Keyboard Escape, Criminal Sim, DONT SPLASH] versus strict step chains [Break and Steal, 20 steps]. Use environment-only when there's one verb and a linear path (walk forward, press the glowing button). Use steps when there are several stations or currencies to connect.

## Guiding the player

- **Always point at exactly one target.** Use the strongest pointer the step allows:
  - **World:** a Beam from the player's feet to the target, updated every frame [Scare Your Neighbor, Mini War, Throw Food, Sushi, Bug Evolution]. Or an animated floor trail of chevrons recalculated by pathfinding every 0.4–0.5 s, leading to the nearest valid target [DONT SPLASH, Criminal Sim, Clean a Painting]. Add a Highlight outline on the target and a bobbing arrow or marker above it.
  - **UI:** dim everything except the button (a full-screen mask with a hole, pulsing) [Mini War, Bug Evolution], plus a bobbing pointing hand or arrow. Pulse the button's outline (stroke 5 → 8 px, 0.7 s loop) [DONT SPLASH].
  - Use one colour for all guidance, e.g. gold (255,205,0) [Throw Food] or amber [Backseat Rally].
- **Remove the guide once it's reached** [Criminal Sim]. After the tutorial, keep a quiet "next thing" pointer: a floating label over the right station reading emoji + verb + count, e.g. "Print 2 Ocean Bookmarks" [My Small Business]; a ◎ button that draws a beam to the tracked quest target [Bug Evolution]; a HUD chip like "5 ARMS +1 AT LV 11" [Spider Arm]. Let players turn arrows off in settings after onboarding.
- **Physically block wandering.** The wall into stage 2 stays solid until your first win, and the win button is recoloured bright yellow with a beam and particles on it [Keyboard Escape]. Walled corridors keep players on the path [Spider Arm].
- **Start with a stripped HUD and reveal it in waves.**
  - During the tutorial show only level, HP, stamina, XP, coins, RUN and BITE. Gameplay buttons pop back after the tutorial (scale 0.6 → 1, Back easing), and paid buttons follow 180 s later [Bug Evolution].
  - Buttons appear at the step that needs them, with a wiggle and a pop sound [My Small Business].
  - Show a currency pill only once that currency matters [Depth Incremental].
  - Unlock systems with progress: trainers cost $500 to unlock [Scare Your Neighbor]; the portal opens at 5 wins and the shop at 1,500 wins [Keyboard Escape]; the market board waits until you own 5 fishermen [Sushi].
- **Nudge idle players by name**: "Don't forget to steal a car!" after 45 s idle, and "Lambo ahead. Steal it!" for a rare car on the road [Steal and Drive].

## Holding offers back

- **Sell nothing during the tutorial.** Every game that has a tutorial does this. Hide paid buttons, suppress notification dots and "you can afford" toasts [Keyboard Escape, Clean a Painting], and delay offline-earnings popups until after it [Clean a Painting].
- **Keep a quiet period after it.**
  - No popups for 75 s, and paid HUD buttons hidden for 180 s or until the first big transformation [Bug Evolution].
  - No pack offers for 150 s or 6 throws [Throw Food].
  - No pass ads until 5 orders have shipped [My Small Business].
  - Nothing for sale until $50 net worth [Sushi].
  - No toasts in the first 12 s after joining [Break and Steal].
- **Queue popups; never stack them.** Daily reward first, the R$9 starter kit only after it closes, and the favourite prompt only after both (with a 1.5 s settle) [Criminal Sim]. Each offer checks no other popup is open, waits until the player has been out of combat for 8 s, and hides itself after 15 s [Bug Evolution].
- **Make asks right after the first success.**
  - Favourite prompt: 3 s after the first visitor pays, only with no modal open [Clean a Painting]; 4 s after the tutorial [Depth Incremental]; after 4 runs [Steal and Drive].
  - Event RSVP: after 10 min, only while standing on safe ground [Spider Arm]; after 20 min, and only once the player has reached a mid-game biome [Throw Food].
- **Time the first paid offer to the first big high, and keep it cheap.** A starter pack 6.5 s after "You grew up!" (R$29, first 24 h only) [Bug Evolution]. A "NEW PLAYER OFFER" on the first rewards screen, 3 s in [Backseat Rally]. See monetisation.md for prices.

## Measure it

Log every onboarding step as a funnel event with playtime: 16 steps from join to second-stage win [Keyboard Escape], 11 numbered beats [Steal and Drive], each packing step [My Small Business], each room cleared [DONT SPLASH]. [Bug Evolution] streams the new player's UI state every second for 5 minutes. A/B test the guidance itself: guided arrows vs none [DONT SPLASH], 5 s vs 3 s vs 2 s reveal length [Throw Food]. The step where players drop is the step to fix.
