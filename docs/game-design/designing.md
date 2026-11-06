# Designing the game

How to pick the fantasy, build the loop, and make every system pull in one direction. Evidence is from 16 top Roblox games; game names are in brackets.

## Fantasy and hook

- **State the fantasy in one line, and put the verb in it.** The title is the pitch: "+1 Spider Arm", "Clean a Painting", "Throw Food For Animals", "DONT SPLASH" (the rule *is* the title). Taglines do the same: "ONE DRIVES. ONE READS THE ROAD." [Backseat Rally], "PAY OFF THE DEBT - DON'T GET CAUGHT." [Criminal Sim]. If you can't say it in one line, the player won't get it in one minute.
- **Make the power fantasy physical.** The stat must show on the avatar or in the world, not just in a counter. Arms get added to your back and really climb with IK [Spider Arm]. Your bug grows 3.5% per level up to 5x [Bug Evolution]. Your level is your real walk speed [Keyboard Escape]. Your pier grows out to sea row by row [Sushi]. If you can make a stat cosmetic or make it physical, make it physical.
- **Borrow pull from something players already love.** Real masterpieces like Nighthawks and The Night Watch [Clean a Painting]. Rally culture with pace notes and Group B cars [Backseat Rally]. ASMR unboxing videos [My Small Business]. The movie stunt of jumping between moving cars [Steal and Drive]. A Backrooms pool [DONT SPLASH]. Recognisable things do your marketing for you.
- **Apply one theme to everything.** In [Keyboard Escape] the candy keyboard runs through the floors (keycaps), walls (chocolate bars), item names, sound packs ("Creamy", "Clacky" switches) and UI. In [Criminal Sim] every menu is a "BLACKBOX" laptop, the shop is a black-market stall, difficulty is notes pinned to a cork board and the leaderboard is a "MOST WANTED" wall. A generic grey menu breaks the fantasy before play starts.
- **Hook test:** can you show the whole game in a 20-second intro with no menus? [Spider Arm] does: the avatar sprouts an arm, "+1 SPIDER ARM!", "TRAIN TO GROW MORE ARMS!", "CLIMB YOUR WAY TO THE TOP!".

## The core loop

Nearly every game studied runs the same skeleton. Use it unless you have a reason not to:

1. **Active verb** that earns: run, climb, throw, steal, scrub, pack, drive.
2. **Bank** the result at home: place the pet, hang the painting, park the car.
3. **Passive income** from what you banked, earning while you do step 1 again.
4. **Spend** on the power stat (treadmill, pull-up bar, trainer) and on income (better items, more slots).
5. **Go further**: the next zone, stage or biome, where rewards are worth more.

Keep one cycle short: 10 s per steal [Steal An Egg], 12–15 s per throw [Throw Food], 1–4 min per rally stage [Backseat Rally], a 240 s crate delivery [Clean a Painting].

### What makes the loop feel good

- **The verb is fun with the numbers hidden.** Scrubbing grime off a painting [Clean a Painting], keycaps that sink and click under your feet [Keyboard Escape], folding and taping a parcel [My Small Business], leaping onto a moving car [Steal and Drive]. Test: would someone do it for 30 s with no reward? If not, add physical feedback (see feel.md) or change the verb.
- **Put a skill or decision moment inside the idle loop.** It can be a chase home with a guard behind you [Steal An Egg, Break and Steal, Scare Your Neighbor], a timing meter [Throw Food], timing deposits to a live market price of 0.5x–1.5x [Sushi], choosing a box size [My Small Business] or popping boost bubbles while training [Spider Arm]. **Keep the skill bounded.** The throw meter adds only 0–20 studs, so a BAD throw never ruins progress [Throw Food].
- **Risk after reward.** You own the loot only when you get it home. You steal the car, then outrun police to the getaway truck [Steal and Drive]. You grab the package, then a chaser runs you down [Scare Your Neighbor]. That creates a mini-story on every run, and that failure moment is where offers sell.
- **Build greed into the map.** Better eggs spawn deeper in the zone, and bigger animals raise the speed you need to escape [Break and Steal]. Heavy loot is worth the most but slows you down [Criminal Sim]. The player chooses their own risk on every run.
- **Rotate between two or three bottlenecks** so the best next move keeps changing. [Sushi] has supply (fishermen), conversion (chef $/s) and timing (market). In [Mini War] the civilian cap blocks the economy, and conquest is how you raise it.
- **Never leave the player waiting.** Orders arrive up to 6x faster when your order slots are empty, and 85% ask for something you already have in stock [My Small Business]. If there's a wait, stage it as a show (see feel.md).

## One number or one rule that drives everything

The strongest games hang every system on **one gating number** or **one rule**.

- **One number**, shown against the requirement at every gate: Speed vs the room's required speed [Steal An Egg], Grip vs "NEEDS 65 GRIP" in green or red [Spider Arm], Scare vs "YOUR SCARE CHANCE 42%" [Scare Your Neighbor], Level vs "Level 8 recommended" [Keyboard Escape], throw power vs the biome you land in [Throw Food], Luck vs the car ladder [Steal and Drive], and in [Depth Incremental] "damage per hit = your cash per second" against a boss.
- **One rule**: "water = noise = death" [DONT SPLASH]. Dry landings are silent. Tools are noise you choose to make. Upgrades tune noise. Paid pushes force noise onto other players. Every feature is a variation on the rule.
- **Every side system feeds the number.** In [Depth Incremental] each of 13 currencies has an upgrade board, and one of its three upgrades always multiplies Cash. New Index entries pay Speed [Steal An Egg]. Index claims give +1% Luck [Steal and Drive]. Base conquest raises the civilian cap [Mini War]. If a system doesn't feed the core number, cut it or rewire it.
- **Failure names the number.** "OUT OF GRIP!" [Spider Arm]. "Out of time! Tip: more cash per second = more damage per hit" [Depth Incremental]. The player always knows why they failed and what fixes it.

Recipe:
1. Pick the number. It should gate the next area and be raised by the grind.
2. Show the requirement on every gate in the world, coloured green or red against the player's current value.
3. Make failure physical (caught, ragdolled, fall) and readable.
4. Offer the fix immediately: a free path (train) and a paid path (a pack sized to the exact gap; see monetisation.md).

**Two numbers, two kinds of satisfaction.** Pair an exploding "flex" number (Speed 251Qi, Speed Power 1.2B) with a felt stat on a log curve (walk speed 16 → ~250). You get big-number dopamine and a character that stays controllable [Keyboard Escape, Break and Steal, Scare Your Neighbor, Steal An Egg]. Curves are in progression.md.

## Depth

- **Add one new verb at a time, each feeding the core.** [Depth Incremental] opens a door every 20 steps onto a new mechanic (dig, worms, minecart, fishing, title rolls), so early on a new toy arrives every couple of minutes.
- **Roll several things on every reward** so old zones never go dead: species × size (0.1x–35x, income ∝ size^1.85) × mutation (x1.2–x3.5) [Steal An Egg]; animal × 5 mutations × 40 size steps [Throw Food]; painting × frame roll [Clean a Painting].
- **Give choices real trade-offs.** Traits come with a downside in red, e.g. Sprinter: +15% speed, −6% bite speed [Bug Evolution]. Buyer offers come in LOW/FAIR/GOOD/GREAT bands with a countdown [Steal and Drive]. Difficulty lists its quota, its XP multiplier and three plain bullets on what gets harder [Criminal Sim]. Extra monsters give +25% coins each [DONT SPLASH].
- **Give each stage one new rule stated in one line**: "SINKING PLATFORMS: Platforms sink while you stand on them. Keep moving." [DONT SPLASH]. Give each stage a new theme and hazard [Spider Arm, Keyboard Escape].
- **Let automation be the arc.** The player does every chore by hand, then hires them away one at a time: Boxer, Designer, Packer, Courier… [My Small Business], and Cashier → Deck Hand → Manager [Sushi]. Each hire removes a chore the player knows, so its value is obvious. The fun shifts from labour to management.
- **Build content from data tables** so you can ship a lot of it. Rooms are generated from gap/jump/count tables [DONT SPLASH], every timing lives in Balancing modules [Backseat Rally], and the games ship 1,800 steps [Depth Incremental], 436 paintings, 164 animals and 50 cars. A game with three zones has the loop but no long tail.

## Choosing and adapting reference games

- **Proven skeletons recur.** Three games are the "steal a ___" formula: run into a zone, grab, chase home, items earn in a pen, a treadmill trains speed, speed packs are offered on a catch [Steal An Egg, Break and Steal, Scare Your Neighbor]. Two are "+1 per step" sims welded to a climb or obby [Keyboard Escape, Spider Arm]. Starting from a proven skeleton is fine.
- **Keep the mechanism, change the verb and the fantasy.** Each hit adds one twist: smash the egg with a pickaxe and get a staged hatch [Break and Steal]; size and mutation rolls plus a short-video phone on the treadmill [Steal An Egg]; a visible scare-chance S-curve and minions that break packages [Scare Your Neighbor]; the steal becomes a highway stunt with a showroom [Steal and Drive].
- **What to carry over:** the gating number, the map as a progress bar, offers at the moment of pain, the staged reveal, the rigged first minute.
- **What copycats drop** (every report lists the same things): the juice on the core verb, a felt stat behind the big number, honest gate signs, offers sized to the player, rewards staged as objects. Copy those first; the skin matters least.
- **When adapting, write down:** the reference's gate number and your equivalent; every feedback beat on its core verb; every place it sells and what pain each offer answers.

## Social and multiplayer

- **Share a server and make progress visible.** 5–8 plots side by side or around a hub, each with the owner's headshot, name and $/s or "WORTH $X" on a sign [Throw Food, Steal and Drive, Scare Your Neighbor]. Your flag flies on every base you capture [Mini War]. Flex comes from 30 titles with their own font, glow and aura [Criminal Sim], statues of the top 3 on podiums [Criminal Sim, Backseat Rally] and rank tags in chat [Depth Incremental, DONT SPLASH].
- **Reward playing with friends:** +10% per friend in the server, capped at +30% to +100% [Keyboard Escape, Break and Steal, Steal An Egg, My Small Business]. Fill the world with friends' avatars as NPCs: 70% of customers [Sushi], buyers and drivers [Steal and Drive].
- **Sell social purchases.** A server boost names the buyer: "X BOOSTED THE SERVER!" [Spider Arm, Keyboard Escape]. Server Luck helps everyone [Steal An Egg]. A like-goal bar pays everyone $1,000 when it fills [Criminal Sim].
- **Design co-op so each role's output is the other's input.** The co-driver reads the map and calls corners, and the driver can't do the stage well without it [Backseat Rally]. **Never block on a partner**: there's an AI co-driver, an open seat that strangers can drop into, and +40 XP for duos. Downed teammates get a 15 s rescue window that turns failure into teamwork [DONT SPLASH].
- **Run session lobbies on timers.** The first player in is host and gets a 45 s setup, the truck waits 30 s for others, then leaves 5 s after it's full [Criminal Sim]. A 20 s countdown, and the party creates itself after 15 s if the host idles [DONT SPLASH]. After a run, offer "Rejoining your crew in N" [Criminal Sim].
- **Protect new players from PvP.** Use a newbie shield to Lv 20, no hit over 12% of max HP, safe zones only low levels can enter, and spawn protection [Bug Evolution]. Light PvP works: a bat knocks a carried egg loose [Steal An Egg].
- **Put the whole server on shared clocks:** a 5-min night reset with a 3-2-1 wall [Steal An Egg], a Craft Fair every 30 min [My Small Business], hourly quests seeded so every server gets the same three [Bug Evolution].
- **Where games disagree.** Mandatory co-op dies in empty servers, and optional co-op with no reward is ignored. Make it optional and rewarded. Small servers (5 players [Throw Food]) keep every plot visible; larger ones suit PvP and conquest maps.

## GAME.md ends with the build checklist

GAME.md's last section is `## Build checklist`: one `- [ ]` line per thing to build for the first full version (each system, each screen, each piece of content), followed by every line of `done.md`. It's the team's to-do list and the definition of "ready for Frazer's review": Otis ticks a box (`- [x]`) when it's built and checked, and T3 keeps the team working while any box is unticked. Make each box concrete and checkable ("Shop sells 8 gum flavours from a data table", not "Shop"). When Frazer gives feedback, add new boxes for it.

## Why games work: checklist

Before building, check the design against each line:

- [ ] Fantasy fits in one line, and the title contains the verb.
- [ ] The core verb is fun with numbers hidden, and has sound, motion and a world reaction.
- [ ] The power stat is visible on the avatar or in the world.
- [ ] One number (or rule) gates progress, shown at every gate in green/red.
- [ ] Every side system feeds that number.
- [ ] Failure is physical, readable, and tells the player what to raise.
- [ ] There is a skill or decision moment, bounded so it never ruins progress.
- [ ] Loot is only yours once banked (risk after reward).
- [ ] Flex number explodes, felt stat grows on a log curve.
- [ ] Map is the progress bar; the next goal is visible from spawn (world.md).
- [ ] First reward lands within 60 s and the first minute can't be failed (onboarding.md).
- [ ] Rewards roll more than one thing, and rare ones get bigger reveals (feel.md).
- [ ] Offers appear at pain or payoff, sized to the gap, with a free path (monetisation.md).
- [ ] Something is always about to happen: timers at minute, hour, day and week horizons (progression.md).
- [ ] Other players can see your progress, and friends make you stronger.
- [ ] One theme is applied to world, items, sounds and UI.
- [ ] Content comes from data tables, with enough of it for weeks.
