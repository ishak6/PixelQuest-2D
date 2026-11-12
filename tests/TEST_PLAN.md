# Test Plan

## Automated CI checks
- Godot editor import succeeds.
- Headless project startup remains alive for the smoke-test interval.
- Web export completes.
- Android APK export completes.

## Manual gameplay checks
- [ ] Player moves left and right on keyboard.
- [ ] Player jumps only when grounded.
- [ ] Touch left/right/jump buttons work on a phone.
- [ ] Crumble tile triggers once and restarts the level.
- [ ] Spike contact increments death count and respawns.
- [ ] Moving platform moves between its bounds.
- [ ] Exit collision shows level-clear state.
- [ ] Restart button and R key work.
- [ ] Landscape layout remains usable on narrow phone screens.
- [ ] No collision gaps, softlocks, or unavoidable deaths.

## Release gate
Do not call the game complete until all manual checks pass on a real Android device and in at least one desktop browser. CI success alone does not prove gameplay quality.
