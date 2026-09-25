<p align="center">
  <img src="docs/icon.png" width="128" height="128" alt="PokeMe icon">
</p>

<h1 align="center">PokeMe</h1>

<p align="center">
  <a href="https://github.com/Kaonashi-42/pokeme/actions/workflows/ci.yml"><img src="https://github.com/Kaonashi-42/pokeme/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/Kaonashi-42/pokeme/badges/coverage.json" alt="Coverage">
  <a href="https://github.com/Kaonashi-42/pokeme/releases/latest"><img src="https://img.shields.io/github/v/release/Kaonashi-42/pokeme?sort=semver" alt="Latest release"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-black?logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white" alt="Swift 6">
</p>

A macOS menu bar app that takes over your whole screen when a meeting is about to start, so you never miss one.
Inspired by [In Your Face](https://www.inyourface.app/).

![The PokeMe overlay for a meeting starting in a minute](docs/overlay.png)

## Features

- Full-screen alert on every display, even over full-screen apps, with a sound and a live countdown.
- One-click **Join** for Zoom, Google Meet, Teams, Webex, Whereby, FaceTime and Chime links.
  <kbd>Return</kbd> joins, <kbd>Esc</kbd> dismisses, or snooze for a minute.
- Works with every account in Calendar.app (iCloud, Google, Exchange…); pick which calendars to watch.
- Alert at start, or 1, 2 or 5 minutes before.
- Skips all-day, declined and canceled meetings.
- Launch at login.

## Install

1. Download `PokeMe-<version>.zip` from the [latest release](https://github.com/Kaonashi-42/pokeme/releases/latest),
   unzip it and move PokeMe to Applications. It runs natively on Apple silicon and Intel, macOS 14 or later.
2. The app is not notarized: on first launch, click **Open Anyway** in System Settings › Privacy & Security.
3. Allow calendar access.

Click the hand in the menu bar for today's meetings and settings; **Preview Overlay** shows the alert right away.

## Development

Requires Xcode 16 or later.

| Command           | What it does                                                 |
| ----------------- | ------------------------------------------------------------ |
| `make`            | Lint, test and build `PokeMe.app`                            |
| `make install`    | Build, replace `/Applications/PokeMe.app` and relaunch it    |
| `make lint`       | Check style (`swift format`, rules in `.swift-format`)       |
| `make format`     | Fix style issues                                             |
| `make test`       | Run the unit tests                                           |
| `make coverage`   | Run the tests and print line coverage                        |
| `make package`    | Build the universal app and zip it (`VERSION=1.2.0` optional) |
| `make icon`       | Regenerate the app icon                                      |
| `make screenshot` | Regenerate `docs/overlay.png`                                |

CI runs lint and tests with coverage on every push and pull request. Coverage covers the `PokeMeCore` logic; the app
target is UI and calendar glue.

### Releasing

In GitHub, run **Actions › Release › Run workflow** on `main` and choose `patch`, `minor` or `major`. It tests,
tags the next semver version, builds the universal app and publishes a release listing the commits since the previous
tag.

## Security

Anyone can send a calendar invite, so event content is treated as untrusted:

- The app runs in the App Sandbox with only calendar access.
- Only `https` links to known video services can be joined.
- The overlay ignores clicks and keys for 0.8 s after it appears, so typing in another app can't join a call.

Releases include a build provenance attestation:
`gh attestation verify PokeMe-<version>.zip --repo Kaonashi-42/pokeme`.

## Troubleshooting

- **No meetings listed**: give PokeMe full access in System Settings › Privacy & Security › Calendars.
- **Calendar access asked again after a local rebuild**: builds are ad-hoc signed, so macOS sees each one as a new
  app.
- **Logs**: `log stream --predicate 'subsystem == "com.pokeme.app"'`
