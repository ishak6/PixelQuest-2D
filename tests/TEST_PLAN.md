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

## Recent regression checks
- [ ] Victory triggers once even when both exit overlap and boundary checks fire.
- [ ] Victory tone and clear message play once, not every physics frame.
- [ ] Player death cannot override a completed level.
- [ ] Restart returns the level to a playable state and clears the victory lock.

## Pause and audio regression checks
- [ ] Pause button opens a readable overlay and stops gameplay movement.
- [ ] Resume closes the overlay and restores player control.
- [ ] Restart from pause returns to the active level without leaving the game paused.
- [ ] Sound effects play for jump, landing, crumble, death, and victory.
- [ ] SFX toggle persists after restarting the app.
- [ ] SFX OFF silences generated effects without breaking gameplay.
