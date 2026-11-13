# Pixel Quest

**Simple look. Brutal gameplay.**

Pixel Quest is an original 2D troll-platformer built with Godot 4.4.1. The same source project targets two independent releases: a browser website and a standalone Android APK.

## Current status

The repository contains an early playable prototype and automated build workflows. The full 100-level campaign, final character art/animation, complete audio, and release QA are not yet complete.

## Run locally

Open `project.godot` in Godot 4.4.1 and press Play.

## Controls

- Desktop: A/D or Left/Right to move; Space/W/Up to jump; R to restart.
- Touch: on-screen movement, jump, and restart controls where implemented.

## Independent releases

### Website

**Play Pixel Quest:** https://ishak6.github.io/PixelQuest-2D/

- GitHub Actions exports the Godot Web build.
- The website is deployed to GitHub Pages.
- It runs in a compatible modern browser; no Android APK is needed.
- After the first successful deployment, open the repository's **Settings → Pages** to confirm the published URL.

### Android APK

- A separate GitHub Actions job exports the Android APK.
- The APK is uploaded as a separate workflow artifact named `pixel-quest-android-apk`.
- Download it from the successful workflow run's **Artifacts** section.
- The APK is not bundled into the website and the website does not install or launch it.

## Build workflow

Every push to `main` runs two independent jobs:

1. **Website:** Godot import/smoke test → Web export → GitHub Pages deployment.
2. **Android:** Android SDK/JDK setup → APK export → separate APK artifact.

A failure in one job does not prevent the other job from running.

## Design principles

- Minimal, friendly pixel-art presentation with difficult, learnable platforming.
- Deterministic trap timing and clear counterplay.
- Every level must have at least one verified solution before release.
- No difficulty claims are treated as proven without playtesting.
- Builds are not considered release-ready until the exported website and APK are tested on real target devices.
