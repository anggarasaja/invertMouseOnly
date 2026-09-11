# Contributing

Thanks for wanting to help! This project is deliberately tiny — that is its
whole personality — so please respect the constraints:

- **One Swift file.** `main.swift` is the entire app. If a change needs a
  second source file or a dependency, think hard about whether it belongs here.
- **No dependencies.** No SPM packages, no CocoaPods, no Xcode project.
- **`build.sh` alone must be enough to build it** — just the Xcode Command Line
  Tools, nothing else.

## Getting started

```sh
./build.sh          # builds invertMouseOnly.app in the repo root
./install.sh        # builds and copies it into /Applications
```

To watch what the app classifies your events as (mouse = `continuous=false`,
trackpad = `continuous=true`):

```sh
IMO_DEBUG=1 /Applications/invertMouseOnly.app/Contents/MacOS/invertMouseOnly
```

## Sending a pull request

1. Open an issue first if the change is anything beyond a trivial fix.
2. Make the change, and update the README if user-visible behavior changes.
3. Rebuild and smoke-test: launch the app, exercise every menu item, and put
   both a wheel mouse and a trackpad in front of it.
4. Keep the commit message small and focused.

## Code of conduct

Please be kind and respectful — see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
