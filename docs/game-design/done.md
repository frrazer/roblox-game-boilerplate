# Before you call it done

Run this check before you report a feature as finished. It should take minutes, not hours. Do it yourself in Studio.

## Play it

- [ ] I played it start to finish as a new player would, using admin commands to get there quickly.
- [ ] A 7-year-old would understand it without reading.
- [ ] It's fun or satisfying, not just working.
- [ ] Every action has feedback, and every reward appears on screen.
- [ ] No dead time.
- [ ] Existing features still work.
- [ ] No errors in the output.

## Polish pass

A whole-screen screenshot gets shrunk before you see it, so small mistakes vanish. Look at each element up close instead:

1. Screenshot each panel, button and bar on its own, zoomed in or cropped.
2. For each one, list what's wrong. Start from the assumption that something is. Compare every element with its parent, its siblings and the same element in other menus. Check:
   - corner rounding: is the fill rounded the same as its background?
   - stroke weight
   - padding on every side
   - alignment
   - text size and vertical centring
3. Fix everything on the list, then look again. Stop only when a full close look turns up nothing.

## Look at it

Take a screenshot of everything you changed and check:

- [ ] `t3_game_check_ui` reports no issues.
- [ ] Alignment, padding and sizing are right, and nothing overlaps or clips.
- [ ] Images aren't stretched, and shapes and rounding are consistent.
- [ ] Everything is labelled in plain words.
- [ ] It matches the game's style.
- [ ] In the world, nothing floats, clips or z-fights, and the lighting is comfortable.

## Devices

- [ ] It works with touch on a phone-sized landscape screen in the emulator.
- [ ] It works with a controller.
- [ ] Nothing is heavy enough to hurt a cheap phone.

## Report

- [ ] I sent the user one short message with a screenshot, including anything I need from them.
