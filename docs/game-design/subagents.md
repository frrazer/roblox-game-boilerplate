# Subagents

The user's plan has plenty of usage, so cost isn't the limit. Use subagents freely wherever they make the game better or faster. What limits them is coordination: subagents can't talk to each other, every handoff loses detail, and agents working on the same thing clash.

## Your team

Two named specialists work for you, defined in `.claude/agents/`. Run them as subagents, **in parallel with your own work**, like colleagues in an office:

- **Pauline** (UI designer): all UI, from concepts to polished screens. Hand her every UI job instead of doing it yourself.
- **Arthur** (game designer): `GAME.md`, the loop, progression, economy, monetisation, and honest "is this fun?" reviews.

They post on Discord under their own names, so the team sees who did what. Brief them like any subagent (below), pass on Frazer's feedback to whoever it concerns, and send them their next job when they come back. When you start a new game, Arthur drafts the design while you set up, and Pauline starts concepts once the design is agreed. While Pauline is checking UI in Studio, stay out of Studio.

## Use them for

- **Research.** Give each reference game its own subagent, running in parallel. Each one returns a short breakdown of its game using the building blocks in `designing.md`.
- **Independent systems.** Give each system its own subagent when the systems live in separate files and barely touch each other (for example the shop, the daily rewards and the leaderboard). Agree the interface between them first: what each system exposes and what it reads.
- **Assets and concepts in parallel.** UI concepts, icons, models and sound lists. Three agents produce three genuinely different UI directions, where one agent tends to produce three variations on the same idea.
- **Fresh eyes.** Have a subagent that didn't build the thing review it, so it isn't biased towards "looks fine":
  - **UI reviewer:** gets zoomed screenshots and `done.md`, and lists every flaw it finds.
  - **Playtester:** plays like a new player and reports confusion and bugs.

  Give reviewers the work and the criteria, not your own opinion of it.
- **Big reads.** Use a subagent to trace how something works across many files and return the answer, not the files.

## Don't

- Don't run chains of role agents (coder, then reviewer, then auditor, then tester) on one change. They take hours and add little.
- Don't split one feature across several agents, or let two agents edit the same files.
- Don't delegate small tasks you could finish in a few steps yourself.
- Don't hand off judgement. The design, what counts as fun, the overview for the user and the final call on quality stay with you.

## Studio

Only one agent drives Studio at a time: playtests, screenshots, building and the UI check. Normally that's you. Other subagents work only on files, and Rojo syncs their edits. Two agents playtesting at once break each other's tests.

## How many

- **A small change:** none.
- **A feature with independent parts:** 2 to 4.
- **A big batch,** such as building out a new game: up to about 5 at once. Beyond that, coordination fails faster than speed improves.

## Models

- **The strongest model** handles anything judged by taste or that needs the whole picture: design, UI, reviews, and bringing the pieces together.
- **A faster model** is fine for well-specified code, research summaries and mechanical changes. Review its work before you build on it.

## Briefs

A subagent knows only what you tell it. Every brief includes:

- **The goal,** and why it matters.
- **What to read:** the specific files, `GAME.md`, and the guide in this folder that applies.
- **Boundaries:** which files it owns, and what it must not touch.
- **What to return:** short and structured. Long output goes in a file, and it returns the path.
- **How to check its own work** before returning, such as the check script or `done.md`.

## Afterwards

- Read what comes back and check it before building on it. Look at the diffs, run the check script, and bring the pieces together yourself.
- Report results to the user, not how you split the work.
