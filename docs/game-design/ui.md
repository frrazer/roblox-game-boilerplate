# UI

UI is where an AI-made game shows most. Small mistakes make the whole game look cheap, so get them right before anyone sees it.

## Style

- **Give each game its own look** that suits its mood, and keep it consistent across every screen.
- **Use real images for icons and detailed art.** Never build an icon out of Frames or text. If you can't make a good icon, leave the slot empty and ask the user.
- **Keep the in-play HUD slim.** Save heavier styling for menus.
- **Give each screen a clear hierarchy:** the important thing stands out, without heavy decoration.

## Layout

- **Follow Roblox placement conventions.** Keep clear of Roblox's own UI: the top-left buttons, the player list and the top bar.
- **Consistent padding,** with nothing touching or overlapping.
- **Proper alignment and centring,** including when a value changes length.
- **Sensible sizing:** no huge gaps, no tiny text in big spaces, and related menus the same size.
- **Nothing clips.** Wrap or reflow instead, and give every list an empty state.
- **Never stretch images or tiled textures.**
- **Consistent shapes:** the same corner rounding everywhere, and the same button shapes and weights in every menu.
- **Never stack popups** so that one hides another.
- **It works everywhere** from a small phone to a TV.

## Words

- **Label everything in plain words a kid knows.** Never show a number or button without its meaning.
- **Buttons say exactly what they do.** Kids click the biggest button, so it must not mislead them.
- **One term per concept.**
- **Remove text and controls that do nothing for the player.**

## Behaviour

- **The UI feels alive:** menus animate in and out, and buttons respond to presses.
- **Consistent animation everywhere.** Scale from the centre, and animate only the element that was pressed.
- **Keep effects in proportion.** Ordinary buttons don't flash for attention, feedback text doesn't take over the screen, and a real wow moment gets something big.
- **UI appears only when it's relevant** and goes away when it isn't. This covers menus, prompts and world labels. Show only what the player can act on right now.
- **Every button works.** UI clicks never leak through into game actions, and the cursor is never trapped.
- **Don't spam notifications.** Notify only what the player cares about, and merge repeats.

## Process

Good Roblox UI is made the way professional games make it: designed outside Studio, exported as images, and put together in Studio. Frames, gradients and strokes alone look cheap.

1. **Design in HTML.** Make two or three different directions, render each with `t3_game_render_html`, send the images to the user, and wait for their pick. Don't build UI before they've picked.
2. **Turn the chosen design into images.** Render each piece's look (panel and button backgrounds, bars, frames, textures, icons) on its own, without text, at `scale` 2:
   - Pieces that resize are **9-slice** images: crisp corners, plain stretchable middle. Never bake a gradient into a 9-slice.
   - Repeating patterns are **standalone tileable** images.
3. **Upload them** with `t3_game_upload_assets`.
4. **Build in Studio** from those images:
   - `ScaleType.Slice` with a `SliceCenter` for 9-slices.
   - `ScaleType.Tile` with a fixed pixel `TileSize` for textures. Never leave a texture on Stretch.
   - Real TextLabels for all text, so it can change.
5. **Compare.** Screenshot the Roblox UI at the same size as the HTML render. Any difference is a bug.
6. **Polish** (see `done.md`). Run `t3_game_check_ui`, fix every issue it lists, and run it again until it's clean. Then check zoomed screenshots yourself, because the checker can't judge taste.
