# Building Roblox UI that looks polished

All 16 studied games share one habit: **they define a look once, in code, and every element is built from it.** It matters more than any single colour or font. Cheap UIs style each frame by hand, so nothing matches. Polished ones call `Kit.button(color)` and never touch a UIStroke directly (+1 Spider Arm `Kit`, Bug Evolution `UI.Skin`, Steal and Drive `ArcadeKit`, Throw Food `UIKit`/`ShopUI`, My Small Business `UIKit`, Depth `paint()`).

## 1. Pick a family, then commit

| Family | Used by | Recipe | Fits |
|---|---|---|---|
| **Toy sticker** (the strong default) | 11 of 16: Speed Keyboard, Spider Arm, Break and Steal, Steal an Egg, Mini War, Scare, DONT SPLASH, Depth, Steal and Drive, Throw Food, Clean a Painting | Saturated gradient fills, thick dark outline, white text with a dark stroke, a faint world-matching texture, icons that overflow | Simulators, tycoons, obbies, collectors, young audiences |
| **Material skin** | Sell a Million Sushi (wood), Clean a Painting (parchment), My Small Business (clipboards, ribbons, paper tags), Criminal Sim (laptop bezel) | One physical object or texture from the fiction, tinted per role | Any game with a strong setting. You can layer this on the toy recipe. |
| **Restrained glass** | Bug Evolution, Backseat Rally, Criminal Sim | Near-black panels at 0.04–0.38 transparency, 1 px white hairline at 0.82–0.88, flat fills, a single accent colour | Realistic, competitive or "adult" themes, racing, survival |

Whichever you choose, **make the UI material match the world material.** Studded worlds get a stud tile on buttons (Speed Keyboard, Spider Arm, Break and Steal, Mini War, Steal an Egg, Scare). A racing game gets a checker pattern (Steal and Drive), a sushi bar gets wood, a museum gets parchment. To adapt the toy recipe to another theme, keep the structure (gradient, outline, lip, gloss, texture) and swap three things: the ink colour (use a dark shade of the theme's hue, never pure black on warm or pastel themes, as My Small Business does with browns and plums), the texture tile (studs, wood, paper, stripes or checker), and the fonts.

## 2. The theme module (write this first)

Put all tokens in one ModuleScript and read every value from it. Sushi's `SushiStyle.Colors` and Throw Food's `UITheme` are the model.

```lua
local Theme = {}
Theme.Ink = Color3.fromHex("0B0838")          -- ONE outline colour for every stroke
Theme.Font = Font.fromName("FredokaOne")
Theme.FontDisplay = Font.fromName("LuckiestGuy")
Theme.Text = Color3.new(1,1,1)
Theme.TextureTile = "rbxassetid://..."        -- white tile matching the world: studs, wood, paper, checker
Theme.Panel = Color3.fromHex("202A40")         -- neutral, darker than any card
Theme.Card  = Color3.fromHex("344262")
Theme.Role = {                                 -- colour = meaning (section 6)
  Buy = "5CD660", Robux = "5CD660", Cash = "5CD660", Gift = "54A0FF",
  Close = "F0545C", Info = "54A0FF", Gold = "FFD65A", Locked = "686C80" }
Theme.Rarity = { Common="C8C8C8", Uncommon="58D660", Rare="408CFF",
  Epic="AA54FF", Legendary="FFAA28", Mythic="FF4D8A" }
Theme.Stroke = { text=0.08, button=0.06, panel=0.015 }  -- ScaledSize fractions
Theme.Corner = { button=UDim.new(0.15,0), card=UDim.new(0,12), panel=UDim.new(0,18), pill=UDim.new(1,0) }
Theme.Tween = { pop=TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
  out=TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
  quick=TweenInfo.new(0.15, Enum.EasingStyle.Quad) }
function Theme.shade(c, t) return c:Lerp(t > 0 and Color3.new(1,1,1) or Color3.new(), math.abs(t)) end
return Theme
```

Then write component helpers: `slab(color)`, `button(color, text, icon)`, `text(size, color)`, `panel(title, icon)`, `pill`, `badge`, `bar`, `toast`, `popIn`, `popOut`, `punch`, `countTo`, `flyTo`, `attachJuice`. Build every screen only from these. Add a global pass that runs on every GuiButton added under PlayerGui and attaches hover, press and sound. Six games do this (Speed Keyboard, Mini War `ButtonAnimation` tag, Scare, My Small Business `ClickyButton`, Break and Steal `ButtonTweenConfig`, DONT SPLASH). Give it an opt-out attribute. Bug Evolution goes further: its skin pass normalises fonts, corners and strokes on any ScreenGui, with a `NoSkin` opt-out.

## 3. The slab: one recipe for buttons, pills, tiles and headers

Build the layers in this order, bottom to top. The values are where the games agree.

1. **Lip.** A frame in the base colour darkened to 0.6–0.66 (Depth uses face×0.66, Backseat C×0.62, DONT SPLASH mixes 45% toward black), showing 4–7 px below the face. It reads as the side of a physical block. You can also use a hard `UIShadow` with blur 0, offset 5–10 px, in a dark tint (Spider Arm).
2. **Face fill.** A vertical `UIGradient` (Rotation 90): lighter at the top, base in the middle, darker at the bottom. Formula: top = base lerped 28% to white, bottom = base lerped 22% to black (Spider Arm `Kit.block`). The cheaper form, used widely, is a white BackgroundColor tinted by a white→grey gradient (`#FFFFFF → #A5A5A5–#D7D7D7`), so one gradient shades any colour (DONT SPLASH, Depth, Sushi, Backseat). Never ship a flat fill in the toy family.
3. **Texture.** A tiled image (`ScaleType.Tile`, ~40–56 px tile) at 0.62–0.82 transparency, clipped by the same UICorner. Studs, wood, paper, stripes or checker, matched to the world.
4. **Gloss.** A white strip over the top 38–45% of the face at 0.72–0.78 transparency, or a thin 3–4 px shine line 5 px from the top. Optionally add a diagonal glint: 2–3 white bars at ~20°, clipped by the face (`ClipsDescendants`), never a CanvasGroup, which is slow and blurry on mobile (Break and Steal, Steal and Drive, Throw Food).
5. **Double outline.** An outer dark stroke in the ink colour, plus an inner light rim (white at 0.55–0.8 transparency, or the fill lerped 60% to white). This "sticker edge" appears in 8 games. Break and Steal derives both strokes from the fill: inner = lerp 60% to white, outer = lerp 60% to black. If you can't use two UIStrokes on one instance, put the outer stroke on a `Rim` frame 8 px larger (DONT SPLASH).
6. **Label.** White heavy text with an ink stroke, inset in the face. Put an icon on the left at about 1.1–1.3× the button height so it **overflows** the edge, tilted −8° to −12°.

```lua
function Kit.slab(color: Color3, parent: Instance, size: UDim2)
  local lip = Instance.new("Frame")               -- 1. lip (also the outer outline)
  lip.Size, lip.BackgroundColor3, lip.Parent = size, color:Lerp(Color3.new(), 0.35), parent
  Instance.new("UICorner", lip).CornerRadius = Theme.Corner.button
  local o = Instance.new("UIStroke", lip)         -- 5a. outer ink outline
  o.Color, o.Thickness, o.StrokeSizingMode = Theme.Ink, Theme.Stroke.button, Enum.StrokeSizingMode.ScaledSize
  local face = Instance.new("Frame")              -- 2. face, leaves a lip below it
  face.Size, face.BackgroundColor3, face.Parent = UDim2.new(1,0,0.88,0), color, lip
  Instance.new("UICorner", face).CornerRadius = Theme.Corner.button
  local g = Instance.new("UIGradient", face); g.Rotation = 90
  g.Color = ColorSequence.new(Theme.shade(color, 0.28), Theme.shade(color, -0.22))
  local tex = Instance.new("ImageLabel")          -- 3. world-matching texture
  tex.Image, tex.ScaleType, tex.TileSize = Theme.TextureTile, Enum.ScaleType.Tile, UDim2.fromOffset(48,48)
  tex.ImageTransparency, tex.BackgroundTransparency, tex.Size, tex.Parent = 0.7, 1, UDim2.fromScale(1,1), face
  Instance.new("UICorner", tex).CornerRadius = Theme.Corner.button
  local gloss = Instance.new("Frame")             -- 4. gloss strip
  gloss.Size, gloss.Position = UDim2.new(1,-10,0.4,0), UDim2.fromOffset(5,3)
  gloss.BackgroundColor3, gloss.BackgroundTransparency, gloss.Parent = Color3.new(1,1,1), 0.75, face
  Instance.new("UICorner", gloss).CornerRadius = Theme.Corner.button
  local i = Instance.new("UIStroke", face)        -- 5b. inner light rim
  i.Color, i.Transparency, i.Thickness = Color3.new(1,1,1), 0.7, 0.03
  i.StrokeSizingMode, i.BorderStrokePosition = Enum.StrokeSizingMode.ScaledSize, Enum.BorderStrokePosition.Inner
  return lip, face                                -- 6. caller adds label + overflowing icon to face
end
```

**Stroke weights.** Panels 3–5 px, buttons and cards 3 px, text 2–4 px, at a 1080p reference. Always set `UIStroke.StrokeSizingMode = ScaledSize` (text 0.06–0.12, button 0.03–0.085, panel 0.01–0.02), or rescale pixel strokes by `min(viewport)/1080` in a stroke-scaler module. Fixed pixel strokes are the number one reason copycat UIs look thin on PC and blobby on phones. Eight games call this out.

**Corners** set the personality: blocky 0–2 px (Steal an Egg, Scare, Break and Steal 0.01 scale) for a LEGO feel; pill-ish 0.15 scale or 8–14 px for buttons (Steal and Drive, Depth); fully round only for badges, chips, pills and knobs. Panels use 16–30 px or 0.02–0.05 scale. Don't mix more than three radii.

**Title text.** Draw a duplicate label in the ink colour offset ~5% down behind the white title, for a solid extruded shadow (Break and Steal, Mini War, Steal an Egg). Big numbers get a gradient fill: gold `#FFF896→#FFD628→#FF9614` for rewards, or chrome white with a grey band at 0.46–0.76 (Speed Keyboard).

**Fonts.** Fredoka One is the default (8 games). Add Luckiest Guy or GothamSSm Black/Heavy for display numbers and titles. Restrained themes use Montserrat + BuilderSans (Bug Evolution), Gotham Heavy Italic (Backseat) or Roboto Condensed (Criminal Sim). Use at most two families, plus at most one expressive accent font for the single most important button (Criminal Sim's Permanent Marker PLAY). Give money its own face or style so the eye finds it (Sushi uses HighwayGothic gold; Steal an Egg uses italic Heavy). Use fixed `TextSize`s from a short list in the theme module, and let one UIScale on the root scale everything. Avoid `TextScaled`: it fills the glyph atlas and makes text flicker on low-end phones (the UI checker flags it), even though many of the studied games use it.

**Images.** Use chunky, glossy, 3D-rendered or outlined cartoon icons, and **live ViewportFrames** for anything that exists as a model: pets, cars, items, trainers (Bug Evolution, Scare, Backseat, Sushi, Throw Food, Criminal). Auto-frame the camera from the bounding box at FOV 26–40, with a slow yaw swing. Show undiscovered items as black silhouettes of the real model, not a padlock. Put a sunburst/ray image at ~0.6 transparency and 1.5× icon size behind every hero icon. 9-slice is optional: only 3 games use it. Gradients, strokes and tiles do the work.

## 4. Layout

**HUD map.** Most of the 16 games converge on this. Keep the centre ~50% of the screen empty.

| Zone | Contents | Evidence |
|---|---|---|
| Left-middle column | 2–6 nav buttons (Shop, Index/Inventory, Rewards). Square icon tiles ~86–145 px at 1080p, label on the bottom edge | 14 of 16 |
| Bottom-left | Currency counters stacked, biggest currency lowest | 9 games |
| Right-middle | Offers (passes, starter pack, x2) and drawers for frequent lists | Spider Arm, DONT SPLASH, Criminal Sim, Steal an Egg, Scare |
| Bottom-centre | The main progress bar (level/XP) with boost buttons under it, or the one primary action (PLAY, SCARE, BITE) | Spider Arm, Speed Keyboard, Throw Food, Bug Evolution, Steal and Drive |
| Top-centre | Transient only: zone name, event timer, toasts, tutorial line | nearly all |

**Context swapping.** Hide or replace HUD by activity. Use a chase HUD that hides side menus and shows a giant Drop button (Break and Steal), a treadmill HUD (Steal an Egg), a driving HUD that is one corner card (Steal and Drive), hide everything during cinematics (Throw Food), and reveal HUD buttons one by one through the tutorial (Bug Evolution, My Small Business). Gate monetisation buttons behind a small progress threshold (Sushi shows them at $50 net worth).

**Menu structure.** Use a centred modal at 55–70% width, 55–85% height, locked with `UIAspectRatioConstraint` (1.3–2.0). Then:
- **Header bar** about 13–17% of the panel height, in the menu's own colour, which matches its HUD button (green Shop, cyan Index). The title is left-aligned, and the icon is ~1.2× the header height, breaking out of the top-left. Some games tilt the banner −3° or use a folded ribbon.
- **Close X** at the top-right, red, square or round, overlapping the corner or flush in the header.
- **Body:** a neutral dark (or cream) well. Use one long ScrollingFrame ordered by value, with centred section dividers (`~ Game Passes ~`, a pill with lines on both sides). Add a tab rail on the left or floating outside the right edge that jumps to sections.
- **Coin chip with "+"** inside every shop-like menu (DONT SPLASH, Bug Evolution).
- **One menu open at a time.** Opening a menu closes the rest, damage closes menus (Bug Evolution), and walking away closes world panels (Break and Steal, Sushi). Use drawers that slide in from the right for frequent tasks instead of modals.

**Scaling.** Use one of two approaches. Never mix ad-hoc offsets with neither.
- **Reference canvas plus UIScale** (code-built UIs): author in pixel offsets at 1920×1080 (Spider Arm, Depth) or about 1150×700 (Bug Evolution, My Small Business). Set `scale = clamp(min(vw/W, vh/H) × touchBoost, 0.4–0.5, 1.15–1.6)`. Backseat scales by height only and widens the root, so wide screens get more room instead of bigger UI.
- **Scale plus aspect locks** (StarterGui-built): Scale sizes with `UIAspectRatioConstraint` on every container, anchored to corners (Steal an Egg, Mini War, Speed Keyboard).

On top of either:
- Use a touch boost of ×1.18–1.25 and a minimum tap target of 44–48 px.
- Set `ScreenInsets = DeviceSafeInsets` and `IgnoreGuiInset = true`.
- Fit windows with `min(scale, (vw−24)/w, (vh−inset−24)/h)`.
- Add a **compact mode** below 600 px height or 1000 px width that restructures content (two panes become tabs, a list becomes a picker) rather than just shrinking it (Clean a Painting, DONT SPLASH).
- Swap key hints per input: "[R] REFILL" on keyboard, a button glyph on gamepad, nothing or "TAP" on touch.
- Auto-select the first button when a window opens, and make B close it.

## 5. Components

- **Currency counter:** an icon at 115–130% of the row height breaking out of the left end, a big stroked number in the currency colour, and a green "+" breaking out of the right end that opens the matching shop. Use compact formatting (`12.3K`, `2.6T`). Show a rate tab ("+5/s") above it if income is passive. Count up over 0.45–0.6 s Quad/Quart Out, then pop the pill 1.12–1.25 → 1.
- **Primary button:** a slab in the buy colour with the Robux glyph or currency icon before the price. Put a square **gift button** beside every Robux price (8 games).
- **Price pair:** on anything buyable with both currencies, show the soft-currency price and the Robux price side by side (Break and Steal, Steal an Egg, Scare, Mini War, Speed Keyboard). Use the same affordable/unaffordable colouring in the world.
- **Card / shop item:** a full saturated gradient card (the brightest thing on screen), a sunburst behind a big icon, a stroked title, one-line benefit with the number highlighted in RichText (`x2` in green), and a full-width buy button docked at the bottom. Add a corner ribbon rotated 6–14° ("FOREVER", "BEST VALUE", "LIMITED", "-74%"). For anchoring, add a struck-through "was"/"worth" price and a "SAVE x%" tag. Show odds on gacha cards with the rarest tile largest, rainbow-bordered and on spinning rays. Grow the art with tier: one shoe, a pile, then a chest (Scare, Steal and Drive).
- **Tabs:** slab buttons. Active tab = menu colour; inactive = grey `#606072`; locked = "???" or a padlock.
- **Close button:** red slab with a white stroked X, 40–74 px, aspect 1. On hover, scale ×1.075 and rotate the X 10–90°.
- **Badge:** a red circle at 40–50% of the parent's size, anchored (0.5, 0.5) at the parent's corner (1, 0). White stroke, "!" or a count capped at "99+". Pulse it on change, and repeat a reminder pulse every ~1.6 s.
- **Toasts:** a stack, top-centre or bottom-centre, max 3–4, hold 2–4 s (or 3 s + 0.25 s per word, clamped 4–10). Colour by type: white info, green success, red error, gold reward. Highlight keywords in RichText. Give each type its own sound. **Dedupe:** a repeated message re-pops the existing toast to 1.15–1.18 instead of stacking.
- **Progress bar:** a dark pill track, a gradient fill, and a centred stroked "x / y" label. Tween the fill 0.15–0.35 s. Keep a minimum 4% fill so it never looks empty. To keep rounded ends from distorting, tween the fill's `UIGradient.Offset` instead of Size (Speed Keyboard). Change fill colour with state (cyan, then gold, then red as a resource runs out). Use pips for level-capped upgrades. A bar whose length grows with the stat's max is itself a progress signal (Spider Arm).
- **Reward popup:** a ladder sized to the event. Floating "+N" < toast < sliding banner (level up) < stamp with confetti < full-screen takeover (dim to 0.25–0.5, rays, big icon or 3D model, "Tap anywhere to continue"). Add an input guard of 0.4–0.6 s so mashing doesn't skip it. Queue popups; never stack two.
- **Daily rewards:** a 7-tile grid, with day 7 double-size, gold or rainbow, on rays and marked "JACKPOT". Today's tile is green CLAIM, future tiles are grey LOCKED, and a countdown bar runs underneath.
- **Failure and "can't afford":** never fail silently. Turn the counter red, shake it ±6–7 px 3–4 times, and show "NEED $X MORE" (Steal and Drive, Sushi), or flash the button label ("Need more!") for 1.2 s (Scare). Play an error sound.

## 6. Colour meaning and restraint

Fix the meanings once and never break them:
- **Green** = buy, go, claim, money (all 16).
- **Red** = close, danger, cancel.
- **Gold or yellow** = reward, highlight, premium.
- **Blue** = info, XP, secondary, gift.
- **Grey** = locked or owned.
- **Rainbow, animated** = the single top offer or the top rarity tier.
- **Robux:** where cash and Robux appear together, give Robux its own colour (purple in Mini War and Scare, pink in Break and Steal). Where only Robux is sold, use the buy green.
- **Each menu owns a hue,** and the HUD button that opens it uses the same hue (Steal an Egg, Scare, Break and Steal), so players navigate by colour.
- **Rarity ladder:** Common grey `#C8C8C8`, Uncommon green, Rare blue, Epic purple, Legendary gold/orange, Mythic pink/red. Tiers above that get animated multi-stop gradients. Reuse the rarity colour on cards, names, world billboards, outlines and toasts. If a rarity colour is dark (luminance < 0.35), lighten it 35% for text (Scare).

**Restraint** is what separates these games from noisy copies:
- **Neutral containers, loud content.** Panel bodies are flat charcoal, navy or translucent black (`#323232`, `#202A40`, black at 0.35). The saturated cards inside then look premium. Monetised cards are the brightest thing on screen, on purpose.
- **Only money moves.** Idle animation goes on offers and unclaimed rewards only. Everything else is still until touched (DONT SPLASH, Criminal Sim, Spider Arm).
- **Restrained themes allow one accent per screen** (Backseat's amber; Bug Evolution's colour appears only on actions).
- **Warm themes** use warm brown backdrops and strokes, not black (My Small Business backdrop `#6E4640` at 0.65).

## 7. Motion

| Action | Values the games agree on |
|---|---|
| Hover (mouse only) | Scale 1.04–1.1, 0.12–0.2 s Back Out or Quad. Rail icons also rotate −6° to +12°. Hover sound. Correct the position so it grows from the centre whatever the AnchorPoint |
| Press | Scale 0.86–0.94 in 0.06–0.1 s, release with Back Out 0.18–0.35 s. Slab buttons instead drop the face 3–4 px onto the lip. Click sound with random pitch 0.93–1.2 |
| Springs (alternative) | Open: damping 0.55, frequency 5 (one overshoot). Close: damping 1, frequency 7. Press stiffness higher than release (Steal an Egg 42 in, 26 out) |
| Menu open | UIScale 0.55–0.9 → 1, 0.18–0.36 s Back Out (or slide up 18%, 0.18 s Quart Out). At the same time: black dim 1 → 0.45–0.55 over 0.2 s, BlurEffect 0 → 8–16 over 0.25 s, camera FOV punch (±5–10, or 70 → 50 for a "zoom in"). Open sound |
| Menu close | Faster than open: 0.06–0.18 s Quad In to 0.8–0.92, then hide. Restore blur and FOV. Token-guard so a stale close can't hide a reopened menu |
| Staggered entrance | Children every 0.04–0.08 s, 0.3–0.4 s Quint Out (cards, reward lines, death-screen stats) |
| Gain pop / punch | 1.12–1.35 → 1, 0.22–0.4 s Back Out or Elastic Out. Punch only on real changes, not passive ticks (Throw Food: punch only when the change > 1.5× income rate) |
| Flying coins | 3–18 icons, count = `log10(amount)×3..4 + 2.5..3`. Burst outward 0.18–0.3 s, then fly to the HUD icon along a Bezier with a random ±35% side control point, 0.35–0.6 s ease-in (t², Exponential In or Back In), 0.03–0.05 s apart, max ~24 in flight. **Hold the counter back and add each coin's share as it lands.** Landing tick pitch rises 3–5% per coin, capped at +50% |
| Toast | In 0.15–0.35 s (pop 0.6 → 1 Back, or slide), hold 2–4 s, out 0.2–0.4 s Quad In |
| Idle (offers only) | Sunburst 10–25°/s; shine band sweep 0.7–0.8 s every 2.6–4.5 s with random offsets; bob ±3–8 px; wobble ±3–8°; breathe ±3–5%; sticker wiggle every 2.6–4.5 s. Offset neighbouring tiles so they alternate. Use additive `max(0, sin)` pulses, never flashing. Run all of it from one RenderStepped loop that skips hidden objects |

The fly-to-counter pattern (Clean a Painting, DONT SPLASH, My Small Business, Spider Arm, Break and Steal) is the most reusable reward trick:

```lua
function Kit.flyTo(amount, fromScreenPos, counter)          -- counter has :Hold(n) / :Add(n)
  local n = math.clamp(math.floor(math.log10(math.max(amount,1))*3 + 3), 3, 18)
  counter:Hold(amount)                                      -- displayed value lags the real one
  for k = 1, n do
    local coin = Kit.icon(counter.Icon.Image, fromScreenPos) -- clone of the HUD icon
    local burst = fromScreenPos + Vector2.new(math.random(-90,90), math.random(-90,40))
    Kit.tween(coin, 0.25, "Back", {Position = UDim2.fromOffset(burst.X, burst.Y)})
    task.delay(0.35 + k*0.04, function()
      local target = counter.Icon.AbsolutePosition + counter.Icon.AbsoluteSize/2
      local ctrl = (burst+target)/2 + Vector2.new((math.random()-0.5)*0.7*(target-burst).Magnitude, 0)
      Kit.bezier(coin, burst, ctrl, target, 0.45, function(t) return t*t end) -- ease-in
      coin:Destroy(); counter:Add(amount/n); Kit.punch(counter.Pill, 0.12)
      Kit.sound("CoinTick", math.min(1 + 0.05*(k-1), 1.5))  -- rising pitch
    end)
  end
end
```

Use Back Out for appearing, Quad or Quart In for leaving, Elastic for one dramatic punch per screen, and Quart Out for counters. Respect `GuiService.ReducedMotionEnabled` and offer a setting to reduce effects (Clean a Painting, Depth, Spider Arm). **Spend the motion budget on rewards, not chrome.** Sushi's menus open instantly, but every gain flies to its counter.

## 8. Build a screen, step by step

1. Write down the screen's single job and its one primary action. That action gets the buy/go colour and the biggest button. Everything else is quieter.
2. Choose the container: a modal (rare tasks), a right drawer (frequent tasks), a world-anchored panel that closes when the player walks away, or a HUD element.
3. Build it with `panel(title, icon)`: header in the menu's hue with an overflowing icon, a close X on the corner, a neutral body, and a one-line helper sentence under the header ("Levels are bought in order.").
4. Fill the body with helper components only. Order the content by value, best offer first. Put section dividers between groups.
5. Add live data: prices from MarketplaceService ("..." while loading), owned/locked states, timers and odds. Swap the buy button for a grey "OWNED" when owned. For locked items, say exactly what unlocks them ("BEAT NORMAL 0/2").
6. Wire input: hover/press/sound (automatic via the global pass), gamepad first selection, B to close, key hints, and touch target size.
7. Wire motion: open/close tweens with blur and FOV, a staggered entrance for cards, and idle motion only on the hero offer.
8. Wire feedback for every outcome: success (fly-to-counter, toast), failure (red shake plus reason), and purchase (confetti, flash, "Thank you" popup).
9. Test at 1920×1080, 1280×720, a 844×390 phone (touch) and 4K. Check strokes, text sizes, overlap with the joystick and jump button, and safe areas.

## 9. Polish checklist (what agents miss)

- [ ] Every stroke uses ScaledSize or a viewport stroke scaler. One ink colour throughout.
- [ ] No flat fills in the toy family: a gradient on every surface, plus a gloss or texture.
- [ ] Icons overflow their buttons and pills, and title icons break out of headers.
- [ ] All text is stroked, at fixed sizes from the theme (no TextScaled). Nothing under ~11 px on a phone.
- [ ] Every button has hover, press and a sound, applied globally.
- [ ] One menu open at a time. Blur, dim and FOV behind it. Close is faster than open.
- [ ] Counters never snap. They count up, and gains fly in from their source.
- [ ] Popups are queued, not stacked. Toasts are deduped and capped at 3–4.
- [ ] Failure always says why and what's missing.
- [ ] Locked content shows a silhouette or "???" plus the unlock condition, never just nothing.
- [ ] Prices show a gift button. Cash and Robux sit side by side. Anchor ("was") prices are real.
- [ ] HUD centre is empty. HUD elements swap with context and hide during cinematics.
- [ ] Badges ("!" or a count) on any button with something claimable.
- [ ] Touch: ×1.2 scale, 44–48 px targets, nothing under the thumbsticks. Gamepad: first selection, B closes, glyph hints.
- [ ] Idle motion only on offers and unclaimed rewards, desynchronised, run from one loop.
- [ ] World signs and billboards use the same fonts, ink and colours as the screen UI.
- [ ] Images that might fail to load have a text or glyph fallback (Criminal Sim `whenLoaded`, Sushi `WoodSkinRefresh`).

## 10. Working process with T3's tools

1. **Concepts first.** Mock up two or three directions in HTML using the recipe above, render each one with `t3_game_render_html`, send the images to the user, and wait for their pick. Don't build UI before they've picked.
2. **Make the image pieces the recipe needs:** the tiled texture, icons, and any ornament a gradient and stroke can't make. Render them on their own at `scale` 2 (tiles as standalone tileable images, resizable ornaments as 9-slice with plain middles) and upload them with `t3_game_upload_assets`.
3. **Build in Studio** with the theme module and helpers from sections 2–3. Text is always real TextLabels.
4. **Compare** the Studio screenshot with the chosen concept at the same size. Every difference is a bug.
5. **Polish:** run `t3_game_check_ui` until it reports nothing, then do the zoomed screenshot pass in `done.md` and the checklist in section 9.
