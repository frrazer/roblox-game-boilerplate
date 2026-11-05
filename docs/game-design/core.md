# Making a good Roblox game

Read this at the start of every session. It distils a study of 16 successful Roblox games. The guides in this folder hold the detail, real numbers and examples; before you build something, read the one for it.

## Who you're making it for

- Most players are young, on phones, and decide within the first minute. They don't read. If something needs explaining in text, change the design.
- **Fun beats correct.** A game that works but isn't fun has failed. "It runs" doesn't mean it's done.

## What the best games all do

1. **A one-line fantasy, with the verb in the title.** The power you gain shows on the avatar or in the world, not just in a counter.
2. **A core verb that's fun with the numbers hidden.** Every action gets sound, motion and a reaction from the world. Add a short, bounded skill or decision moment inside the loop.
3. **One number (or one rule) drives everything.** Show it against the requirement at every gate, in green or red. Every side system feeds it. Failure names the number to raise and offers a free fix and a paid fix.
4. **The map is the progress bar.** The next goal is visible from spawn. Going further is harder and pays more.
5. **Rewards are events, not numbers.** They fly to their counter, and the counter waits for them to land. Celebrations scale with how rare the event is, and big reveals build up before they burst.
6. **The first minute is rigged and quiet.** The first reward is guaranteed within 60 seconds and nothing can go wrong. Each tutorial step is one action, shown in the world. Nothing is sold until a few minutes after the tutorial.
7. **Offers come at the moment of pain or payoff,** sized to the player's own progress, with a free path beside every paid one.
8. **Other players can see your progress,** and playing with friends makes you stronger.
9. **One theme across everything:** world, items, sounds and UI.
10. **UI is one design system in code,** with one recipe for every button and panel. Colour means the same thing everywhere, and motion is spent on rewards.

## How to work

- **Plan before building.** Follow `designing.md`, write `GAME.md`, and send the user a short overview. Wait for their OK.
- **Show UI concepts before building any UI** (`ui.md`).
- **Get the core verb feeling right before adding systems.**
- **Check your own work before reporting** (`done.md`). Polish is part of the job.
- **Use subagents for independent work** (`subagents.md`). Only one agent drives Studio at a time.
- **Add admin commands** that jump straight to any state, so you can test anything quickly.
- **When the user thinks out loud or asks a question, discuss it; don't build** until they say so.
- **Never silently drop features.**
- **Don't fake assets you can't make well.** Ask for them.

## Guides

| Read before you work on | Guide |
| --- | --- |
| The concept, the loop, any new system | `designing.md` |
| The first minute and the tutorial | `onboarding.md` |
| Stats, currencies, curves, rebirth, retention | `progression.md` |
| Anything sold for Robux | `monetisation.md` |
| Feedback, juice, celebrations, reveals, sound | `feel.md` |
| The map, plots, shops and information in the world | `world.md` |
| Any UI | `ui.md` |
| Controls on other devices, performance | `devices.md` |
| Title, thumbnail, description, trailer | `packaging.md` |
| Calling a feature done | `done.md` |
| Splitting work across subagents | `subagents.md` |
