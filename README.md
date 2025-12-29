# SitLess — Gentle move reminders for Garmin watches

SitLess is a lightweight widget (with Glance support) for Garmin Connect IQ devices that helps you break up long sitting periods. Instead of strict, opaque system rules, SitLess gives you simple, configurable reminders based on your own goals and working hours.

This repository contains the Monkey C source code and resources for the app.

## Features

- Background step monitoring in a rolling time window (e.g., last 60 minutes)
- Configurable from the watch (long-press UP) or via Garmin Connect (mobile):
  - Minimum steps target per window (default: 50)
  - Time window length (default: 60 minutes)
  - Active hours (default: 07:00–21:00)
- Discreet vibration alert and text prompt (e.g., "Time to move!")
- Snooze toggle via SELECT button — delays alerts for configurable duration (default: 60 min); press again to cancel early
- Visual snooze indicator near SELECT button (orange when active)
- Smart exclusions — no alerts when:
  - Do Not Disturb (DND) is enabled
  - Sleep mode is active
  - A workout is currently in progress
  - The watch is off‑wrist
- Glance view for a quick status peek; full widget view with progress visualization
- Dark/AMOLED‑friendly visuals

## How it works

SitLess runs a periodic background task that keeps a small in‑memory buffer of step counts to estimate your steps within a rolling window (e.g., the past 60 minutes). If the steps in that window are below your configured minimum and you are within active hours, the app sends a gentle vibration alert. You can snooze directly on the watch (press SELECT) to delay subsequent alerts; press SELECT again to cancel snooze early.

Notes and constraints:

- The app relies on the system step counter (no custom accelerometer logic)
- No long‑term history is stored; the buffer resets on device restart
- Background execution follows Connect IQ platform limits (wake frequency, etc.)

## Installation (Users)

- Install from the Connect IQ Store (if/when published)

## Configuration

Configuration is available in two ways:

**On the watch:**
- Long-press the UP button while in the widget to open the settings menu

**Via Garmin Connect mobile app:**
- Open the app's Settings in Garmin Connect

Available settings:
- Notifications enabled (default: ON) — toggle vibration alerts on/off; when disabled, the app works as a step tracker only
- Min. steps (default: 50)
- Time window in minutes (default: 60)
- Start/End time for active hours (default: 07:00–21:00)

## Project structure

Key paths:

- `sitless/manifest.xml` — Connect IQ manifest
- `sitless/monkey.jungle` — build configuration
- `sitless/source/` — Monkey C source code (`.mc`)
- `sitless/resources/` — resources (layouts, drawables, strings)
- `sitless/bin/` — generated builds/artifacts
- `AI/prd.md` — product requirements (Polish)

## Supported devices

Designed for Garmin watches that support Connect IQ widgets and Glances across MIP and AMOLED screens. Specific compatibility depends on your SDK targets and may be refined before store publication.

## Privacy

- All processing happens on the watch
- No internet connectivity is used by the app
- The app reads system step counts and device state flags (e.g., DND, sleep, off‑wrist, activity in progress) to decide whether to alert

## Roadmap (MVP)

- Store publication and screenshots
- Additional translations (EN/PL are primary; more may follow)
- Fine‑tuning of background scheduling and power use

## Acknowledgments

- Built with Garmin Connect IQ and Monkey C
