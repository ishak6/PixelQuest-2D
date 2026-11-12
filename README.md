# Pixel Quest

**Simple look. Brutal gameplay.**

Pixel Quest is an original 2D troll-platformer project built with Godot 4 for Android and the web. It uses original level concepts and does not copy another game's levels or assets.

## Current status

This repository is being initialized. The first milestone is a playable vertical slice with keyboard/touch controls, restart, death counter, one designed level, and export workflows. The 100-level campaign, audio, final art, and release builds require subsequent implementation and verification.

## Requirements

- Godot 4.x (use the version pinned in .github/workflows/build.yml)
- Android export templates and Android SDK/JDK for local APK export

## Run

Open project.godot in Godot 4 and press Play.

## Controls

- Desktop: A/D or Left/Right to move; Space/W/Up to jump; R to restart.
- Touch: on-screen left, right, jump, and restart controls.

## Exports

GitHub Actions builds a Web export and attempts an Android APK export. APK export requires compatible Android export templates and SDK configuration; check the Actions logs and artifacts before treating a build as release-ready.

## Design principles

- Minimal, friendly pixel-art presentation with difficult, learnable platforming.
- Deterministic trap timing and clear counterplay.
- Every level must have at least one verified solution before release.
- No difficulty claims are treated as proven without playtesting.
