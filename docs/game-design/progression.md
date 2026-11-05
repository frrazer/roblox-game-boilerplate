# Progression

Stats, gates, curves, prestige, collections and the timers that bring players back. Numbers are from the 16 studied games; names in brackets are evidence.

## Stats and currencies

- **Use one spend currency and one power stat.** The spend currency (Cash, Wins, Coins) comes mostly from passive income. The power stat (Speed, Grip, Scare, throw power) comes from active training: a treadmill, rig, pull-up bar or trainer. Two stats work if each has a clear job: Scare gets you through the door and Speed gets you home, each with its own trainer, gear line and Robux ladder [Scare Your Neighbor].
- **Add a currency only if it loops back.** [Depth Incremental] has 13 currencies, but each has an upgrade board with a ×Cash upgrade, and deeper steps are priced in the new currency so you must use each system. Event currencies get their own shop, and their milestones pay main-game items [DONT SPLASH, Mini War].
- **Reveal currencies when they matter.** A new pill appears in the stack only once relevant [Depth Incremental].
- **Show the rate, not just the total.** Put "~$X/hr" under cash [Steal and Drive], "+$X/s" over each item [Scare Your Neighbor, Throw Food], and Chef Skill $/s on a sign [Sushi].
- **Format big numbers** with K, M, B, T, Qa, Qi, Sx… Let counters lerp toward the true value instead of jumping [Depth Incremental].
- **Stack multipliers, and show each one.** Use HUD chips like "REBIRTH +50%", "BOOST x2.0 0:12", "x3 TRAIN" [Spider Arm], or a boost row like "NIGHT HUNT · 1.5x XP" [Bug Evolution]. A multiplier hidden in a stats page doesn't motivate anyone.

## Visible progress

- **Change the avatar.** More arms [Spider Arm], a bigger body with a new life stage [Bug Evolution], a costume that morphs you over 1.6 s [Scare Your Neighbor].
- **Change the base.** The pen fills with animals sized by weight (up to 7.5x) [Break and Steal]. Seats and plates in the restaurant scale with log10 of income [Sushi]. The gallery goes from a grey shop to a two-storey museum [Clean a Painting]. Fences go Wood → Iron → Gold → Diamond [Throw Food].
- **Show the locked future.**
  - Unbought rooms appear as concrete pads with blue tape outlines and a sign [My Small Business].
  - The x100 rig stands next to your x1 rig [Spider Arm].
  - Unfound items show as "???" silhouettes [Bug Evolution, Throw Food].
  - Unreached biomes are visible down the lane [Steal An Egg, Throw Food].
- **Always show the next goal and the distance to it.** For example "5 ARMS +1 AT LV 11" [Spider Arm], "best 1:18.5 (6.6 s to gold)" [Backseat Rally], "Level 1/25" on the rebirth bar [Keyboard Escape], "Only 3 levels until Monarch!" [Bug Evolution].

## Gates

- **Prefer soft stat gates over locked doors when the verb tests the stat.**
  - Guard speed scales with your speed ÷ the zone's requirement, from 0.4x yours to 4x, with a "close call" blend between 0.6x and 1x [Break and Steal].
  - Scare chance = S^5 / (S^5 + R^5 × 1/3). That gives 75% at the requirement, ~8% at half and ~99% at double [Scare Your Neighbor].
  - Under-levelled players can try and sometimes win. Overreaching fails often; being slightly over-levelled almost always succeeds, so progress feels decisive.
- **Use hard gates where a new layer of content starts:** a boss key plus a rebirth [Depth Incremental], "beat NORMAL twice" for Hard and the event map [DONT SPLASH], room price plus a level [My Small Business], parent bug grown to adult plus coins [Bug Evolution]. Gate on collection when collecting is the game: Floor 2 opens at 200 paintings discovered, not at a cash price [Clean a Painting].
- **Print the requirement on the gate, coloured against the player's value**: "NEEDS 65 GRIP" in green or red [Spider Arm], or a room sign with the exact speed needed computed from the chase geometry [Steal An Egg].
- **Make distance the difficulty.** Later zones are longer (93 → 900 studs [Break and Steal], 93 → 1,090 [Steal An Egg]), so the run home grows as the chaser gets faster.

**Where games disagree:** [Keyboard Escape] uses a solid wall until the first win, while the chase games never lock. Lock to protect new players or pace content releases. Leave gates soft wherever failing is itself fun.

## Curves and real numbers

| What | Values seen | Use |
|---|---|---|
| XP per level | ×1.1 per level with a hand-tuned fast early table [Spider Arm]; ×1.15 [Keyboard Escape]; 100×L, quadratic [Criminal Sim]; 26+4L+0.5L^1.5 [Bug Evolution] | Exponential for sims, polynomial for skill games. Always hand-tune the first ~10 levels to be fast. |
| Felt stat from power | walk = 18 + p^1.59 × 82, p = log10(P/10)/8, soft cap 100 at 1e9 [Break and Steal]; 16 + log10(S) × 15.67, cap 250 [Scare Your Neighbor]; min(10 + 2L, 300) [Keyboard Escape] | Log-map the big number so speed stays playable. Optionally add a "Slow Mode" toggle [Break and Steal]. |
| Tier price vs output | pickaxe ~4x damage per tier; pull-up bars 6–8x price for 2x XP [Throw Food]; buildings ~10x price for ~1.5x output [Mini War] | Price grows faster than output, so the curve stretches unnoticed. |
| New zone income | each biome ~25–40x the last [Throw Food]; car worlds cost 6–70x more each [Steal and Drive] | The new zone makes the old base obsolete, which pushes the player forward. |
| Per-step price | ×1.115 per step, then ×1.16 [Depth Incremental]; upgrades cost base × 1.4–4^level | Round to 2 significant figures. |
| Early payback | a $150 farm pays back in 36 s [Mini War]; crate 1 in ~4 visits, crate 21 in ~4,000 [Clean a Painting] | Instant early, slow late; that late gap is where skips sell. |

- **Rarity odds within one pool:** 46 / 30 / 14 / 6.5 / 2.3 / 0.85 / 0.3 / 0.05% [Break and Steal]. A three-tier pool: 75 / 20 / 5% [Sushi boats]. Mutations: 13% ×1.5, 4% ×3, 2% ×5, 1% ×10, 0.5% ×20 [Throw Food].
- **Size rolls:** most results 0.85–1.05x, with rare 2x–35x. Income ∝ size^1.8–1.85, so a 4x pet earns ~13x [Steal An Egg, Throw Food].
- **Protect against bad luck.**
  - A guaranteed Rare–Epic after 330 s of play [Break and Steal].
  - Crate pity at 6–12 rolls, shown as "Epic or better in 3" [Backseat Rally].
  - Anti-repeat: divide the last catch's weight by 200 [Throw Food].
  - Roll rarest-first, falling through once an item is maxed, so every fossil can be completed [Depth Incremental].
  - A server-side "excitement" meter quietly upgrades catches after a dry spell [Throw Food].
- **Discourage farming honestly.** After 3 runs of the same stage within an hour, each further run pays ×0.92, down to a floor of 65%, and the cut is shown on the line: "STAGE FINISH · REPEAT 92%" [Backseat Rally].

## Rebirth and prestige

- **Most hits have none.** 12 of 16 rely on exponential ladders, new zones and collections instead. Only 4 reset progress [Keyboard Escape, Spider Arm, Depth Incremental, Bug Evolution]. Add rebirth only if the core is a single stat that would otherwise cap out, as in a sim.
- **Make a rebirth a new thing, not a button.** Each new bug restarts at Lv 1 as an egg with a new body, life stages and abilities [Bug Evolution]. Each rebirth opens the next physical layer, with new art, music and a new currency [Depth Incremental].
- **Numbers that work:**
  - Rebirth available at level 10 + 10 × rebirths, giving +0.5x XP each [Spider Arm].
  - Rebirth tiers from level 15 → x1.5 up to x4e20 across 32 tiers, keeping Wins [Keyboard Escape].
  - Rebirth cost set just above the cost of clearing the layer (layer ≈ 2.3B, rebirth 3.9B), giving ×10 Cash so the replay is fast [Depth Incremental].
  - First rebirths should come within minutes (adult at Lv 12, 15, 28) [Bug Evolution].
- **Show "YOU GET / YOU KEEP"** and current vs next multiplier, use a two-tap "ARE YOU SURE?", then play a full-screen cinematic [Depth Incremental, Keyboard Escape]. Sell or award permanent "keeps on rebirth" upgrades to soften later resets [Depth Incremental].
- **Prestige without reset:** building tiers that raise every upgrade cap [Clean a Painting], world unlocks [Steal and Drive], mastery stars per character [Bug Evolution].

## Collections

- **Make the Index pay, not just track.**
  - First discovery pays 100–120 s of that item's income plus a stat reward [Break and Steal, Scare Your Neighbor, Steal An Egg].
  - Completing a rarity set pays 600 s of income and 6x the stat reward [Scare Your Neighbor].
  - A completed crate set gives a permanent +5% to +50% income [Clean a Painting].
  - Each car claimed gives +1% Luck forever [Steal and Drive].
  - Completing a biome unlocks a stronger bat [Steal An Egg].
  - Tokens from claims fund rerolls [Clean a Painting].
- **Show the count and what's missing:** "3 / 436 discovered", "0/50 STOLEN · +0% LUCK · CLAIM ALL", "???" silhouettes, a red badge with the claimable count capped at "99+".
- **Make every item an individual**: a name, model, colour and tagline ("Bolted together from junk. Mostly works." [Spider Arm]). 24 named fish beat "Tier 1–24" [Sushi]. Real paintings beat "Painting #34" [Clean a Painting].
- **Handle duplicates fairly.** Duplicates pay credits, some crates never give a duplicate, and a fully owned pool is labelled "COMPLETE · every roll pays credits" [Backseat Rally].
- **Let players hunt.** A throw-power slider lets you aim for a specific biome to fill a missing entry [Throw Food].

## Retention

**Put something on a timer at every horizon:**

| Horizon | Examples |
|---|---|
| Seconds | market price every few s [Sushi]; boost bubbles every 3.5–6.5 s [Spider Arm] |
| 4–5 min | crate truck every 240 s [Clean a Painting]; shop restock every 5 min [Mini War]; night reset every 5 min [Steal An Egg]; Golden Key every 300 s [Keyboard Escape]; coins every 240 s [Bug Evolution] |
| 15–30 min | weather rolls every 15 min [Mini War] or 30 min [Break and Steal]; Craft Fair every 30 min [My Small Business]; a Titanic Egg every 30 min |
| Hourly | free abilities on a 60-min cooldown [Sushi]; hourly quests and the Void Gate [Bug Evolution] |
| Daily | 7-day streak; 3 daily quests; free Lucky Roll |
| Weekly | Saturday update with a countdown [Mini War, Keyboard Escape]; weekly contracts and leaderboards [Backseat Rally] |
| Season | 14–25 day events with their own currency |

- **Daily streak:** 7 days, resetting on a miss. Make **day 2 big**, because that's when a new player decides whether to return: "HUGE!" 100 wins + 5 levels [Spider Arm], a free bug on day 2 [Bug Evolution]. Make **day 7 a jackpot**: a free car [Steal and Drive], 10 God Modes [Criminal Sim]. Scale cash days to income.
- **Playtime rewards:** slots at 2, 4, 6, 8, 10, 13, 17, 25, 31, 41, 51 and 61 min [Keyboard Escape]; mystery gifts at 2, 5, 10, 20 and 30 min, then "FREE CAR AT 45 MINUTES" [Steal and Drive]. Start the next timer only after a claim, so rewards don't pile up [Bug Evolution].
- **Quests:**
  - Show one linear goal at a time [My Small Business, 82 goals].
  - Use story quests that walk through every system in order [Bug Evolution, 26 steps].
  - Daily or hourly quests are seeded so every server gets the same ones.
  - Weekly contracts pay a streak bonus of +100 per consecutive week [Backseat Rally].
  - Mark anything claimable with a pulsing "!" pin.
- **Catch leavers.** When the Roblox Esc menu opens, show **one** personalised reason to stay, picked by priority: reward ready, "Only 3 levels until Monarch!", streak at risk [Bug Evolution]. Or a "WAIT! FREE GIFT!" 2x XP for 5 min on a 30-min cooldown [Spider Arm], or "Your paintings earn cash while you're offline!" [Clean a Painting].
- **Run live ops.** Admin-abuse shows with server-wide boosts and spin reels [Keyboard Escape, Spider Arm, Throw Food]. Scheduled map drops with a countdown and a wall-breaking cutscene [Throw Food]. Roblox Event RSVPs. Give returning players 3x offline earnings plus a 7-day comeback track after 14+ days away [Mini War].
- **Free social rewards:** like + join the group for a modest boost, framed as a "LIMITED TIME!" gift (+10K Speed [Break and Steal]; $500/day [Criminal Sim]; auto-buy unlocked [Depth Incremental]). Add codes.

**Where games disagree:** most use a daily login streak. [My Small Business] and [Scare Your Neighbor] skip it, relying on a 30-min fair, a 20-min special delivery and walk-in offline cash. A short-cadence shared event can replace the calendar.

## Offline earnings

| Game | Rate | Cap |
|---|---|---|
| [Throw Food] | 2 min of income per hour (~3%) | 48 h |
| [Clean a Painting] | 5% (Night Shift pass ×2) | 6 h, min 5 min away |
| [Break and Steal] | 10% | 5 h |
| [Steal and Drive] | 12% → 6% by world | 2 h |
| [My Small Business] | 40 × level coins/h | 8 h |
| [Mini War] | — | 4 h, extended by research and vaults |
| [Steal An Egg] | — | 10 h |

- **Rule:** pay 3–12% of the live rate, cap it at 2–10 h, and sell or research cap extensions. Live play must stay far better.
- **Make the claim physical.** A money pile in your base that you walk into [Scare Your Neighbor, Steal An Egg], a glowing fish crate on the pier [Sushi], or a "WELCOME BACK – AWAY FOR 3h 12m – $12,480" screen with COLLECT and 2X for R$49 [Steal and Drive, Throw Food, Break and Steal].
- **Advertise it while they play** so leaving never feels like losing: "Your items earn $X/Day offline!" over your base [Scare Your Neighbor]; "Your country works offline!" under the top bar [Mini War]; reminder toasts every 5–10 min [Throw Food].
