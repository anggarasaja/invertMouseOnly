# Invert Mouse Only

The smallest menu-bar app that flips scroll direction **for wheel mice only**,
leaving the trackpad completely alone — the split macOS won't give you when it
lumps both under one "Natural scrolling" toggle.

**Minimal.** One ~300-line Swift file. No Xcode project, no dependencies, no
background daemon. **Open source.** Every line is right here for you to read.
**No gimmicks.** No analytics, no accounts, no nagging, no "Pro" upgrade — just
one thing, done well.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.10-orange)
![License](https://img.shields.io/badge/License-MIT-green.svg)

Written for a Logitech Signature M650, whose firmware doesn't expose the HID++
`0x2121` wheel-invert register, so it can't be flipped on the device itself.

## How it works

A `CGEventTap` sits on the scroll-wheel event stream. Trackpads and the Magic
Mouse emit **continuous** pixel-based deltas; a wheel mouse emits **discrete**
line-based ones. Only the discrete events get negated, so trackpad gestures pass
through untouched.

## Build

```sh
./build.sh
```

Produces `invertMouseOnly.app`. Requires the Xcode Command Line Tools.

## Install

```sh
cp -R invertMouseOnly.app /Applications/
open /Applications/invertMouseOnly.app
```

On first launch it asks for **Accessibility** permission — an event tap cannot
modify events without it. Grant it in System Settings › Privacy & Security ›
Accessibility, then the app picks it up within a second. No restart needed.

Enable **Launch at Login** from the menu to keep it running.

## Menu

| Item | Effect |
| --- | --- |
| Invert Mouse Scrolling | Master on/off. Filled icon = active. |
| Also Invert Horizontal | Flips left/right too. Off by default. |
| Launch at Login | Registers via `SMAppService`. |
| Hide Menu Bar Icon | Runs headless. See below. |

## Running without a menu bar icon

Pick **Hide Menu Bar Icon** and the app keeps inverting scroll with nothing in
the menu bar.

To get the icon back, just open the app again — double-click
`invertMouseOnly.app`, or:

```sh
open -a invertMouseOnly
```

macOS routes that to the running instance as a reopen rather than starting a
second copy, and the app takes it as the cue to show itself.

To quit while hidden:

```sh
killall invertMouseOnly
```

The setting persists across launches, so with Launch at Login on it comes back
hidden. If you ever need to force the icon back without launching the app:

```sh
defaults write local.invertmouseonly hideMenuBarIcon -bool false
```

## Troubleshooting

Scrolling not inverted, or the trackpad inverted by mistake? Check how macOS is
classifying your events:

```sh
IMO_DEBUG=1 /Applications/invertMouseOnly.app/Contents/MacOS/invertMouseOnly
```

Each scroll logs `continuous=true|false`. The mouse should read `false` and the
trackpad `true`.

After a rebuild the Accessibility grant may need to be toggled off and back on:
ad-hoc signing means the code hash changes on every build, and macOS keys the
permission to that hash.

## Requirements

- macOS 13.0 or later (Apple Silicon or Intel)
- Xcode Command Line Tools, for building from source
  (`xcode-select --install`)

## Development

The whole app lives in a handful of files in the repo root:

| File | Purpose |
| --- | --- |
| `main.swift` | Everything: the event tap, the menu, the login item. |
| `build.sh`   | Compiles `main.swift` into `invertMouseOnly.app` with `swiftc`. |
| `install.sh` | Builds and copies the app into `/Applications`. |

No Xcode project, no package manifest, no third-party code — by design. See
[CONTRIBUTING.md](.github/CONTRIBUTING.md) for how to help out within those
limits.

A GitHub Actions workflow (`.github/workflows/build.yml`) builds the app on a
macOS runner on every push, so a merge can never ship a broken build.

## License

MIT — see [LICENSE](LICENSE). Do whatever you want with it (and if you remove
the scroll inversion, you can finally browse like a normal person).

