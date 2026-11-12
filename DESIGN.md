# Pixel Quest — Game Design v1

## Creative direction
A bright, minimal pixel-art platformer whose challenge comes from observation, precision, memory, and deterministic trap logic. The game must feel difficult but never arbitrary.

## Target platforms
- Landscape browser build (desktop keyboard and touch).
- Landscape Android APK (touch controls).

## Player
- Small gold pixel hero with red boots.
- Horizontal movement, jump, gravity, collision, restart.
- Desktop: A/D or arrows, Space/W/Up, R.
- Touch: left, right, jump, restart.

## Visual language
- Clean sky-blue background, green grass platforms, warm accent colors.
- High contrast between safe surfaces and hazards.
- Minimal HUD: level, death count, short event message.

## Audio
- Runtime-generated short tones for death, trap activation, and completion.
- Full soundtrack and polished sound pack are a later art/audio milestone.

## Difficulty contract
1. Every hazard has a deterministic trigger.
2. Every level has at least one solution route.
3. Deaths caused by bugs, inconsistent collision, or unavoidable random timing are defects.
4. A level is not labelled solver-verified until it has passed repeatable automated and human playtests.
5. Difficulty increases through new combinations of mechanics, not merely faster hazards.

## First playable level: 001 — The Fake Beginning
- Spawn on a wide safe-looking grassy platform.
- A suspicious tile collapses on contact.
- Spike strips punish careless ground movement.
- A moving platform provides the route across the gap.
- Exit is visible at the far right.
- Death counter persists through retries.

## Campaign roadmap
The intended campaign is 10 worlds × 10 levels (100 total). The repository currently contains a first playable prototype only; the remaining 99 authored levels are not represented as finished content yet.

World themes:
1. Cursed Garden — collapsing floors and hidden hazards.
2. Broken Castle — fake platforms and moving geometry.
3. Gravity Hell — gravity zones and inverted routes.
4. Shadow City — shadow echoes and timed paths.
5. Mirror World — mirrored layouts and rule changes.
6. Deadly Machine — moving hazards and switches.
7. Lost Dimension — portals and spatial puzzles.
8. Nightmare Lab — multi-mechanic combinations.
9. Devil's Kingdom — long multi-stage gauntlets.
10. The Impossible — mastery challenges.

## Modes roadmap
Campaign, Daily Devil, Endless Hell, Speedrun, and Level Creator are planned, not implemented in this prototype.
